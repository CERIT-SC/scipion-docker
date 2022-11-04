#!/bin/python3

import os.path
import signal
import sys
import threading
import sysrsync
import time

from threading import Thread
from pathlib import Path
from loguru import logger

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

sync_clone_ok = False
sync_restore_ok = False

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

def run_rsync(src, dest, ignore_error = False):
    try:
        sysrsync.run(
            source = src,
            destination = dest,
            options = ["--delete", "--recursive", "--times", "--omit-dir-times", "--quiet"])

        return True
    except Exception as e:
        logger.error(f"An error occured while running rsync. Error message: {e}")
        
        if not ignore_error:
            c_exit(remove_lock=True, success=False)

        return False


def sync_clone():
    logger.info("Cloning the dataset...")
    run_rsync(d_od_dataset, d_vol_dataset)
    logger.info("Cloning is complete.")

def sync_restore(project_empty):
    # remove files from the last instance
    p_status = f"{d_od_project}/{d_scipion}/{f_instance_status}"
    p_log = f"{d_od_project}/{d_scipion}/{f_instance_log}"

    if os.path.exists(p_status):
        os.remove(p_status)

    if os.path.exists(p_log):
        os.remove(p_log)

    # rsync od-project > vol-project
    logger.info("Restoring the project...")
    run_rsync(d_od_project, d_vol_project)
    logger.info("Restore is complete.")

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
    return run_rsync(d_vol_project, d_od_project, ignore_error = True)


def save_trap(sig, frame):
    logger.info("The stop signal (SIGINT or SIGTERM) was received. The Scipion application will be terminated and the project saved to the Onedata.")

    logger.info("Saving the project...")

    save(final=True)

    logger.info("Saving is complete.")

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
        logger.info("Autosaving will be started every 10 minutes. New autosave logs will not be printed, except for errors.")

    if not result:
        autosave_print = True
        logger.error("Autosave failed.")


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
t_sync_clone = Thread(target = sync_clone)
t_sync_restore = Thread(target = sync_restore, args = (project_empty,))

t_sync_clone.start()
t_sync_restore.start()

t_sync_clone.join()
t_sync_restore.join()

# Send a "signal" to the master container that desktop environment can be started
if not os.path.exists(f"/mnt/shared/instance-status"):
    Path("/mnt/shared/instance-status").touch()

with open("/mnt/shared/instance-status", "w") as f:
    f.write("ok")
logger.info("Starting the desktop environment...")

# Autosaves
while True:
    time.sleep(1*60)
    save_auto()

