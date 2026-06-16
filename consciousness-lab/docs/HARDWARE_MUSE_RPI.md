# Reading the Muse headband (and "hacking" it with a Raspberry Pi)

Good news: you do **not** need to reverse-engineer or jailbreak the Muse.
Muse headbands stream raw EEG over standard **Bluetooth Low Energy (BLE)**,
and there is a mature open-source stack for reading it. "Hacking the
headband" here just means **bypassing the official phone app** and pulling
the raw signal yourself. That's fully supported by these libraries.

## What works with which Muse

- **Muse 2** and **Muse S** → best supported (EEG, PPG/heart rate, accel).
- **Muse 2016** → EEG works; no PPG heart rate.
- All connect over BLE. A **Raspberry Pi 4 / 5** with built-in Bluetooth
  is plenty; a Pi Zero 2 W also works.

## Two software options

### Option A — BrainFlow (what this app targets)

BrainFlow is a single library that speaks to the Muse directly and gives
you raw samples + band-power helpers. This is what `conlab`'s
`MuseSource` wraps.

```bash
pip install brainflow
```

```python
from brainflow.board_shim import BoardShim, BrainFlowInputParams, BoardIds

params = BrainFlowInputParams()
# On a Pi, pass the MAC to skip a slow scan:  params.mac_address = "00:11:..."
board = BoardShim(BoardIds.MUSE_2_BOARD, params)
board.prepare_session()
board.start_stream()
# ... wait, then board.get_current_board_data(n) ...
```

To turn raw EEG into the five band powers this app stores, use
`brainflow.data_filter.DataFilter.get_avg_band_powers()` over each
channel's recent buffer, once per second. Wiring that into
`MuseSource.read()` (currently a clearly-marked stub) is the **single
next hardware step** — the storage, session model, and tests already work
via the simulator, so you're filling in one well-defined function.

### Option B — muselsl + LSL

`muse-lsl` streams the Muse over the Lab Streaming Layer:

```bash
pip install muselsl pylsl
muselsl stream            # discovers + streams over LSL
```

Then read the `EEG` LSL inlet in Python. Good if you later want to sync
EEG with other LSL sources (e.g. an external heart-rate strap).

## Raspberry Pi setup checklist

1. Raspberry Pi OS (64-bit), `sudo apt update && sudo apt full-upgrade`.
2. Bluetooth on: `sudo systemctl enable --now bluetooth`.
3. `python3 -m venv .venv && source .venv/bin/activate`.
4. `pip install brainflow` (or `muselsl pylsl`).
5. Find the Muse MAC: `bluetoothctl` → `scan on` → note the `Muse-XXXX`
   address → pass it as `mac` to skip scans.
6. Power the Muse on (hold button until the lights cycle), then run
   `python -m conlab record --subject me --device muse_2 --seconds 60`
   *after* the `read()` stub is implemented.

## Adding a second heartbeat / HRV channel

You mentioned wanting "at least another heartbeat". Two easy routes:

- **Muse PPG** (Muse 2 / S) gives a heart-rate signal already over the
  same BLE stream — store it as `hr_bpm` (the schema already has a slot).
- **A dedicated chest strap** (Polar H10) is the gold standard for **HRV**
  and also speaks BLE — read it with `bleak` and log `hrv` alongside EEG.

HRV is honestly the highest-value extra signal for "centers/relaxation"
work: it's cheap, robust, and well-validated, unlike most EEG-to-chakra
claims. If you add one sensor next, make it an H10.

## Safety / sanity

- Consumer EEG is **not** medical-grade. It's fine for personal
  experiments; don't use it to diagnose anything.
- Dry electrodes drift. Keep sessions short, consistent, and note signal
  quality. BrainFlow exposes a quality/railed indicator — log it.
