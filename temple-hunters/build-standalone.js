/* build-standalone.js
 * Assembles every CSS/JS file into ONE self-contained HTML you can AirDrop to
 * an iPhone (save to Files → open in Safari) or email to yourself. No server,
 * no modules, no service worker — runs straight off file://.
 *
 *   node build-standalone.js   →   ../temple-hunters-standalone.html
 */
const fs = require("fs");
const path = require("path");
const here = __dirname;
const read = (p) => fs.readFileSync(path.join(here, p), "utf8");

const css = read("css/style.css");
const js = ["js/data.js", "js/audio.js", "js/sprites.js", "js/game.js"]
  .map(read).join("\n//\n");
const icon = read("icon.svg").trim();
const iconData = "data:image/svg+xml;base64," + Buffer.from(icon).toString("base64");

let html = read("index.html");

// inline the stylesheet
html = html.replace(
  /<link rel="stylesheet" href="css\/style\.css" \/>/,
  `<style>\n${css}\n</style>`
);

// drop the external manifest + service-worker bits (not used from file://)
html = html.replace(/<link rel="manifest"[^>]*>\s*/, "");
html = html.replace(/<script>\s*\/\/ register the service worker[\s\S]*?<\/script>\s*/m, "");

// embed the icon as a data URI so it travels inside the single file
html = html.replace(/href="icon\.svg"/g, `href="${iconData}"`);

// replace the four <script src> tags with one inlined block
html = html.replace(
  /\s*<script src="js\/data\.js"><\/script>[\s\S]*?<script src="js\/game\.js"><\/script>/m,
  `\n  <script>\n${js}\n  </script>`
);

const out = path.join(here, "..", "temple-hunters-standalone.html");
fs.writeFileSync(out, html);
console.log("wrote", out, "(" + Math.round(html.length / 1024) + " KB)");
