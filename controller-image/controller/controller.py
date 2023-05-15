
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
from kube_sa_auto_config import KubeSaAutoConfig
from kubectl import Kubectl

class ControllerHealth(Enum):
    OK       = 0
    DEGRADED = 1

class ControllerPhase(Enum):
    PRE_STAGE_IN          = 0 # Checking the mounts, lock the project...
    STAGE_IN              = 1 # Clone and restore
    PRE_RUN               = 2 # Info print about starting the desktop environment... (master checks this REST API's phase to start the desktop env.)
    RUN                   = 3 # Auto save
    PRE_STAGE_OUT         = 4 # Delete other containers (Deployments and Jobs), terminate running auto save, some info prints...
    STAGE_OUT             = 5 # Final save
    END                   = 6 # Final save complete, unlock the project...
    CRITICAL_ERROR_UNLOCK = 7 # Special phase for failed STAGE_IN, PRE_RUN, PRE_STAGE_OUT, STAGE_OUT. This phase just unlocks the project. Next phase is CRITICAL_ERROR
    CRITICAL_ERROR        = 8 # Special phase for failed PRE_STAGE_IN phase and others from the CRITICAL_ERROR_UNLOCK
    EXIT                  = 9

class Controller:
    def __init__(self, namespace, instance_name):
        # these variables are modified while checking the mountpoints
        self.p_od_dataset = d_od_dataset
        self.p_od_project = d_od_project

        self.phase = ControllerPhase.PRE_STAGE_IN

        self.namespace = namespace
        self.instance_name = instance_name

        self.kubectl = Kubectl(KubeSaAutoConfig(), namespace, instance_name)

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
        self.sig_lock_refresh = False
        self.sig_finalsave = False

        self.autosave_print = True

    def startup(self):
        self._start_loop()
        self.send_sig_clone()
        self.send_sig_restore()

    def shutdown(self):
        self.send_sig_finalsave()

    def send_sig_clone(self):
        self.sig_clone = True

    def send_sig_restore(self):
        self.sig_restore = True

    def send_sig_autosave(self):
        self.sig_autosave = True

    def send_sig_lock_refresh(self):
        self.sig_lock_refresh = True

    def send_sig_finalsave(self):
        self.sig_finalsave = True

    def get_phase(self):
        return self.phase

    def get_health(self):
        components_alive = self.kubectl.filter_main()
        components_required = [
            "controller",
            "master",
            "vnc"
        ]

        for cr in components_required:
            cr_ok = False
            for ca in components_alive:
                if cr == ca:
                    cr_ok = True
                    break

            if not cr_ok:
                return ControllerHealth.DEGRADED

        return ControllerHealth.OK

    def _switch_phase(self, phase):
        self.phase = phase

    def _start_loop(self):
        self.t_loop.start()

    def _loop(self):
        while not self.exit:
            self._loop_turn()
            time.sleep(1)

        self._c_exit()

    def _loop_turn(self):
        # phase PRE_STAGE_IN
        #====================
        if self.phase == ControllerPhase.PRE_STAGE_IN:
            if self._pre_stage_in():
                self._switch_phase(ControllerPhase.STAGE_IN)
            else:
                self._switch_phase(ControllerPhase.CRITICAL_ERROR)

        # phase STAGE_IN
        #================
        elif self.phase == ControllerPhase.STAGE_IN:

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

            # refresh lock
            if self.sig_lock_refresh:
                self.sig_lock_refresh = False
                self._lock_refresh()

            # switch to PRE_RUN phase
            if self.sync_clone.is_status(SyncStatus.COMPLETE) and \
                    self.sync_restore.is_status(SyncStatus.COMPLETE):
                self._switch_phase(ControllerPhase.PRE_RUN)
            # ...or to CRITICAL_ERROR_UNLOCK
            elif self.sync_clone.is_status(SyncStatus.ERROR) or \
                self.sync_restore.is_status(SyncStatus.ERROR):
                self._switch_phase(ControllerPhase.CRITICAL_ERROR_UNLOCK)

        # phase PRE_RUN
        #===============
        elif self.phase == ControllerPhase.PRE_RUN:
            if self._pre_run():
                self._switch_phase(ControllerPhase.RUN)
            else:
                self._switch_phase(ControllerPhase.CRITICAL_ERROR_UNLOCK)

        # phase RUN
        #===========
        elif self.phase == ControllerPhase.RUN:

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

            # refresh lock
            if self.sig_lock_refresh:
                self.sig_lock_refresh = False
                self._lock_refresh()

            # switch to PRE_STAGE_OUT phase
            if self.sig_finalsave:
                self._switch_phase(ControllerPhase.PRE_STAGE_OUT)

        # phase PRE_STAGE_OUT
        #=====================
        elif self.phase == ControllerPhase.PRE_STAGE_OUT:
            if self._pre_stage_out():
                self._switch_phase(ControllerPhase.STAGE_OUT)
            else:
                self._switch_phase(ControllerPhase.CRITICAL_ERROR_UNLOCK)

        # phase STAGE_OUT
        #=================
        elif self.phase == ControllerPhase.STAGE_OUT:

            # start Finalsave thread
            if self.sync_finalsave.is_status(SyncStatus.READY):
                self.sync_finalsave.run()
            # switch to END phase
            elif self.sync_finalsave.is_status(SyncStatus.COMPLETE):
                self._switch_phase(ControllerPhase.END)
            # ...or to CRITICAL_ERROR_UNLOCK
            elif self.sync_finalsave.is_status(SyncStatus.ERROR):
                self._switch_phase(ControllerPhase.CRITICAL_ERROR_UNLOCK)

        # phase END
        #===========
        elif self.phase == ControllerPhase.END:
            if self._end():
                self._switch_phase(ControllerPhase.EXIT)
                self.success = True
            else:
                self._switch_phase(ControllerPhase.CRITICAL_ERROR_UNLOCK)

        # phase CRITICAL_ERROR_UNLOCK
        #=============================
        elif self.phase == ControllerPhase.CRITICAL_ERROR_UNLOCK:
            self._critical_error_unlock()
            self._switch_phase(ControllerPhase.CRITICAL_ERROR)

        # phase CRITICAL_ERROR
        #======================
        elif self.phase == ControllerPhase.CRITICAL_ERROR:
            self._critical_error()
            self._switch_phase(ControllerPhase.EXIT)

        # phase EXIT
        #============
        elif self.phase == ControllerPhase.EXIT:
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
        logger.info("Starting the desktop environment...")

        return True

    def _pre_stage_out(self):
        logger.info("A stop signal has been received.")
        logger.info("The Scipion application will be terminated and the project saved to the Onedata.")

        # If the deleting of the pods hang, it is necessary to keep the data saved.
        # For this reason, the autosync is terminated only after the deletion.
        self._delete_pods()
        self._terminate_syncs()
        return True

    def _end(self):
        self._lock_remove()
        return True

    def _critical_error_unlock(self):
        #logger.error("TODO some prints in _critical_error_unlock")
        self._lock_remove()

    def _critical_error(self):
        #logger.error("TODO some prints in _critical_error")
        pass

    def _terminate_syncs(self):
        # terminate still running Clone, Restore, Autosave
        self.sync_clone.terminate()
        self.sync_restore.terminate()
        self.sync_autosave.terminate()

        first_it = True
        while self.sync_clone.is_running() or \
                self.sync_restore.is_running() or \
                self.sync_autosave.is_running():

            if first_it:
                first_it = False
                logger.info("Terminating other still running controller threads...")

            logger.info("Waiting for other controller threads to be terminated...")
            time.sleep(timer_waiting_to_end)

    def _delete_pods(self):
        self.kubectl.delete_main()
        self.kubectl.delete_tools()
        self.kubectl.delete_specials()

        first_it = True
        while self.kubectl.filter_main(include_controller=False) or \
                self.kubectl.filter_tools() or \
                self.kubectl.filter_specials():

            if first_it:
                first_it = False
                logger.info("Deleting other still running containers...")

            logger.info("Waiting for other containers to be deleted...")
            time.sleep(timer_waiting_to_end)

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

    def _lock_refresh(self):
        unix_time = str(int(time.time()))

        # create lock in OD project mount
        with open(f"{self.p_od_project}/{f_project_lock}", "w") as f:
            f.write(unix_time)

        # create lock in staged-in project volume mount
        # The creation must be done on both side, because the autosave rewrites the refreshed lock in OD project mount.
        # The creation before the autosave is complicated bacause the autosave is active after the RUN phase is reached,
        # but the lock refresh is active in STAGE-IN and RUN phases.
        p_vol_scipion_dir = f"{d_vol_project}/{d_scipion}"
        if not os.path.isdir(p_vol_scipion_dir):
            os.mkdir(p_vol_scipion_dir)
        with open(f"{d_vol_project}/{f_project_lock}", "w") as f:
            f.write(unix_time)

    def _lock_create(self):
        self._lock_refresh()
        logger.info("The project has been locked to prevent modifications from another instance.")

    def _lock_remove(self):
        p_od_project_lock = f"{self.p_od_project}/{f_project_lock}"
        if not os.path.exists(p_od_project_lock):
            logger.warning("There is no need to unlock the project, because the project lock is missing. This should not happen.")
        else:
            os.remove(p_od_project_lock)
            logger.info("The project has been unlocked.")

    def _lock_check(self):
        lock_file = f"{self.p_od_project}/{f_project_lock}"

        # check existency of the lock file
        if os.path.exists(lock_file):
            # check freshness of the lock file
            current_unix_time = int(time.time())

            try:
                lock_unix_time = current_unix_time
                with open(lock_file, "r") as f:
                    lock_unix_time = int(f.read())

                if (current_unix_time - lock_unix_time) > lock_freshness_threshold:
                    # return False (/project is not locked/) if the unix time stored in the lock file is outdated
                    logger.warning("The project has been opened (locked) in another Scipion instance, but the instance seems to be dead.")
                    return False
            except:
                logger.error("The project has been opened (locked) in another Scipion instance, but the lock is damaged")
                return True

            logger.error("The project is already opened (locked) in another Scipion instance")
            return True

        return False

    def _c_exit(self):
        if self.success:
            logger.info("Terminating...")
        else:
            logger.error("It is not possible to continue.")
