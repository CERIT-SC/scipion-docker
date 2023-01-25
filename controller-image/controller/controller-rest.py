
import logging
import time

from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

from constants import *
from controller import *

namespace = os.environ["NAMESPACE"]
instance_name = os.environ["INSTANCE_NAME"]

app = FastAPI()
controller = Controller(namespace, instance_name)

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
    return {
        "phase": controller.get_phase_str()
    }

@app.get("/health")
async def health():
    return {
        "health": controller.get_health_str()
    }

@app.get("/info")
async def info():
    return {
        "health": controller.get_health_str(),
        "phase": controller.get_phase_str(),
        "master": controller.get_master(),
        "tools": controller.get_tools()
    }

@app.get("/")
async def index():
    return {}
