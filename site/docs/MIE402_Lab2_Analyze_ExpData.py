"""MIE 402 Lab 2: inspect ExpData and compare sine fits without MATLAB.

Usage:
    python MIE402_Lab2_Analyze_ExpData.py --input recording.zip --output-dir results

Requires NumPy and Matplotlib. Reads the course analyzer's MATLAB v5 MAT
file, either directly or inside a ZIP. No SciPy or MATLAB is required.
The damped-sine fit is diagnostic, not a substitute for good tracking data.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import struct
import zipfile
import zlib

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def read_expdata(path: Path) -> np.ndarray:
    if path.suffix.lower() == ".zip":
        with zipfile.ZipFile(path) as z:
            files = [n for n in z.namelist() if n.lower().endswith(".mat")]
            if len(files) != 1:
                raise ValueError("ZIP must contain exactly one MAT file.")
            raw = z.read(files[0])
    else:
        raw = path.read_bytes()
    if not raw.startswith(b"MATLAB 5.0 MAT-file") or raw[126:128] != b"IM":
        raise ValueError("Expected a little-endian MATLAB v5 MAT file.")
    kind, size = struct.unpack_from("<II", raw, 128)
    if kind == 15:  # miCOMPRESSED
        block = zlib.decompress(raw[136:136 + size])
    elif kind == 14:  # miMATRIX
        block = raw[128:136 + size]
    else:
        raise ValueError(f"Unsupported MAT element type {kind}.")
    kind, size = struct.unpack_from("<II", block, 0)
    if kind != 14:
        raise ValueError("Expected a MATLAB matrix element.")
    off = 8
    elements = []
    while off < 8 + size:
        element_type, nbytes = struct.unpack_from("<II", block, off)
        off += 8
        elements.append((element_type, block[off:off + nbytes]))
        off += (nbytes + 7) // 8 * 8
    name = elements[2][1].decode("ascii")
    if name != "ExpData" or elements[3][0] != 9:
        raise ValueError("MAT file must contain a double-precision ExpData matrix.")
    dims = tuple(np.frombuffer(elements[1][1], dtype="<i4"))
    data = np.frombuffer(elements[3][1], dtype="<f8").reshape(dims, order="F").copy()
    if data.ndim != 2 or data.shape[1] < 3:
        raise ValueError("ExpData needs time, bob x, and bob y columns.")
    return data


def linear_sine(t: np.ndarray, y: np.ndarray, freq: float, decay: float = 0,
                trend: bool = False):
    u = t - t[0]
    envelope = np.exp(-decay * u)
    columns = [np.ones(len(t))]
    if trend:
        columns.append(u)
    columns += [envelope * np.sin(2 * np.pi * freq * u),
                envelope * np.cos(2 * np.pi * freq * u)]
    matrix = np.column_stack(columns)
    coef = np.linalg.lstsq(matrix, y, rcond=None)[0]
    fitted = matrix @ coef
    return np.mean((y - fitted) ** 2), coef, fitted


def search_constant_sine(t, y, fmin, fmax):
    grid = np.linspace(fmin, fmax, 2500)
    errors = np.array([linear_sine(t, y, f)[0] for f in grid])
    idx = int(np.argmin(errors))
    lo, hi = grid[max(0, idx - 2)], grid[min(len(grid) - 1, idx + 2)]
    for _ in range(35):
        a = lo + (hi - lo) / 3
        b = hi - (hi - lo) / 3
        if linear_sine(t, y, a)[0] < linear_sine(t, y, b)[0]:
            hi = b
        else:
            lo = a
    f = (lo + hi) / 2
    mse, coef, fitted = linear_sine(t, y, f)
    return f, mse, coef, fitted


def search_damped_sine(t, y, center, fmin, fmax):
    best = (float("inf"), None, None, None, None)
    low, high = max(fmin, center - .20), min(fmax, center + .20)
    for decay in np.linspace(0, .4, 81):
        for freq in np.linspace(low, high, 121):
            mse, coef, fitted = linear_sine(t, y, freq, decay, trend=True)
            if mse < best[0]:
                best = mse, freq, decay, coef, fitted
    mse, freq, decay, coef, fitted = best
    for span in (.015, .003, .0006):
        for d in np.linspace(max(0, decay - span), decay + span, 31):
            for f in np.linspace(max(fmin, freq - span), min(fmax, freq + span), 31):
                candidate = linear_sine(t, y, f, d, trend=True)
                if candidate[0] < mse:
                    mse, freq, decay, coef, fitted = candidate[0], f, d, candidate[1], candidate[2]
    return freq, decay, mse, coef, fitted


def evaluate_model(t, reference_t, coef, freq, decay=0, trend=False):
    u = t - reference_t
    base = coef[0] + (coef[1] * u if trend else 0)
    a, b = coef[-2:]
    return base + np.exp(-decay * u) * (a * np.sin(2 * np.pi * freq * u)
                                          + b * np.cos(2 * np.pi * freq * u))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="ExpData .mat or .zip")
    parser.add_argument("--output-dir", type=Path, default=Path("Lab2_Python_Result"))
    parser.add_argument("--fmin", type=float, default=.1)
    parser.add_argument("--fmax", type=float, default=5.0)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    data = read_expdata(args.input)
    times = data[:, 0]
    if not np.all(np.isfinite(times)) or np.any(np.diff(times) <= 0):
        raise ValueError("ExpData time must be finite and strictly increasing.")
    valid = np.isfinite(data[:, 1]) & np.isfinite(data[:, 2])
    if valid.sum() < 30:
        raise ValueError("Too few valid tracked positions for a diagnostic fit.")
    t = times[valid]
    x, y = data[valid, 1], data[valid, 2]
    theta = np.unwrap(np.arctan2(x, -y))  # x right, y up, pivot-relative
    sample_interval = float(np.median(np.diff(times)))
    gaps = np.diff(np.r_[False, ~valid, False].astype(int))
    starts, ends = np.flatnonzero(gaps == 1), np.flatnonzero(gaps == -1) - 1
    longest_gap = int(np.max(ends - starts + 1)) if len(starts) else 0
    missing_fraction = float(1 - valid.mean())
    constant = search_constant_sine(t, theta, args.fmin, args.fmax)
    damped = search_damped_sine(t, theta, constant[0], args.fmin, args.fmax)
    f_const, mse_const, c_const, _ = constant
    f_damp, decay, mse_damp, c_damp, _ = damped
    dense = np.linspace(t[0], t[-1], 2500)
    estimate_const = evaluate_model(dense, t[0], c_const, f_const)
    estimate_damp = evaluate_model(dense, t[0], c_damp, f_damp, decay, trend=True)

    fig, axes = plt.subplots(2, 1, figsize=(13, 8), height_ratios=[3, 1])
    axes[0].plot(t, np.degrees(theta), "k.", ms=3, label=f"tracked angle ({valid.sum()}/{len(valid)} frames)")
    axes[0].plot(dense, np.degrees(estimate_const), color="#b52b27", lw=1.2,
                 label=f"constant sine: {f_const:.4f} Hz")
    axes[0].plot(dense, np.degrees(estimate_damp), color="#147d5a", lw=2,
                 label=f"damped sine: {f_damp:.4f} Hz")
    axes[0].set(ylabel="Angle (deg)", title="Lab 2: measured angle and diagnostic fits")
    axes[0].legend(); axes[0].grid(alpha=.25)
    bins = np.arange(np.floor(times[0]), np.ceil(times[-1]) + 1)
    total, _ = np.histogram(times, bins=bins)
    found, _ = np.histogram(t, bins=bins)
    coverage = np.divide(found, total, out=np.zeros_like(found, dtype=float), where=total > 0)
    axes[1].bar(bins[:-1], 100 * coverage, width=.85, align="edge", color="#64748b")
    axes[1].axhline(90, color="#b52b27", ls="--", label="90% recommended tracking screen")
    axes[1].set(xlabel="Time (s)", ylabel="Valid frames (%)", ylim=(0, 105))
    axes[1].legend(); axes[1].grid(alpha=.25)
    fig.tight_layout()
    fig_path = args.output_dir / "Lab2_ExpData_fit_diagnostic.png"
    fig.savefig(fig_path, dpi=180)
    plt.close(fig)

    result = {
        "source": str(args.input), "rows": int(len(data)), "valid_rows": int(valid.sum()),
        "missing_percent": round(100 * missing_fraction, 2),
        "longest_missing_gap_s": round(longest_gap * sample_interval, 3),
        "constant_sine_frequency_hz": round(float(f_const), 6),
        "constant_sine_rmse_deg": round(float(np.degrees(np.sqrt(mse_const))), 4),
        "damped_sine_frequency_hz": round(float(f_damp), 6),
        "damped_sine_period_s": round(float(1 / f_damp), 6),
        "damped_decay_per_s": round(float(decay), 6),
        "damped_time_constant_s": round(float(1 / decay), 3) if decay > 0 else None,
        "damped_initial_amplitude_deg": round(float(np.degrees(np.hypot(*c_damp[-2:]))), 3),
        "damped_rmse_deg": round(float(np.degrees(np.sqrt(mse_damp))), 4),
        "tracking_screen_pass": missing_fraction <= .10 and longest_gap * sample_interval <= .05,
    }
    (args.output_dir / "Lab2_ExpData_fit_results.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    print("Figure:", fig_path)
    if missing_fraction > .10:
        print("WARNING: Too many missing frames. This fit describes only observed points; retrack before reporting results.")


if __name__ == "__main__":
    main()
