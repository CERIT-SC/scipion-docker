#!venv/bin/python3

import threading
import ctypes
import time
import psutil

from enum import Enum


class MortalThreadState(Enum):
    READY      = 1
    RUNNING    = 2
    COMPLETE   = 3
    TERMINATED = 4
    ERROR      = 5

class MortalThread(threading.Thread):

    def __init__(self, target, args):
        threading.Thread.__init__(self)
        self.status = MortalThreadState.READY
        self.terminate_signal = False

        self.target = target
        self.args = args

    def _set_status(self, value):
        self.status = value

    def get_status(self):
        return self.status

    def run(self):
        result = False

        try:
            args = [self]
            args.extend(self.args)
            result = self.target(*args)
        finally:
            if self.terminate_signal:
                self._set_status(MortalThreadState.TERMINATED)
                return

            self._set_status(MortalThreadState.COMPLETE if result else MortalThreadState.ERROR)
    
    def start(self):
        self._set_status(MortalThreadState.RUNNING)
        super().start()

    def join(self):
        super().join()

    def nice_terminate(self):
        if not self.is_running():
            return False

        self.terminate_signal = True
        return True
    
    def terminate(self, pid = None, name = None):
        if not pid and not name:
            return False

        self.nice_terminate()

        current_process = psutil.Process()
        children = current_process.children(recursive=True)
        for child in children:
            if pid and child.pid == pid:
                child.terminate()
                return True
            if name and child.name == name:
                child.terminate()
                return True

        return False

    def kill(self, pid = None, name = None):
        if not pid and not name:
            return False

        self.nice_terminate()

        current_process = psutil.Process()
        children = current_process.children(recursive=True)
        for child in children:
            if pid and child.pid == pid:
                child.kill()
                return True
            if name and child.name == name:
                child.kill()
                return True

        return False

    def is_running(self):
        return self.get_status() == MortalThreadState.RUNNING

    def is_terminate_signal(self):
        return self.terminate_signal

    def is_finished(self):
        return self.get_status() == MortalThreadState.COMPLETE \
            or self.get_status() == MortalThreadState.TERMINATED \
            or self.get_status() == MortalThreadState.ERROR
