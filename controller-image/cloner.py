#!venv/bin/python3

import os
import os.path
import threading
import time

from pathlib import Path
from loguru import logger
from enum import Enum

from mortal_thread import MortalThread, MortalThreadState
from sync import SyncStatus, Sync, SyncClone, SyncRestore, SyncSave, SyncAutoSave, SyncFinalSave
from constants import *


class ClonerPhase(Enum):
    PRE_STAGE_IN          = 0 # Checking the mounts, lock the project...
    STAGE_IN              = 1 # Clone and restore
    PRE_RUN               = 2 # Send signal to start desktop environment...
    RUN                   = 3 # Auto save
    PRE_STAGE_OUT         = 4 # Terminate running auto save, some info prints...
    STAGE_OUT             = 5 # Final save
    END                   = 6 # Final save complete, unlock the project...
    CRITICAL_ERROR_UNLOCK = 7 # Special phase for failed STAGE_IN, PRE_RUN, PRE_STAGE_OUT, STAGE_OUT. This phase just unlocks the project. Next phase is CRITICAL_ERROR
    CRITICAL_ERROR        = 8 # Special phase for failed PRE_STAGE_IN phase and others from the CRITICAL_ERROR_UNLOCK
    EXIT                  = 9


class Cloner:
    def __init__(self):
        # these variables are modified while checking the mountpoints
        self.p_od_dataset = d_od_dataset
        self.p_od_project = d_od_project

        self.phase = ClonerPhase.PRE_STAGE_IN

        # init final signal to end the loop of the state machine
        self.exit = False

        self.success = False

        # init loop thread
        self.t_loop = threading.Thread(target = self._loop, args = ())

        # init syncers
        self.sync_clone     = SyncClone(self)
        self.sync_restore   = SyncRestore(self)
        self.sync_autosave  = SyncAutoSave(self)
        self.sync_finalsave = SyncFinalSave(self)

        # init signals
        self.sig_clone = False
        self.sig_restore = False
        self.sig_autosave = False
        self.sig_finalsave = False

        self.autosave_print = True

    # TODO tyhle dva signaly jsou divny, to tu nema co delat
    def send_sig_clone(self):
        if self.phase == ClonerPhase.STAGE_IN or \
                self.phase == ClonerPhase.PRE_RUN or \
                self.phase == ClonerPhase.RUN:
            self.sig_clone = True

    def send_sig_restore(self):
        if self.phase == ClonerPhase.STAGE_IN:
            self.sig_restore = True

    def send_sig_autosave(self):
        if self.phase == ClonerPhase.RUN:
            self.sig_autosave = True

    def send_sig_finalsave(self):
        if self.phase == ClonerPhase.RUN:
            self.sig_finalsave = True

    def switch_phase(self, phasea):
        # switch phase first to prevent set the signals again from REST API
        self.phase = phasea

        # reset signals
        self.sig_clone = False
        self.sig_restore = False
        self.sig_autosave = False
        self.sig_finalsave = False

    def start_loop(self):
        self.t_loop.start()

    def _loop(self):
        while not self.exit:
            self._loop_turn()
            time.sleep(1)

        self._c_exit()

    def _loop_turn(self):
        # phase PRE_STAGE_IN
        #====================
        if self.phase == ClonerPhase.PRE_STAGE_IN:
            if self._pre_stage_in():
                self.switch_phase(ClonerPhase.STAGE_IN)
            else:
                self.switch_phase(ClonerPhase.CRITICAL_ERROR)

        # phase STAGE_IN
        #================
        elif self.phase == ClonerPhase.STAGE_IN:

            # start Clone thread
            if self.sig_clone and \
                    self.sync_clone.is_status(SyncStatus.READY):
                self.sig_clone = False
                self.sync_clone.run()

            # start Restore thread
            if self.sig_restore and \
                    self.sync_restore.is_status(SyncStatus.READY):
                self.sig_restore = False
                self.sync_restore.run()

            # switch to PRE_RUN phase
            if self.sync_clone.is_status(SyncStatus.COMPLETE) and \
                    self.sync_restore.is_status(SyncStatus.COMPLETE):
                self.switch_phase(ClonerPhase.PRE_RUN)
            # ...or to CRITICAL_ERROR_UNLOCK
            elif self.sync_clone.is_status(SyncStatus.ERROR) or \
                self.sync_restore.is_status(SyncStatus.ERROR):
                self.switch_phase(ClonerPhase.CRITICAL_ERROR_UNLOCK)

        # phase PRE_RUN
        #===============
        elif self.phase == ClonerPhase.PRE_RUN:
            if self._pre_run():
                self.switch_phase(ClonerPhase.RUN)
            else:
                self.switch_phase(ClonerPhase.CRITICAL_ERROR_UNLOCK)

        # phase RUN
        #===========
        elif self.phase == ClonerPhase.RUN:

            # start Clone thread (re-stage-in the dataset)
            if self.sig_clone:
                self.sig_clone = False
                if self.sync_clone.is_status(SyncStatus.COMPLETE) or \
                        self.sync_clone.is_status(SyncStatus.ERROR):
                    self.sync_clone = SyncClone(self)
                    self.sync_clone.run()

            # start Autosave thread
            if self.sig_autosave:
                self.sig_autosave = False
                if self.sync_autosave.is_status(SyncStatus.READY):
                    self.sync_autosave.run()
                elif self.sync_autosave.is_status(SyncStatus.COMPLETE) or \
                        self.sync_autosave.is_status(SyncStatus.ERROR):
                    self.sync_autosave = SyncAutoSave(self)
                    self.sync_autosave.run()

            # switch to PRE_STAGE_OUT phase
            if self.sig_finalsave:
                self.switch_phase(ClonerPhase.PRE_STAGE_OUT)

        # phase PRE_STAGE_OUT
        #=====================
        elif self.phase == ClonerPhase.PRE_STAGE_OUT:
            if self._pre_stage_out():
                self.self.switch_phase(ClonerPhase.STAGE_OUT)
            else:
                self.self.switch_phase(ClonerPhase.CRITICAL_ERROR_UNLOCK)

        # phase STAGE_OUT
        #=================
        elif self.phase == ClonerPhase.STAGE_OUT:

            # start Finalsave thread
            if self.sync_finalsave.is_status(SyncStatus.READY):
                self.sync_finalsave.run()
            # switch to END phase
            elif self.sync_finalsave.is_status(SyncStatus.COMPLETE):
                self.switch_phase(SyncStatus.END)
            # ...or to CRITICAL_ERROR_UNLOCK
            elif self.sync_finalsave.is_status(SyncStatus.ERROR):
                self.switch_phase(SyncStatus.CRITICAL_ERROR_UNLOCK)

        # phase END
        #===========
        elif self.phase == ClonerPhase.END:
            if self._end():
                self.switch_phase(SyncStatus.EXIT)
                self.success = True
            else:
                self.switch_phase(SyncStatus.CRITICAL_ERROR_UNLOCK)

        # phase CRITICAL_ERROR_UNLOCK
        #=============================
        elif self.phase == ClonerPhase.CRITICAL_ERROR_UNLOCK:
            self._critical_error_unlock()
            self.switch_phase(ClonerPhase.CRITICAL_ERROR)

        # phase CRITICAL_ERROR
        #======================
        elif self.phase == ClonerPhase.CRITICAL_ERROR:
            self._critical_error()
            self.switch_phase(ClonerPhase.EXIT)

        # phase EXIT
        #============
        elif self.phase == ClonerPhase.EXIT:
            # end the loop
            self.exit = True


    def _pre_stage_in(self):
        # 1. Check the mountpoints whether each contains only one Onedata space
        # 2. Get the spaces names
        ret = self._check_mountpoint(self.p_od_dataset)
        if not ret:
            return False
        self.p_od_dataset = ret

        ret = self._check_mountpoint(self.p_od_project)
        if not ret:
            return False
        self.p_od_project = ret

        # Change work dir to prevent problems with relative target paths in symlinks
        os.chdir(d_vol_project)

        if self._lock_check():
            return False

        # Create work dir
        p_od_scipion = f"{self.p_od_project}/{d_scipion}"
        if not os.path.exists(p_od_scipion):
            self.project_empty = True
            logger.info("The project space looks empty. Working dir for the instance has been created.")
            os.makedirs(p_od_scipion)
        else:
            self.project_empty = False

        self._lock_create()

        return True

    def _pre_run(self):
        # TODO try-except
        # Send a "signal" to the master container that desktop environment can be started
        if not os.path.exists(f"/mnt/shared/instance-status"):
            Path("/mnt/shared/instance-status").touch()

        with open("/mnt/shared/instance-status", "w") as f:
            f.write("ok")
        logger.info("Starting the desktop environment...")

        return True

    def _pre_stage_out(self):
        logger.info("The stop signal (SIGINT or SIGTERM) was received.")

        # TODO neco je spolecne s ukoncenim pri chybe
        logger.info("The Scipion application will be terminated and the project saved to the Onedata.")

        # var t_terminate
        #=============
        # terminate still running restore, clone, _print_progress threads
        if t_terminate:
            self.t_sync_clone.terminate(name="rsync")
            self.t_sync_restore.terminate(name="rsync")

            first_it = True
            while self.t_sync_clone.is_running() \
                or self.t_sync_restore.is_running():

                if first_it:
                    first_it = False
                    logger.info("Terminating other still running threads...")

                logger.info("Waiting for other threads to terminate...")
                time.sleep(timer_waiting_to_end)

    def _critical_error_unlock(self):
        logger.warning("TODO nejake vypisy v _critical_error_unlock")
        self._lock_remove()

    def _critical_error(self):
        logger.warning("TODO nejake vypisy v _critical_error")

    def _check_mountpoint(self, mountpoint):
        if not os.path.exists(mountpoint):
            logger.error(f"Mountpoint \"{mountpoint}\" does not exist.")
            return None

        dirs = next(os.walk(mountpoint))[1]
        if 1 < len(dirs):
            logger.error(f"Mounting the Onedata seems successful, but there more than one space available on the \"{mountpoint}\" mountpoint.")
            return None
        elif 0 == len(dirs):
            logger.error(f"Mounting the Onedata probably failed. There are no space available in the \"{mountpoint}\" mountpoint.")
            return None

        return f"{mountpoint}/{dirs[0]}"

    def _lock_create(self):
        Path(f"{self.p_od_project}/{f_project_lock}").touch()
        logger.info("The project has been locked to prevent modifications from another instance.")

    def _lock_remove(self):
        # Unlock the project
        p_od_project_lock = f"{self.p_od_project}/{f_project_lock}"
        if not os.path.exists(p_od_project_lock):
            logger.warning("Unlocking the project is not needed. The project lock is missing. This should not happen.")
        else:
            os.remove(p_od_project_lock)
            logger.info("The project has been unlocked.")

    def _lock_check(self):
        if os.path.exists(f"{self.p_od_project}/{f_project_lock}"):
            logger.error("The project is already opened in another Scipion instance")
            return True

        return False

    def _c_exit(self):
        if self.success:
            logger.info("Terminating...")
        else:
            logger.info("It is not possible to continue.")
            while True:
                time.sleep(10)
