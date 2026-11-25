// Render the tidydiversity video frames with Playwright and pipe them to ffmpeg.
// Usage: node video/render.mjs <build-dir> [fps=30] [--still t1,t2,...]
// With --still, writes PNG stills at the given times (for checking) instead of video.
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)("playwright");
import { spawn } from "node:child_process";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import url from "node:url";

const here = path.dirname(url.fileURLToPath(import.meta.url));
const build = path.resolve(process.argv[2] || path.join(here, "build"));
const fps = Number(process.argv[3] && !process.argv[3].startsWith("--") ? process.argv[3] : 30);
const stillArg = process.argv.indexOf("--still");
const fmt = (process.argv.find(a => a.startsWith("--format=")) || "--format=wide").slice(9);
const size = { wide: [1920, 1080], vertical: [1080, 1920], square: [1080, 1080] }[fmt];
const stills = stillArg > 0 ? process.argv[stillArg + 1].split(",").map(Number) : null;

// A tiny static server: /video/* from this folder, /build/* from the build dir.
const types = { ".html": "text/html", ".json": "application/json", ".png": "image/png", ".txt": "text/plain", ".js": "text/javascript", ".csv": "text/csv" };
const server = http.createServer((req, res) => {
  const p = decodeURIComponent(new URL(req.url, "http://x").pathname);
  const file = p.startsWith("/build/") ? path.join(build, p.slice(7)) : path.join(here, p.slice(1));
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  });
});
await new Promise(r => server.listen(0, r));
const port = server.address().port;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: size[0], height: size[1] } });
await page.goto(`http://127.0.0.1:${port}/scenes.html?build=/build&format=${fmt}`);
const total = await page.evaluate(() => window.ready);

if (stills) {
  for (const t of stills) {
    await page.evaluate(x => window.render(x), t);
    await page.screenshot({ path: path.join(build, `still-${fmt}-${t}.png`) });
  }
} else {
  const frames = Math.ceil(total * fps);
  const ff = spawn("ffmpeg", ["-y", "-loglevel", "error", "-f", "image2pipe", "-framerate", String(fps), "-c:v", "mjpeg", "-i", "-",
    "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", path.join(build, `video-silent-${fmt}.mp4`)], { stdio: ["pipe", "inherit", "inherit"] });
  for (let i = 0; i < frames; i++) {
    await page.evaluate(x => window.render(x), i / fps);
    const buf = await page.screenshot({ type: "jpeg", quality: 92 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once("drain", r));
    if (i % (fps * 10) === 0) console.log(`frame ${i}/${frames}`);
  }
  ff.stdin.end();
  await new Promise(r => ff.on("close", r));
}
await browser.close();
server.close();
