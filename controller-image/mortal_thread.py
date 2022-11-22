
import threading
import ctypes
import time
#import psutil

from enum import Enum
from mortal_thread_state import MortalThreadState


class MortalThreadState(Enum):
    READY      = 1
    RUNNING    = 2
    COMPLETED  = 3
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
        try:
            args = [self]
            args.extend(self.args)
            result = self.target(*args)
        finally:
            if self.terminate_signal:
                self._set_status(MortalThreadState.TERMINATED)
                return

            self._set_status(MortalThreadState.COMPLETED if result else MortalThreadState.ERROR)
    
    def start(self):
        self._set_status(MortalThreadState.RUNNING)
        super().start()

    def join(self):
        super().join()

    def terminate(self):
        if self.get_status() != MortalThreadState.RUNNING:
            return False

        self.terminate_signal = True
        return True

    def is_terminate_signal(self):
        return self.terminate_signal

