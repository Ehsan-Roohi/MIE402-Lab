"""Lab 6 optional at-home check of a suspected reversal in a fixed-camera clip.

Adapted from the Lab 6 pilot's fixed-glass, left/right vane-pose analysis.
This checks a visually selected event. Confirm the direction against the
original frames. The script does not measure RPM or search an entire movie.
"""
import argparse
from pathlib import Path

import cv2 as cv
import numpy as np
from scipy.ndimage import gaussian_filter1d


def features(frames, columns):
    smooth = np.stack([cv.GaussianBlur(frame, (5, 5), 1.25) for frame in frames]).astype(float)
    region = np.s_[:, 12:45:2, columns]
    brightness = smooth[region]
    brightness = (brightness - brightness.mean((1, 2), keepdims=True)) / (
        brightness.std((1, 2), keepdims=True) + 6
    )
    vertical, horizontal = np.gradient(smooth, axis=(1, 2))

    def normalize(values, floor):
        flat = values.reshape(len(frames), -1)
        return flat / (np.linalg.norm(flat, axis=1, keepdims=True) + floor)

    result = np.concatenate([
        normalize(brightness, 1),
        0.38 * normalize(horizontal[region], 5),
        0.38 * normalize(vertical[region], 5),
    ], axis=1)
    return normalize(result, 0.001)


def candidate_time(frames, times, guess):
    """Return a time only when left and right pose traces agree."""
    if frames.shape != (len(times), 58, 80) or len(times) < 35:
        raise ValueError("Need a set of 80 x 58 grayscale patches spanning the event.")
    if np.any(np.diff(times) <= 0):
        raise ValueError("Frame timestamps must increase.")
    if times[0] > guess - 3 or times[-1] < guess + 2:
        raise ValueError("Provide 3 seconds before and 2 seconds after the suspected turn.")
    estimates = []
    for columns in (slice(7, 35, 2), slice(46, 74, 2)):
        pose = features(frames, columns)
        near = np.abs(times - guess) < 0.30
        previous = np.abs(times - (guess - 2)) < 0.23
        if min(near.sum(), previous.sum()) < 3:
            return None
        axis = pose[near].mean(0) - pose[previous].mean(0)
        strength = np.linalg.norm(axis)
        if strength < 0.04:
            return None
        trace = gaussian_filter1d(pose @ (axis / strength), 0.20 / np.median(np.diff(times)))
        window = np.flatnonzero(np.abs(times - guess) < 1.5)
        peak = window[np.argmax(trace[window])]
        if peak in (window[0], window[-1]):
            return None
        # Require approach and retreat on both sides of the local maximum.
        dt = times - times[peak]
        before = (dt < -0.45) & (dt > -1.1)
        after = (dt > 0.45) & (dt < 1.1)
        if min(before.sum(), after.sum()) < 3:
            return None
        if trace[peak] - max(trace[before].mean(), trace[after].mean()) < 0.02:
            return None
        fit = np.abs(dt) < 0.55
        curvature, slope, _ = np.polyfit(dt[fit], trace[fit], 2)
        if curvature >= 0:
            return None
        offset = -slope / (2 * curvature)
        if abs(offset) > 0.45:
            return None
        estimates.append(float(times[peak] + offset))
    if abs(estimates[0] - estimates[1]) > 0.6:
        return None
    return tuple(estimates)


def load_video(path, guess, roi, capture_fps):
    movie = cv.VideoCapture(str(path))
    try:
        if not movie.isOpened():
            raise ValueError("Could not open the original video.")
        playback_fps = movie.get(cv.CAP_PROP_FPS)
        clock_fps = capture_fps if capture_fps is not None else playback_fps
        if clock_fps < 10:
            raise ValueError("At least 10 samples per second are needed.")
        start = max(0, guess - 3.35)
        first = int(start * clock_fps)
        movie.set(cv.CAP_PROP_POS_FRAMES, first)
        x, y, width, height = roi
        frames, times = [], []
        for _ in range(int(7 * clock_fps) + 1):
            index = movie.get(cv.CAP_PROP_POS_FRAMES)
            ok, image = movie.read()
            if not ok:
                break
            time = index / capture_fps if capture_fps else movie.get(cv.CAP_PROP_POS_MSEC) / 1000
            if time > guess + 3:
                break
            if times and time <= times[-1]:
                raise ValueError("This decoder did not return increasing presentation timestamps.")
            if times and time - times[-1] < 0.045:
                continue
            if x < 0 or y < 0 or min(width, height) < 20 or y + height > image.shape[0] or x + width > image.shape[1]:
                raise ValueError("ROI must fit inside the decoded image and include both vane sides.")
            crop = cv.cvtColor(image[y:y+height, x:x+width], cv.COLOR_BGR2GRAY)
            frames.append(cv.resize(crop, (80, 58), interpolation=cv.INTER_AREA))
            times.append(time)
        return np.array(frames), np.array(times)
    finally:
        movie.release()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("video", type=Path)
    parser.add_argument("--guess", type=float, required=True, help="Approximate event time in original file seconds")
    parser.add_argument("--roi", type=int, nargs=4, required=True, metavar=("X", "Y", "W", "H"))
    parser.add_argument("--light-off", type=float, required=True, help="Lamp-off time in the same file clock")
    parser.add_argument("--capture-fps", type=float, help="Only for a constant-rate Chronos file, use actual capture fps")
    args = parser.parse_args()
    if not np.isfinite([args.guess, args.light_off]).all() or args.guess <= args.light_off or args.light_off < 0:
        parser.error("Set a nonnegative lamp-off time before the suspected reversal.")
    if args.capture_fps is not None and (not np.isfinite(args.capture_fps) or args.capture_fps < 10):
        parser.error("Enter a valid capture frame rate.")
    try:
        frames, times = load_video(args.video, args.guess, args.roi, args.capture_fps)
        estimate = candidate_time(frames, times, args.guess)
    except ValueError as exc:
        parser.error(str(exc))
    if estimate is None:
        print("Unclear. Review original frames and report the observation without a fitted time.")
        return
    left, right = estimate
    if min(estimate) <= args.light_off:
        print("Unclear. One estimate precedes lamp-off.")
        return
    print(f"Candidate turn {np.mean(estimate) - args.light_off:.2f} s after OFF "
          f"(left/right file times {left:.2f}, {right:.2f} s).")
    print("Confirm motion before and after this point against a fixed glass or base detail.")


if __name__ == "__main__":
    main()
