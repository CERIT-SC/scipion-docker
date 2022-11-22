#!bin/python3

import os
import os.path
import signal
import sys
import threading
import sysrsync
import time
import multiprocessing

from pathlib import Path
from loguru import logger
from enum import Enum

from mortal_thread import MortalThread, MortalThreadState


# the following two paths will be updated while checking the mountpoints
d_od_dataset = "/mnt/od-dataset"
d_od_project = "/mnt/od-project"

d_vol_dataset = "/mnt/vol-dataset"
d_vol_project = "/mnt/vol-project"

d_scipion = "scipion-docker"

f_symlink_dump = "symlink-dump"
f_project_lock = "project.lock"
f_instance_status = "instance-status"
f_instance_log = "instance.log"

# seconds for time.sleep()
timer_print_progress = 60*0.5
timer_autosave = 60*2
timer_status_checking = 1
timer_waiting_to_end = 2

project_empty = True
autosave_first = True
autosave_print = True

def check_mountpoint(mountpoint):
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

def lock_create():
    global project_empty

    if not os.path.exists(f"{d_od_project}/{d_scipion}"):
        project_empty = True
        logger.info("The project space looks empty. Working dir for the instance has been created.")
        os.makedirs(f"{d_od_project}/{d_scipion}/")
    else:
        project_empty = False

def lock_remove():
    # Unlock the project
    if not os.path.exists(f"{d_od_project}/{d_scipion}/{f_project_lock}"):
        logger.warning("Unlocking the project is not needed. The project lock is missing. This should not happen.")
    else:
        os.remove(f"{d_od_project}/{d_scipion}/{f_project_lock}")
        logger.info("The project has been unlocked.")

def c_exit(remove_lock, success):
    if remove_lock:
        lock_remove()

    if success:
        logger.info("Terminating...")
    else:
        logger.info("It is not possible to continue.")

    exit(0)

def run_rsync(src, dest):
    try:
        sysrsync.run(
            source = src,
            destination = dest,
            options = ["--delete", "--recursive", "--times", "--omit-dir-times", "--quiet"])

        return True
    except Exception as e:
        logger.error(f"An error occured while running rsync. Error message: {e}")

        return False


def sync_clone(t):
    logger.info("Cloning the dataset...")

    sync_ok = run_rsync(d_od_dataset, d_vol_dataset)

    if sync_ok:
        logger.info("Cloning is complete.")

    return sync_ok

def sync_restore(t, project_empty):
    # remove files from the last instance
    p_status = f"{d_od_project}/{d_scipion}/{f_instance_status}"
    p_log = f"{d_od_project}/{d_scipion}/{f_instance_log}"

    if os.path.exists(p_status):
        os.remove(p_status)

    if os.path.exists(p_log):
        os.remove(p_log)

    # rsync od-project > vol-project
    logger.info("Restoring the project...")

    sync_ok = run_rsync(d_od_project, d_vol_project)
    if not sync_ok:
        return False

    # restore symlinks in vol-project
    if not os.path.exists(f"{d_od_project}/{f_symlink_dump}"):
        if project_empty:
            logger.info("The symlink dump file is missing, because the project space was empty.")
        else:
            logger.warning("The symlink dump file is missing, but the project space is not empty. If the project space contains some Scipion's project, the project data is probably corrupted.")

        return

    f_symlink = open(f"{d_od_project}/{f_symlink_dump}", "r")
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

    logger.info("Restore is complete.")
    return True

def symlink_search(path):
    result = list()

    walk = next(os.walk(path))
    root = walk[0]
    dirs = walk[1]
    files = walk[2]

    link_candidates = dirs.copy()
    link_candidates.extend(files)
    for c in link_candidates:
        if os.path.islink(f"{root}/{c}"):
            link = f"{root}/{c}"
            target = f"{os.readlink(link)}"

            result.append(f"{target} {link}")

    for d in dirs:
        result.extend(symlink_search(f"{root}/{d}"))

    return result

def save(final):
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

    if not os.path.exists(f"{d_vol_project}/{d_scipion}/{f_project_lock}"):
        logger.warning("The project lock was recreated because it was missing. Please do not remove the lock.")
        Path(f"{d_vol_project}/{d_scipion}/{f_project_lock}").touch()

	# rsync vol-project > od-project
    return run_rsync(d_vol_project, d_od_project)


def save_trap(sig, frame):
    logger.info("The stop signal (SIGINT or SIGTERM) was received. The Scipion application will be terminated and the project saved to the Onedata.")

    # terminate still running restore, clone, print_progress threads
    t_sync_clone.terminate(name="rsync")
    t_sync_restore.terminate(name="rsync")
    t_print_progress.nice_terminate()

    first_it = True
    while t_sync_clone.is_running() \
        or t_sync_restore.is_running() \
        or t_print_progress.is_running():

        if first_it:
            first_it = False
            logger.info("Terminating other still running threads...")

        logger.info("Waiting for other threads to terminate...")
        time.sleep(timer_waiting_to_end)

    logger.info("Saving the project...")

    save(final=True)

    logger.info("Save is complete.")

    c_exit(remove_lock=True, success=True)

def save_auto():
    global autosave_first
    global autosave_print

    if autosave_first or autosave_print:
        logger.info("Autosaving the project...")

    result = save(final=False)

    if autosave_first or autosave_print:
        autosave_print = False
        logger.info("Autosave is complete.")

    if autosave_first:
        autosave_first = False
        logger.info(f"Autosaving will be started every {str(int(timer_autosync / 60))} minutes. New autosave logs will not be printed, except for errors.")

    if not result:
        autosave_print = True
        logger.error("Autosave failed.")

def get_dir_size(path):
    size = 0
    for it in os.scandir(path):
        if it.is_file():
            size += os.path.getsize(it)
        elif it.is_dir():
            size += get_dir_size(it.path)
    return size

def print_progress(t, t_cloner, t_restore):
    time.sleep(timer_print_progress / 10)

    while not t.is_terminate_signal() and (t_cloner.is_running() or t_restore.is_running()):

        if t_cloner.is_running():
            size_source = get_dir_size(d_od_dataset)
            size_target = get_dir_size(d_vol_dataset)
            progress = 1 if size_target > size_source else size_target / size_source
            logger.info(f"Clonning progress: {str(round(progress * 100))} %")

        if t_restore.is_running():
            size_source = get_dir_size(d_od_project)
            size_target = get_dir_size(d_vol_project)
            progress = 1 if size_target > size_source else size_target / size_source
            logger.info(f"Restoring progress: {str(round(progress * 100))} %")

        i = 0
        while not t.is_terminate_signal() and i < 100:
            time.sleep(timer_print_progress / 100)
            i += 1

    return True


# Init threads
t_sync_clone     = MortalThread(target = sync_clone, args = ())
t_sync_restore   = MortalThread(target = sync_restore, args = (project_empty,))
t_print_progress = MortalThread(target = print_progress, args = (t_sync_clone, t_sync_restore))

# Check the mountpoints whether each contains only one Onedata space
# Get the spaces names
ret = check_mountpoint(d_od_dataset)
if not ret:
    c_exit(remove_lock=False, success=False)
d_od_dataset = ret

ret = check_mountpoint(d_od_project)
if not ret:
    c_exit(remove_lock=False, success=False)
d_od_project = ret

# Change work dir to prevent problems with relative target paths in symlinks
os.chdir("/mnt/vol-project")

# Check if the project is already opened (locked)
if os.path.exists(f"{d_od_project}/{d_scipion}/{f_project_lock}"):
    logger.error("The project is already opened in another Scipion instance")
    c_exit(remove_lock=False, success=False)

# Register handlers for the SIGINT and SIGTERM signals
signal.signal(signal.SIGINT, save_trap)
signal.signal(signal.SIGTERM, save_trap)

# Lock the project
lock_create()

Path(f"{d_od_project}/{d_scipion}/{f_project_lock}").touch()
logger.info("The project has been locked to prevent modifications from another instance.")

# Start restore and clone stages
t_sync_clone.start()
t_sync_restore.start()
t_print_progress.start()

while t_sync_clone.is_running() \
    or t_sync_restore.is_running() \
    or t_print_progress.is_running():
    if t_sync_clone.get_status() == MortalThreadState.ERROR:
        logger.error("An error occured in cloning thread.")
        c_exit(remove_lock=True, success=False)
    if t_sync_restore.get_status() == MortalThreadState.ERROR:
        logger.error("An error occured in restoring thread.")
        c_exit(remove_lock=True, success=False)
    if t_print_progress.get_status() == MortalThreadState.ERROR:
        logger.error("An error occured in progress_printing thread.")
        c_exit(remove_lock=True, success=False)

    time.sleep(timer_status_checking)

t_sync_clone.join()
t_sync_restore.join()
t_print_progress.join()

# Send a "signal" to the master container that desktop environment can be started
if not os.path.exists(f"/mnt/shared/instance-status"):
    Path("/mnt/shared/instance-status").touch()

with open("/mnt/shared/instance-status", "w") as f:
    f.write("ok")
logger.info("Starting the desktop environment...")

# Autosaves
while True:
    time.sleep(timer_autosave)
    save_auto()

