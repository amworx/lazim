/**
 * Generates Lazim PWA icons (192, 512, maskable-512) with zero dependencies.
 * Geometric orbit mark: violet gradient, white orbit ring, 3 colored dots,
 * glass core. Supersampled 4x for smooth antialiasing.
 */
const zlib = require('zlib')
const fs = require('fs')
const path = require('path')

const OUT = path.join(__dirname, '..', 'public', 'icons')
fs.mkdirSync(OUT, { recursive: true })

const hex = h => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)]
const mix = (c1, c2, t) => c1.map((v, i) => v + (c2[i] - v) * t)
const clamp01 = v => Math.min(1, Math.max(0, v))

function roundedRectSDF(px, py, half, r) {
  const qx = Math.abs(px) - (half - r)
  const qy = Math.abs(py) - (half - r)
  return Math.min(Math.max(qx, qy), 0) + Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) - r
}

function renderIcon(size, maskable) {
  const SS = 4
  const N = size * SS
  const buf = Buffer.alloc(N * N * 4)
  const bg1 = hex('#8b7bff')
  const bg2 = hex('#5a49d6')
  const k = maskable ? 0.62 : 0.78
  const R = (size * k / 2) * SS
  const cx = N / 2
  const cy = N / 2
  const corner = maskable ? 0 : size * 0.18 * SS
  const dots = [['#8b7bff', -90], ['#4fc79a', 30], ['#ffb86b', 150]].map(([h, deg]) => {
    const a = (deg * Math.PI) / 180
    return { col: hex(h), dx: cx + R * Math.cos(a), dy: cy + R * Math.sin(a) }
  })

  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      const fx = x + 0.5
      const fy = y + 0.5
      let r = 0, g = 0, b = 0, a = 0

      const blend = (cr, cg, cb, ca) => {
        if (ca <= 0) return
        const na = ca + a * (1 - ca)
        if (na <= 0) return
        r = (cr * ca + r * a * (1 - ca)) / na
        g = (cg * ca + g * a * (1 - ca)) / na
        b = (cb * ca + b * a * (1 - ca)) / na
        a = na
      }

      // background (rounded square, or full bleed for maskable)
      const d = maskable ? -1 : roundedRectSDF(fx - cx, fy - cy, N / 2 - 2, corner)
      const bgA = maskable ? 1 : clamp01(-d / SS + 0.5)
      if (bgA > 0) {
        const t = clamp01((fx + fy) / (2 * N))
        const [br, bg2c, bb] = mix(bg1, bg2, t)
        blend(br, bg2c, bb, bgA)
      } else {
        const i = (y * N + x) * 4
        buf[i] = buf[i + 1] = buf[i + 2] = buf[i + 3] = 0
        continue
      }

      // orbit ring
      const dr = Math.hypot(fx - cx, fy - cy) - R
      blend(255, 255, 255, clamp01((3.25 * SS - Math.abs(dr)) / SS) * 0.55)

      // glass core
      const dc = Math.hypot(fx - cx + R * 0.22, fy - cy + R * 0.22)
      const coreR = R * 0.42
      if (dc < coreR) {
        const [cr, cg, cb] = mix([255, 255, 255], hex('#e6e1ff'), dc / coreR)
        blend(cr, cg, cb, clamp01((coreR - dc) / SS))
      }

      // orbiting dots with white outline
      for (const { col, dx, dy } of dots) {
        const dd = Math.hypot(fx - dx, fy - dy)
        const dotR = R * 0.11
        blend(col[0], col[1], col[2], clamp01((dotR - dd) / SS))
        blend(255, 255, 255, clamp01((dotR + 4 * SS - dd) / SS) * clamp01((dd - dotR) / SS) * 0.9)
      }

      const i = (y * N + x) * 4
      buf[i] = Math.round(r); buf[i + 1] = Math.round(g); buf[i + 2] = Math.round(b); buf[i + 3] = Math.round(a * 255)
    }
  }

  // box-downsample SSx
  const out = Buffer.alloc(size * (size * 4 + 1))
  for (let y = 0; y < size; y++) {
    out[y * (size * 4 + 1)] = 0
    for (let x = 0; x < size; x++) {
      let r = 0, g = 0, b = 0, a = 0
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const i = ((y * SS + sy) * N + (x * SS + sx)) * 4
          r += buf[i]; g += buf[i + 1]; b += buf[i + 2]; a += buf[i + 3]
        }
      }
      const n = SS * SS
      const o = y * (size * 4 + 1) + 1 + x * 4
      out[o] = Math.round(r / n); out[o + 1] = Math.round(g / n); out[o + 2] = Math.round(b / n); out[o + 3] = Math.round(a / n)
    }
  }
  return out
}

function crc32(buf) {
  let table = crc32.table
  if (!table) {
    table = crc32.table = new Int32Array(256)
    for (let n = 0; n < 256; n++) {
      let c = n
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
      table[n] = c
    }
  }
  let c = -1
  for (let i = 0; i < buf.length; i++) c = table[(c ^ buf[i]) & 0xff] ^ (c >>> 8)
  return (c ^ -1) >>> 0
}

function chunk(type, data) {
  const len = Buffer.alloc(4)
  len.writeUInt32BE(data.length)
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data])
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(body))
  return Buffer.concat([len, body, crc])
}

function encodePNG(raw, size) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(size, 0)
  ihdr.writeUInt32BE(size, 4)
  ihdr[8] = 8   // bit depth
  ihdr[9] = 6   // RGBA
  const idat = zlib.deflateSync(raw, { level: 9 })
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))])
}

for (const [name, size, maskable] of [
  ['icon-192.png', 192, false],
  ['icon-512.png', 512, false],
  ['icon-maskable-512.png', 512, true],
]) {
  const png = encodePNG(renderIcon(size, maskable), size)
  fs.writeFileSync(path.join(OUT, name), png)
  console.log(name, size + 'x' + size, Math.round(png.length / 1024) + ' KB')
}
console.log('done')
