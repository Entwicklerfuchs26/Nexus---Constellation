#!/usr/bin/env python3
# Chatterbox TTS — Sprachausgabe für Sojus. Lazy-Load beim ersten Request,
# Idle-Unload nach CHATTERBOX_IDLE_TIMEOUT Sekunden ohne Anfrage (VRAM frei
# für Spiele/ComfyUI). Läuft in einem uv-verwalteten venv, siehe
# home/chatterbox-tts.nix — dort auch die Begründung für venv statt Nix-Paket.

import asyncio
import gc
import logging
import os
import tempfile
import time
from pathlib import Path
from typing import Optional

import torch
import torchaudio as ta
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

logger = logging.getLogger("chatterbox-tts")
logging.basicConfig(level=logging.INFO)

VOICES_DIR = Path(
    os.environ.get("CHATTERBOX_VOICES_DIR", str(Path.home() / ".local/share/chatterbox-tts/voices"))
)
IDLE_TIMEOUT = float(os.environ.get("CHATTERBOX_IDLE_TIMEOUT", "300"))
MODEL_NAME = os.environ.get("CHATTERBOX_MODEL", "multilingual")

# Modell-Registry: Name -> (Modulpfad, Klassenname, unterstützt language_id).
# "turbo" ist laut Chatterbox-Doku Englisch-only, daher dort kein language_id.
# Austauschbar über CHATTERBOX_MODEL, falls z.B. für Englisch doch Turbo
# (weniger VRAM, niedrigere Latenz) gewünscht ist.
MODEL_REGISTRY = {
    "multilingual": ("chatterbox.mtl_tts", "ChatterboxMultilingualTTS", True),
    "turbo": ("chatterbox.tts_turbo", "ChatterboxTurboTTS", False),
    "english": ("chatterbox.tts", "ChatterboxTTS", False),
}

app = FastAPI()

state = {"model": None, "last_used": 0.0}
lock = asyncio.Lock()


class TTSIn(BaseModel):
    text: str
    voice: Optional[str] = "default"


def _load_model():
    import importlib

    module_path, class_name, _ = MODEL_REGISTRY[MODEL_NAME]
    module = importlib.import_module(module_path)
    cls = getattr(module, class_name)
    logger.info("Lade Chatterbox-Modell '%s' (%s.%s) auf CUDA...", MODEL_NAME, module_path, class_name)
    model = cls.from_pretrained(device="cuda")
    logger.info("Modell geladen.")
    return model


def _unload_model():
    state["model"] = None
    gc.collect()
    torch.cuda.empty_cache()
    logger.info("Modell entladen, VRAM freigegeben.")


async def _idle_watcher():
    while True:
        await asyncio.sleep(30)
        if state["model"] is not None and time.time() - state["last_used"] > IDLE_TIMEOUT:
            async with lock:
                if state["model"] is not None and time.time() - state["last_used"] > IDLE_TIMEOUT:
                    _unload_model()


@app.on_event("startup")
async def startup():
    asyncio.create_task(_idle_watcher())


@app.post("/tts")
async def tts(payload: TTSIn):
    voice_path = VOICES_DIR / f"{payload.voice}.wav"
    if not voice_path.is_file():
        raise HTTPException(
            status_code=503,
            detail=f"Referenzstimme '{payload.voice}' nicht gefunden unter {voice_path}",
        )

    async with lock:
        if state["model"] is None:
            state["model"] = await asyncio.get_event_loop().run_in_executor(None, _load_model)
        state["last_used"] = time.time()
        model = state["model"]

    _, _, supports_language_id = MODEL_REGISTRY[MODEL_NAME]
    kwargs = {"audio_prompt_path": str(voice_path)}
    if supports_language_id:
        kwargs["language_id"] = "de"

    def _generate():
        return model.generate(payload.text, **kwargs)

    wav = await asyncio.get_event_loop().run_in_executor(None, _generate)
    state["last_used"] = time.time()

    with tempfile.NamedTemporaryFile(suffix=".wav") as f:
        ta.save(f.name, wav, model.sr)
        f.seek(0)
        audio_bytes = f.read()

    return Response(content=audio_bytes, media_type="audio/wav")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("CHATTERBOX_PORT", "8004")))
