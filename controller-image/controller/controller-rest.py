
import logging
import time

from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

from constants import *
from controller import *

app = FastAPI()
controller = Controller()

@app.on_event("startup")
async def event_startup():
    controller.startup()

@app.on_event("shutdown")
async def event_shutdown():
    controller.shutdown()

@app.on_event("startup")
@repeat_every(seconds=timer_autosave)
async def autosave():
    controller.send_sig_autosave()

@app.post("/clone")
async def clone():
    controller.send_sig_clone()

@app.get("/phase")
async def phase():
    controller.get_phase_str()
    return "Not implemented"

@app.get("/")
async def index():
    return "index"
