"""Lay the narration WAVs on the timeline, add a quiet music bed and mux.
Usage: python3 video/mix.py <build-dir> <out.mp4> [wide|vertical|square]"""
import json, subprocess, sys
import numpy as np, soundfile as sf
b, out = sys.argv[1:3]
fmt = sys.argv[3] if len(sys.argv) > 3 else "wide"
t = json.load(open(f"{b}/timing.json")); sr = 24000
nar = np.zeros(int((t["total"] + 1) * sr), dtype=np.float32)
for s in t["scenes"]:
    a, _ = sf.read(f"{b}/audio/{s['id']}.wav", dtype="float32"); i = int(s["start"] * sr); nar[i:i + len(a)] += a
sf.write(f"{b}/narration.wav", nar, sr)
d = t["total"]
bed = (f"[2][3]amix=2,tremolo=f=0.15:d=0.5,lowpass=f=900,volume=0.04,afade=t=in:d=3,"
       f"afade=t=out:st={d - 4}:d=4[m];[1][m]amix=2:duration=first:normalize=0[a]")
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f"{b}/video-silent-{fmt}.mp4", "-i", f"{b}/narration.wav",
                "-f", "lavfi", "-i", f"sine=f=220:d={d}", "-f", "lavfi", "-i", f"sine=f=329.63:d={d}",
                "-filter_complex", bed, "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
                "-shortest", out], check=True)
