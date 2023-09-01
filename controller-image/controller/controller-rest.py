
import logging
import time

from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every

from constants import *
from controller import *

namespace = os.environ["NAMESPACE"]
instance_name = os.environ["INSTANCE_NAME"]
instance_prefix = os.environ["INSTANCE_PREFIX"]
instance_link = os.environ["INSTANCE_LINK"]

app = FastAPI()
controller = Controller(namespace, instance_name, instance_prefix)

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

@app.on_event("startup")
@repeat_every(seconds=timer_lock_refresh)
async def lock_refresh():
    controller.send_sig_lock_refresh()

@app.post("/clone")
async def clone():
    controller.send_sig_clone()

@app.get("/phase")
async def phase():
    return {
        "phase": controller.get_phase()
    }

@app.get("/health")
async def health():
    return {
        "health": controller.get_health()
    }

@app.get("/info")
async def info():
    return {
        "health":   controller.get_health(),
        "phase":    controller.get_phase(),
        "syncs":    controller.get_syncs(),
        "link":     instance_link,
        "main":     controller.kubectl.filter_main(),
        "tools":    controller.kubectl.filter_tools(),
        "specials": controller.kubectl.filter_specials()
    }

@app.get("/")
async def index():
    return {}
