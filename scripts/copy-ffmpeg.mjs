// Copies the in-browser video converter (ffmpeg.wasm) into public/ffmpeg so
// the site serves it itself (no outside CDN). Runs after every `npm install`.
import { cpSync, mkdirSync } from "node:fs";

const out = "public/ffmpeg";
mkdirSync(out, { recursive: true });
for (const f of ["ffmpeg-core.js", "ffmpeg-core.wasm"]) cpSync(`node_modules/@ffmpeg/core/dist/esm/${f}`, `${out}/${f}`);
for (const f of ["classes.js", "worker.js", "const.js", "errors.js", "utils.js"]) cpSync(`node_modules/@ffmpeg/ffmpeg/dist/esm/${f}`, `${out}/${f}`);
console.log("ffmpeg.wasm copied to public/ffmpeg");
