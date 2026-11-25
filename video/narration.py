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

ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()


def words(n):
    """Spoken English for a whole number below 10000."""
    if n < 20:
        return ONES[n]
    if n < 100:
        return TENS[n // 10] + ("" if n % 10 == 0 else " " + ONES[n % 10])
    if n < 1000:
        h = ("a" if n // 100 == 1 else ONES[n // 100]) + " hundred"
        return h + ("" if n % 100 == 0 else " and " + words(n % 100))
    if n % 100 == 0 and n < 2000:
        return words(n // 100) + " hundred"
    return words(n // 1000) + " thousand" + ("" if n % 1000 == 0 else " " + words(n % 1000))


def down(x):
    """Round a speed-up down, never overstate: 5.9 -> 5, 132 -> 130, 509 -> 500."""
    x = int(x)
    step = 1 if x < 20 else 10 if x < 200 else 50 if x < 1000 else 100
    return x // step * step


build, model, voices = sys.argv[1:4]
here = os.path.dirname(os.path.abspath(__file__))
spec = json.load(open(os.path.join(here, "scenes.json")))
with open(os.path.join(build, "fig", "bench.csv")) as f:
    lev = {r["ref"]: float(r["speedup"]) for r in csv.DictReader(f)}
with open(os.path.join(build, "fig", "bench_scale.csv")) as f:
    sc = list(csv.DictReader(f))
big = max(int(float(r["species"])) for r in sc)
t = {r["package"]: float(r["seconds"]) for r in sc if int(float(r["species"])) == big}
nums = {"td_x": down(lev["iNEXT"]), "pd_x": down(lev["iNEXT.3D"]),
        "scale_x": down(t["iNEXT.3D"] / t["tidydiversity"]), "scale_s": f"{big:,}"}
say = dict(nums, td_w=words(nums["td_x"]), pd_w=words(nums["pd_x"]),
           scale_w=words(nums["scale_x"]), scale_sw=words(big))
os.makedirs(os.path.join(build, "audio"), exist_ok=True)
k = Kokoro(model, voices)
timing = []
t = 0.0
lead, tail = 0.6, 0.9  # silence before and after each line
for s in spec["scenes"]:
    text = s["say"].format(**say)
    audio, sr = k.create(text, voice=spec["voice"], speed=spec["speed"], lang="en-us")
    pad = lambda sec: np.zeros(int(sec * sr), dtype=audio.dtype)
    clip = np.concatenate([pad(lead), audio, pad(tail)])
    sf.write(os.path.join(build, "audio", f"{s['id']}.wav"), clip, sr)
    dur = len(clip) / sr
    timing.append({"id": s["id"], "start": round(t, 3), "duration": round(dur, 3),
                   "speech": round(len(audio) / sr, 3), "say": text})
    t += dur
json.dump({"scenes": timing, "total": round(t, 3), "nums": nums}, open(os.path.join(build, "timing.json"), "w"), indent=1)
print(f"{len(timing)} scenes, {t:.1f} s, {nums}")
