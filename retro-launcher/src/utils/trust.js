// ROM + BIOS integrity validation — runs client-side before any file is loaded into emulator

import md5 from 'md5'

// Known-good PSX BIOS MD5 hashes (from hardware dumps)
const PSX_BIOS_HASHES = {
  'SCPH1001.BIN': '924e392ed05558ffdb115408c263dccf', // US v2.2
  'SCPH5500.BIN': '8dd7d5296a650fac7319bce665a6a5aa', // JP v3.0
  'SCPH5501.BIN': '490f666e1afb15b7362b406ed1cea246', // US v3.0 — most compatible
  'SCPH5502.BIN': '32736f17079d0b2b7024407c39bd3050', // EU v3.0
}

// PSX games that need specific BIOS versions.
// PCSX-ReARMED accepts any retail BIOS; SCPH5501.BIN (US v3.0) is the safest
// single choice. PSXONPSP660.BIN is an alternative favored for edge-case compat.
const PSX_COMPAT = {
  'Metal Gear Solid': { bios: 'SCPH5501.BIN', notes: 'Multi-disc — disc 1 boots, swap discs at the codec prompt' },
  'Small Soldiers':  { bios: 'SCPH5501.BIN', notes: 'Single disc, runs well' },
}

export async function validateBIOS(file) {
  const buffer = await file.arrayBuffer()
  const bytes = new Uint8Array(buffer)
  const hash = md5(bytes)
  const name = file.name.toUpperCase()

  const expectedHash = PSX_BIOS_HASHES[name]
  if (!expectedHash) {
    return { valid: false, reason: `Unknown BIOS filename: ${file.name}. Expected one of: ${Object.keys(PSX_BIOS_HASHES).join(', ')}` }
  }
  if (hash !== expectedHash) {
    return { valid: false, reason: `Hash mismatch for ${file.name}. File may be corrupt or wrong region.` }
  }
  return { valid: true, name, region: name.includes('5500') ? 'JP' : name.includes('5502') ? 'EU' : 'US' }
}

export function getBIOSCompat(gameName) {
  return PSX_COMPAT[gameName] || null
}

export async function hashROM(file) {
  const buffer = await file.arrayBuffer()
  return md5(new Uint8Array(buffer))
}

// Check if a file is likely a valid GBA ROM by magic bytes
export async function validateGBAROM(file) {
  const buffer = await file.arrayBuffer()
  const view = new DataView(buffer)
  // GBA ROM entry point: 0xEA000000 (B instruction) at offset 0x00
  const entry = view.getUint32(0, true)
  if (entry !== 0xEA000000 && entry !== 0x00000000) {
    // Nintendo logo check at 0x04 — partial match is enough
    const logoStart = view.getUint32(4, true)
    if (logoStart !== 0x24FFAE51) {
      return { valid: false, reason: 'File does not appear to be a valid GBA ROM' }
    }
  }
  return { valid: true, size: file.size }
}
