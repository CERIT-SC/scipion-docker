
import os
import os.path
import time
import sysrsync

from pathlib import Path
from loguru import logger
from enum import Enum
from abc import ABC, abstractmethod

from mortal_thread import MortalThread, MortalThreadState
from constants import *
from utils import *

class SyncStatus(Enum):
    READY    = 1
    RUNNING  = 2
    COMPLETE = 3
    ERROR    = 4

class Sync(ABC):
    def __init__(self, controller_obj):
        self.status = SyncStatus.READY
        self.t = MortalThread(target = self._run, args = ())
        self.controller = controller_obj

    def get_status(self):
        if self.t.get_status() == MortalThreadState.COMPLETE:
            self.status = SyncStatus.COMPLETE
        elif self.t.get_status() == MortalThreadState.ERROR or \
                self.t.get_status() == MortalThreadState.TERMINATED:
            self.status = SyncStatus.ERROR

        return self.status

    def is_status(self, status):
        return self.get_status() == status

    def run(self):
        self.status = SyncStatus.RUNNING
        self.t.start()

    def terminate(self):
        self.t.terminate(name = "rsync")

    def is_running(self):
        return self.get_status() == SyncStatus.RUNNING

    def join(self):
        self.t.join()

    @abstractmethod
    def _run(self, t):
        raise NotImplementedError("Must override method \"_run()\"")

    def _run_rsync(self, src, dest, progress = True, progress_print_head = "Unknown sync"):
        # start progress printer
        if progress:
            t_progress = MortalThread(target = self._print_progress, args = (self.t, progress_print_head, src, dest))
            t_progress.start()

        # rsync
        result = False
        try:
            sysrsync.run(
                source = src,
                destination = dest,
                options = ["--delete", "--recursive", "--times", "--omit-dir-times", "--quiet"])
            result = True
        except Exception as e:
            logger.error(f"An error occured while running rsync. Error message: {e}")
            result = False

        # end progress printer
        if progress:
            t_progress.nice_terminate()
            t_progress.join()

        return result

    def _print_progress(self, t, sync_t, print_head, dir_src, dir_dest):
        time.sleep(timer_print_progress / 10)

        while not t.is_terminate_signal() and (sync_t.is_running()):
            size_src  = get_dir_size(dir_src)
            size_dest = get_dir_size(dir_dest)
            progress = 1 if size_dest > size_src else size_dest / size_src
            logger.info(f"{print_head} progress: {str(round(progress * 100))} %")

            i = 0
            while not t.is_terminate_signal() and i < 100:
                time.sleep(timer_print_progress / 100)
                i += 1

        return True

class SyncClone(Sync):
    def _run(self, t):
        logger.info("Cloning the dataset...")

        ok = super()._run_rsync(self.controller.p_od_dataset, d_vol_dataset, progress = True, progress_print_head = "Cloning")

        if not ok:
            logger.error("Cloning failed.")
            return False

        logger.info("Cloning is complete.")
        return True

class SyncRestore(Sync):
    def _run(self, t):
        # remove files from the last instance
        p_log = f"{self.controller.p_od_project}/{f_instance_log}"

        if os.path.exists(p_log):
            os.remove(p_log)

        logger.info("Restoring the project...")

        ok = super()._run_rsync(self.controller.p_od_project, d_vol_project, progress = True, progress_print_head = "Restoring")
        if not ok:
            logger.error("Restoring failed.")
            return False

        # restore symlinks in vol-project
        if not os.path.exists(f"{self.controller.p_od_project}/{f_symlink_dump}"):
            if self.controller.project_empty:
                logger.info("The symlink dump file is missing, because the project space was empty.")
            else:
                logger.warning("The symlink dump file is missing, but the project space is not empty. If the project space contains some Scipion's project, the project data is probably corrupted.")
        else:
            f_symlink = open(f"{self.controller.p_od_project}/{f_symlink_dump}", "r")
            for line in f_symlink:
                line_link = line.strip()
                if line_link:
                    line_link_arr = line_link.split(' ')

                    link = line_link_arr[1]
                    target = line_link_arr[0]

                    if not os.path.exists(link):
                        os.symlink(target, link, target_is_directory = (os.path.isdir(target)))
                    elif not os.path.islink(link):
                        logger.warning("Symlink dump file contains entry with a file that already exists but it is not a symbolic link. The project data is probably corrupted.")
                    elif os.readlink(link) != target:
                        logger.warning("Symlink dump file contains entry with a symbolic link that already exists but refers to another target. The project data is probably corrupted.")
                    else:
                        pass
                        #logger.debug("Symbolic link already exists and refers to the right target.")

            f_symlink.close()

        logger.info("Restore is complete.")
        return True

class SyncSave(Sync):
    def _helper_save(self, progress, progress_print_head):
        # Remove old symlinks dump
        p_sym = f"{d_vol_project}/{f_symlink_dump}"
        if os.path.exists(p_sym):
            os.remove(p_sym)

        Path(p_sym).touch()
        p_symlink = open(p_sym, 'a')

        # Create symlinks dump
        for line in symlink_search(d_vol_project):
            p_symlink.write(f"{line}\n")

        p_symlink.close()

        p_vol_project_lock = f"{d_vol_project}/{f_project_lock}"
        if not os.path.exists(p_vol_project_lock):
            logger.warning("The project lock was recreated because it was missing. Please do not remove the lock.")
            Path(p_vol_project_lock).touch()

        # rsync vol-project > od-project
        return super()._run_rsync(d_vol_project, self.controller.p_od_project, progress, progress_print_head)

class SyncAutoSave(SyncSave):
    def _run(self, t):
        if self.controller.autosave_print:
            logger.info("Auto saving the project...")

        ok = self._helper_save(progress = False, progress_print_head = "Auto save")

        if not ok:
            self.controller.autosave_print = True
            logger.error("Auto save failed.")
            return False

        if self.controller.autosave_print:
            self.controller.autosave_print = False
            logger.info("Auto save is complete.")
            logger.info(f"Auto save will be started every {str(int(timer_autosave / 60))} minutes. New autosave logs will not be printed, except for errors.")

        return True

class SyncFinalSave(SyncSave):
    # TODO improve copying the log file from the shared mount to the od_project - this copy the log before the lock is removed
    def _run(self, t):
        result = False
        for i in range(3):
            logger.info("Final saving the project...")
            ok = self._helper_save(progress = True, progress_print_head = "Final save")

            if ok:
                logger.info("Final save is complete.")
                result = True
                break

            logger.error("Final save failed.")

        if not result:
            logger.error("Repeatedly failed to save the project. Project data will probably be corrupted.")

        self._run_rsync(f"{d_shared}/{f_instance_log}", f"{self.controller.p_od_project}/{d_scipion}/{f_instance_log}", progress = False, progress_print_head = None)
        return result
