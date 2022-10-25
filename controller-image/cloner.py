#!/bin/python3

import os.path
import signal
import sys
import threading
import sysrsync
import time
#import logging

from threading import Thread

from pathlib import Path
from loguru import logger
# logger.warning("msg")

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

empty_project = True
first_autosave = True

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

def c_exit(success):
    if not success:
        logger.info("It is not possible to continue.")

    logger.info("Terminating...")

    exit(0)

def run_rsync(src, dest, exclusions = None, ignore_error = False):
    try:
        sysrsync.run(
            source = src,
            destination = dest,
            exclusions = exclusions,
            options = ["--delete", "--recursive", "--times", "--omit-dir-times", "--quiet"])
        # TODO --info=progress2
    except Exception as e:
        logger.error(f"An error occured while running rsync. Error message: {e}")
        
        if not ignore_error:
            raise Exception from e


def sync_clone():
    logger.info("Cloning the dataset...")
    run_rsync(d_od_dataset, d_vol_dataset)
    logger.info("Cloning is complete.")

def sync_restore(empty_project):
    # remove files from the last instance
    p_status = f"{d_od_project}/{d_scipion}/{f_instance_status}"
    p_log = f"{d_od_project}/{d_scipion}/{f_instance_log}"

    if os.path.exists(p_status):
        os.remove(p_status)

    if os.path.exists(p_log):
        os.remove(p_log)

    # rsync od-project > vol-project
    logger.info("Restoring the project...")
    run_rsync(d_od_project, d_vol_project, exclusions=[f"{d_scipion}/"])
    logger.info("Restore is complete.")

    # restore symlinks in vol-project
    if not os.path.exists(f"{d_od_project}/{f_symlink_dump}"):
        if empty_project:
            logger.info("The symlink dump file missing, because the project space was empty.")
        else:
            logger.warning("The symlink dump file missing, but the project space is not empty. If the project space contains some Scipion's project, the project data is probably corrupted.")

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

def save():
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

	# rsync vol-project > od-project (except symlinks)
    run_rsync(d_vol_project, d_od_project, exclusions=[f"{d_scipion}/"], ignore_error = True)


def save_trap(sig, frame):
    logger.info("The stop signal (SIGINT) was received. The Scipion application will be terminated and the project saved to the Onedata.")

    logger.info("Saving the project...")

    save()

    logger.info("Saving is complete.")

    # Unlock the project
    if not os.path.exists(f"{d_od_project}/{d_scipion}/{f_project_lock}"):
        logger.warning("Unlocking the project is not needed. The project lock is missing. This should not happen.")
    else:
        os.remove(f"{d_od_project}/{d_scipion}/{f_project_lock}")
        logger.info("The project has been unlocked.")

    c_exit(True)

def save_auto():
    global first_autosave

    if first_autosave:
        logger.info("Autosaving the project...")

    save()

    if first_autosave:
        first_autosave = False
        logger.info("Autosaving is complete.")
        logger.info("Autosaving will be started every 10 minutes. New autosave logs will not be printed, except for errors.")


# Check the mountpoints whether each containes only one Onedata space
# Get the spaces names
ret = check_mountpoint(d_od_dataset)
if not ret:
    c_exit(False)
d_od_dataset = ret

ret = check_mountpoint(d_od_project)
if not ret:
    c_exit(False)
d_od_project = ret

os.chdir("/mnt/vol-project")

#os.makedirs(f"{d_od_project}/{d_scipion}/")
#
#root_logger = logging.getLogger()
#
#file_handler = logging.FileHandler(f"{d_vol_project}/{d_scipion}/instance.log")
#root_logger.addHandler(file_handler)
#
#console_handler = logging.StreamHandler()
#rootLogger.addHandler(console_handler)

# Check if the project is already opened (locked)
if os.path.exists(f"{d_od_project}/{d_scipion}/{f_project_lock}"):
    logger.error("The project is already opened in another Scipion instance")
    c_exit(False)

# Register handler for the SIGINT signal
signal.signal(signal.SIGINT, save_trap)

# Lock the project
if not os.path.exists(f"{d_od_project}/{d_scipion}"):
    empty_project = True
    logger.info("The project space looks empty. Working dir for the instance has been created.")
    os.makedirs(f"{d_od_project}/{d_scipion}/")
else:
    empty_project = False

logger.info("The project has been locked to prevent modifications from another instance.")
Path(f"{d_od_project}/{d_scipion}/{f_project_lock}").touch()

# Start restore and clone stages
t_sync_clone = Thread(target = sync_clone)
t_sync_restore = Thread(target = sync_restore, args = (empty_project,))

t_sync_clone.start()
t_sync_restore.start()

t_sync_clone.join()
t_sync_restore.join()


while True:
    time.sleep(0.2*60)
    save_auto()

