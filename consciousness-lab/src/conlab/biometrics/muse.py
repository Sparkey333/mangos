"""Biometric sources: a Muse EEG adapter and a deterministic simulator.

The Muse adapter is intentionally a thin wrapper around BrainFlow, which
is the most robust way to talk to a Muse 2 / Muse S over BLE (it works on
a Raspberry Pi too). BrainFlow is an *optional* dependency — if it is not
installed, importing this module still works and ``MuseSource`` raises a
clear error only when you actually try to connect.

Both sources expose the same interface::

    src = SimSource()            # or MuseSource(mac="...")
    src.connect()
    for sample in src.read(seconds=10):
        ...                      # sample is a BandSample
    src.disconnect()

A ``BandSample`` is the per-second average power in the five classic EEG
bands plus an optional heart rate. Band power is a real, measurable thing;
the *meaning* you assign to it lives in the analysis layer, not here.
"""

from __future__ import annotations

import math
import random
import time
from dataclasses import dataclass, asdict
from typing import Iterator, Optional

BANDS = ("delta", "theta", "alpha", "beta", "gamma")


@dataclass
class BandSample:
    t: float                       # seconds since session start
    delta: float
    theta: float
    alpha: float
    beta: float
    gamma: float
    hr_bpm: Optional[float] = None

    def as_metric_rows(self) -> list[tuple[str, Optional[str], float]]:
        """Flatten into (metric, channel, value) rows for storage."""
        rows: list[tuple[str, Optional[str], float]] = [
            (b, None, getattr(self, b)) for b in BANDS
        ]
        if self.hr_bpm is not None:
            rows.append(("hr_bpm", None, self.hr_bpm))
        return rows

    def to_dict(self) -> dict:
        return asdict(self)


class BaseSource:
    name = "base"

    def connect(self) -> None:  # pragma: no cover - interface
        raise NotImplementedError

    def disconnect(self) -> None:  # pragma: no cover - interface
        raise NotImplementedError

    def read(self, seconds: int) -> Iterator[BandSample]:  # pragma: no cover
        raise NotImplementedError


class SimSource(BaseSource):
    """Deterministic-ish simulator so the whole pipeline runs without hardware.

    It models a gentle "relaxation drift": as a session goes on, alpha and
    theta rise and beta falls, with a slowing heart rate — a caricature of
    what a meditative session *might* look like. It is fake data, clearly
    labeled (device='sim'), useful only for testing plumbing and demos.
    """

    name = "sim"

    def __init__(self, seed: Optional[int] = 7):
        self._rng = random.Random(seed)
        self._connected = False

    def connect(self) -> None:
        self._connected = True

    def disconnect(self) -> None:
        self._connected = False

    def read(self, seconds: int) -> Iterator[BandSample]:
        if not self._connected:
            raise RuntimeError("call connect() first")
        for i in range(seconds):
            drift = i / max(seconds, 1)
            n = lambda s=0.05: self._rng.uniform(-s, s)
            yield BandSample(
                t=float(i),
                delta=0.5 + 0.1 * math.sin(i / 5) + n(),
                theta=0.4 + 0.4 * drift + n(),
                alpha=0.5 + 0.5 * drift + n(),
                beta=0.8 - 0.4 * drift + n(),
                gamma=0.2 + n(0.03),
                hr_bpm=72 - 8 * drift + self._rng.uniform(-1.5, 1.5),
            )


class MuseSource(BaseSource):
    """Real Muse headband via BrainFlow. Optional dependency.

    Example::

        src = MuseSource()           # auto-discovers over BLE
        src.connect()
        for s in src.read(60):
            ...

    On a Raspberry Pi, prefer passing the device MAC address to skip the
    BLE scan: ``MuseSource(mac="00:11:22:...")``.
    """

    name = "muse"

    def __init__(self, mac: str = "", board: str = "muse_2"):
        self.mac = mac
        self.board = board
        self._board = None

    def connect(self) -> None:
        try:
            from brainflow.board_shim import (  # type: ignore
                BoardShim,
                BrainFlowInputParams,
                BoardIds,
            )
        except ImportError as exc:  # pragma: no cover - depends on env
            raise RuntimeError(
                "BrainFlow is not installed. Run `pip install brainflow` "
                "(see docs/HARDWARE_MUSE_RPI.md) to use a real Muse headband."
            ) from exc

        board_id = {
            "muse_2": BoardIds.MUSE_2_BOARD,
            "muse_s": BoardIds.MUSE_S_BOARD,
        }.get(self.board, BoardIds.MUSE_2_BOARD)

        params = BrainFlowInputParams()
        if self.mac:
            params.mac_address = self.mac
        self._board = BoardShim(board_id, params)
        self._board.prepare_session()
        self._board.start_stream()

    def disconnect(self) -> None:  # pragma: no cover - depends on env
        if self._board is not None:
            try:
                self._board.stop_stream()
            finally:
                self._board.release_session()
                self._board = None

    def read(self, seconds: int) -> Iterator[BandSample]:  # pragma: no cover
        # A faithful implementation requires BrainFlow's DataFilter band-power
        # API over the live ring buffer. It is hardware-dependent, so it is
        # left as the one clearly-marked stub. The interface and storage are
        # already proven by SimSource and the tests.
        raise NotImplementedError(
            "Live Muse band-power extraction is the next hardware step; "
            "see docs/HARDWARE_MUSE_RPI.md for the BrainFlow recipe."
        )


def get_source(device: str = "sim", **kwargs) -> BaseSource:
    """Factory: 'sim' or 'muse'."""
    if device == "sim":
        return SimSource(**kwargs)
    if device in ("muse", "muse_2", "muse_s"):
        return MuseSource(board=device if device != "muse" else "muse_2", **kwargs)
    raise ValueError(f"unknown device: {device!r}")
