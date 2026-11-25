"""Narration for the tidydiversity video with Kokoro (voice am_michael).

Usage: python3 video/narration.py <build-dir> <kokoro-v1.0.onnx> <voices-v1.0.bin>

Reads video/scenes.json and <build-dir>/fig/bench.csv (the speed-up measured by
figures.R), writes one WAV per scene to <build-dir>/audio and the scene
timings (seconds) to <build-dir>/timing.json. Each scene lasts as long as its
narration plus a short pause.

Model files: https://github.com/thewh1teagle/kokoro-onnx/releases (model-files-v1.0).
"""
import csv
import json
import os
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

NUMS = {
    10: "ten", 20: "twenty", 30: "thirty", 40: "forty", 50: "fifty", 60: "sixty",
    70: "seventy", 80: "eighty", 90: "ninety", 100: "a hundred",
}


def words(n):
    if n in NUMS:
        return NUMS[n]
    if n < 200:
        return "over a hundred"
    return f"{n}"


build, model, voices = sys.argv[1:4]
here = os.path.dirname(os.path.abspath(__file__))
spec = json.load(open(os.path.join(here, "scenes.json")))
with open(os.path.join(build, "fig", "bench.csv")) as f:
    row = next(csv.DictReader(f))
speed = float(row["speedup"])
rounded = int(speed // 10 * 10)  # round down: never overstate
os.makedirs(os.path.join(build, "audio"), exist_ok=True)
k = Kokoro(model, voices)
timing = []
t = 0.0
lead, tail = 0.6, 0.9  # silence before and after each line
for s in spec["scenes"]:
    text = s["say"].replace("{speedup_words}", words(rounded))
    audio, sr = k.create(text, voice=spec["voice"], speed=spec["speed"], lang="en-us")
    pad = lambda sec: np.zeros(int(sec * sr), dtype=audio.dtype)
    clip = np.concatenate([pad(lead), audio, pad(tail)])
    sf.write(os.path.join(build, "audio", f"{s['id']}.wav"), clip, sr)
    dur = len(clip) / sr
    timing.append({"id": s["id"], "start": round(t, 3), "duration": round(dur, 3)})
    t += dur
json.dump({"scenes": timing, "total": round(t, 3), "speedup": rounded}, open(os.path.join(build, "timing.json"), "w"), indent=1)
print(f"{len(timing)} scenes, {t:.1f} s, speed-up quoted as {rounded}x (measured {speed:.0f}x)")
