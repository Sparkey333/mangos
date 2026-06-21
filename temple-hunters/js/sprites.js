/* ============================================================================
 * sprites.js — Procedural 8/16-bit creature renderer.
 *
 * No image files. Every Hunter is drawn from its data (color + ornament) onto
 * a tiny virtual grid, then blown up with smoothing OFF so the pixels stay
 * crisp and chunky. This keeps the whole game to plain text files — perfect
 * for dropping on a phone — while still reading as pixel art.
 * ========================================================================== */

const GRID = 16; // creatures live on a 16x16 virtual grid

// shade a hex color by amt (-1..1)
function shade(hex, amt) {
  const n = parseInt(hex.slice(1), 16);
  let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  const f = amt < 0 ? 0 : 255, t = Math.abs(amt);
  r = Math.round(r + (f - r) * t);
  g = Math.round(g + (f - g) * t);
  b = Math.round(b + (f - b) * t);
  return `rgb(${r},${g},${b})`;
}

// fill one virtual pixel
function px(ctx, ox, oy, cell, gx, gy, color) {
  ctx.fillStyle = color;
  ctx.fillRect(ox + gx * cell, oy + gy * cell, cell, cell);
}

// distance helper for the rounded body
function inEllipse(gx, gy, cx, cy, rx, ry) {
  const dx = (gx - cx) / rx, dy = (gy - cy) / ry;
  return dx * dx + dy * dy <= 1;
}

/* Draw a Hunter centered in a box of `size` device pixels.
 * frame: integer tick used for idle bob + blink. facing: 1 right, -1 left. */
function drawHunter(ctx, hunter, x, y, size, frame, facing) {
  facing = facing || 1;
  const cell = Math.max(1, Math.floor(size / GRID));
  const used = cell * GRID;
  const ox = Math.floor(x + (size - used) / 2);
  const bob = Math.round(Math.sin(frame / 14) * 1) * cell; // gentle float
  const oy = Math.floor(y + (size - used) / 2) + bob;

  const outline = shade(hunter.shade, -0.45);
  const body = hunter.base;
  const belly = hunter.light;
  const dark = hunter.shade;

  ctx.save();
  if (facing < 0) { ctx.translate(ox * 2 + used, 0); ctx.scale(-1, 1); }
  const bx = facing < 0 ? 0 : ox;

  // ---- ornament behind body (wings/halo/horns drawn first where needed) ----
  drawOrnamentBack(ctx, hunter, bx, oy, cell, outline, body, dark);

  // ---- body: a rounded blob ----
  const cx = 8, cy = 9, rx = 5.2, ry = 5.6;
  for (let gy = 0; gy < GRID; gy++) {
    for (let gx = 0; gx < GRID; gx++) {
      if (!inEllipse(gx, gy, cx, cy, rx, ry)) continue;
      // outline ring
      const edge = !inEllipse(gx, gy, cx, cy, rx - 0.9, ry - 0.9);
      if (edge) { px(ctx, bx, oy, cell, gx, gy, outline); continue; }
      // belly highlight lower-front, shadow upper-back
      let c = body;
      if (gy > cy && inEllipse(gx, gy, cx + 1.2, cy + 1.6, rx - 2.2, ry - 2.4)) c = belly;
      else if (gy < cy - 1) c = dark;
      px(ctx, bx, oy, cell, gx, gy, c);
    }
  }

  // ---- forehead gem (diamond) ----
  const gemX = 8, gemY = 4;
  px(ctx, bx, oy, cell, gemX, gemY, hunter.gem);
  px(ctx, bx, oy, cell, gemX, gemY - 1, shade(hunter.gem, 0.5));
  px(ctx, bx, oy, cell, gemX - 1, gemY, hunter.gem);
  px(ctx, bx, oy, cell, gemX + 1, gemY, shade(hunter.gem, -0.2));
  px(ctx, bx, oy, cell, gemX, gemY + 1, hunter.gem);

  // ---- eyes (blink every ~3s) ----
  const blink = (frame % 180) < 8;
  const eyeY = 7;
  for (const ex of [6, 10]) {
    if (blink) {
      px(ctx, bx, oy, cell, ex, eyeY, outline); // closed: a single dark line
    } else {
      px(ctx, bx, oy, cell, ex, eyeY, "#ffffff");     // white of the eye
      px(ctx, bx, oy, cell, ex, eyeY - 1, "#ffffff");
      px(ctx, bx, oy, cell, ex, eyeY, "#222");         // pupil overwrites center
    }
  }

  // tiny feet
  px(ctx, bx, oy, cell, 5, 14, dark);
  px(ctx, bx, oy, cell, 10, 14, dark);

  // ---- ornament in front ----
  drawOrnamentFront(ctx, hunter, bx, oy, cell, outline, body, belly, dark);

  ctx.restore();
}

function drawOrnamentBack(ctx, h, bx, oy, cell, outline, body, dark) {
  if (h.ornament === "halo") {
    // glowing ring above the head
    const ring = shade(h.light, 0.3);
    for (const [gx, gy] of [[5,1],[6,0],[7,0],[8,0],[9,0],[10,1]]) {
      px(ctx, bx, oy, cell, gx, gy, ring);
    }
  }
  if (h.ornament === "fins") {
    for (const [gx, gy] of [[1,9],[1,10],[1,11],[2,12]]) px(ctx, bx, oy, cell, gx, gy, dark);
  }
}

function drawOrnamentFront(ctx, h, bx, oy, cell, outline, body, belly, dark) {
  const C = shade(h.base, -0.15);
  switch (h.ornament) {
    case "horns":
      for (const [gx, gy] of [[4,3],[3,2],[3,1],[12,3],[13,2],[13,1]])
        px(ctx, bx, oy, cell, gx, gy, dark);
      break;
    case "ears":
      for (const [gx, gy] of [[4,2],[4,1],[5,1],[12,2],[12,1],[11,1]])
        px(ctx, bx, oy, cell, gx, gy, C);
      px(ctx, bx, oy, cell, 4, 2, belly);
      px(ctx, bx, oy, cell, 12, 2, belly);
      break;
    case "spikes":
      for (const [gx, gy] of [[6,2],[8,1],[10,2],[5,3],[11,3]])
        px(ctx, bx, oy, cell, gx, gy, belly);
      break;
    case "leaves":
      for (const [gx, gy] of [[7,1],[8,0],[9,1],[6,2],[10,2]])
        px(ctx, bx, oy, cell, gx, gy, shade(h.base, 0.2));
      break;
    case "fins":
      for (const [gx, gy] of [[14,8],[14,9],[14,10],[13,11],[2,8]])
        px(ctx, bx, oy, cell, gx, gy, belly);
      break;
    case "antennae":
      for (const [gx, gy] of [[6,2],[6,1],[10,2],[10,1]])
        px(ctx, bx, oy, cell, gx, gy, dark);
      px(ctx, bx, oy, cell, 6, 0, h.gem);
      px(ctx, bx, oy, cell, 10, 0, h.gem);
      break;
    case "halo":
      // wings to the sides for the crown creature
      for (const [gx, gy] of [[2,8],[1,9],[1,10],[14,8],[15,9],[15,10]])
        px(ctx, bx, oy, cell, gx, gy, shade(h.light, 0.2));
      break;
  }
}

/* Build a reusable canvas "portrait" of a hunter (for roster cards). */
function hunterPortrait(hunter, sizePx) {
  const c = document.createElement("canvas");
  c.width = c.height = sizePx;
  const ctx = c.getContext("2d");
  ctx.imageSmoothingEnabled = false;
  drawHunter(ctx, hunter, 0, 0, sizePx, 0, 1);
  return c;
}

if (typeof window !== "undefined") {
  window.Sprites = { drawHunter, hunterPortrait, shade };
}
