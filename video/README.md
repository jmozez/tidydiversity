# Marketing video (not part of the package)

Scripts that build the tidydiversity video: live-coded R console scenes,
figures and a speed test made with the installed package, narration by
Kokoro TTS (voice `am_michael`), rendered with Playwright and ffmpeg.

| File | Role |
|---|---|
| `figures.R` | figures, console output and the iNEXT.3D speed comparison |
| `scenes.json` | scene list, on-screen code and narration text |
| `narration.py` | Kokoro narration and scene timings |
| `scenes.html` | the animated scenes (`window.render(t)`) |
| `render.mjs` | renders frames to `video-silent.mp4` |
| `mix.py` | narration + music bed, final MP4 |
| `build.sh` | runs all of the above |

Install the package from GitHub first, then run:

    bash video/build.sh /tmp/tdvideo <kokoro-model-dir>

Needs R (ggplot2, vegan, iNEXT.3D), Python (kokoro-onnx, soundfile),
Node with Playwright, and ffmpeg. Write "Tidy Diversity" in the narration
so the name is pronounced as two words. The speed-up in the narration is
rounded down from the measured value.
