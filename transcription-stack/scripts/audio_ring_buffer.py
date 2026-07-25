from __future__ import annotations

import threading
from dataclasses import dataclass, field
from typing import Optional

import numpy as np


@dataclass
class AudioRingBuffer:
    """Thread-safe ring buffer for capture audio."""

    capacity: int
    _buffer: np.ndarray = field(init=False, repr=False)
    _size: int = field(default=0, init=False, repr=False)
    _write_pos: int = field(default=0, init=False, repr=False)
    _lock: threading.Lock = field(default_factory=threading.Lock, init=False, repr=False)

    def __post_init__(self) -> None:
        self.capacity = max(1, int(self.capacity))
        self._buffer = np.zeros(self.capacity, dtype=np.float32)

    def append(self, chunk: np.ndarray) -> None:
        data = np.asarray(chunk, dtype=np.float32).reshape(-1)
        if data.size <= 0:
            return

        with self._lock:
            if data.size >= self.capacity:
                self._buffer[:] = data[-self.capacity :]
                self._size = self.capacity
                self._write_pos = 0
                return

            first = min(self.capacity - self._write_pos, data.size)
            self._buffer[self._write_pos : self._write_pos + first] = data[:first]

            remaining = data.size - first
            if remaining > 0:
                self._buffer[:remaining] = data[first:]

            self._write_pos = (self._write_pos + data.size) % self.capacity
            self._size = min(self.capacity, self._size + data.size)

    def snapshot(self, limit_samples: Optional[int] = None) -> np.ndarray:
        with self._lock:
            if self._size <= 0:
                return np.empty(0, dtype=np.float32)

            n = self._size if limit_samples is None else max(0, min(self._size, int(limit_samples)))
            if n <= 0:
                return np.empty(0, dtype=np.float32)

            start = (self._write_pos - n) % self.capacity
            if start + n <= self.capacity:
                return self._buffer[start : start + n].copy()

            first = self.capacity - start
            return np.concatenate((self._buffer[start:], self._buffer[: n - first]), axis=0).astype(np.float32, copy=False)

    def clear(self) -> None:
        with self._lock:
            self._size = 0
            self._write_pos = 0
