# src/modules/reports_metrics.py
"""Physiological metric calculators for Reports."""

import numpy as np


def calc_sprint_count(speed_kmh: np.ndarray, fps: float,
                      threshold_kmh: float = 20.0, min_gap_s: float = 1.0) -> int:
    """Counts sprints above threshold with a minimum gap between them."""
    above = (speed_kmh >= threshold_kmh).astype(np.int8)
    gap_frames = int(min_gap_s * fps)
    if not above.any():
        return 0

    # Rising / falling edges via diff on padded array
    padded  = np.concatenate(([0], above))
    d       = np.diff(padded)
    rising  = np.where(d == 1)[0]   # frame where each sprint starts
    falling = np.where(d == -1)[0]  # frame where each sprint ends

    if len(falling) < len(rising):
        falling = np.append(falling, len(speed_kmh))

    count    = 1
    prev_end = falling[0]
    for k in range(1, len(rising)):
        if rising[k] - prev_end >= gap_frames:
            count   += 1
            prev_end = falling[k] if k < len(falling) else len(speed_kmh)

    return count


def calc_vo2max(speed_p95_kmh: float, age: int | None, sex: str | None) -> dict:
    """
    Léger formula: VO2max = 31.025 + 3.238*vmax - 3.248*age + 0.1536*vmax*age
    speed_p95_kmh should be the p95 speed (PlayerMetrics.max_speed_kmh).
    Returns {"value", "classification", "color", "age_used", "warning"}.
    """
    warning = None
    age_used = age
    if age is None or age <= 0:
        age_used = 25
        warning = "idade não cadastrada (usando 25)"
    sex_used = sex
    if sex_used not in ("M", "F"):
        sex_used = "M"
        if sex is None:
            w2 = "sexo não cadastrado (usando tabela masculina)"
            warning = (warning + " · " + w2) if warning else w2

    vmax = float(speed_p95_kmh)
    vmax = min(vmax, 36.0)  # physiological clamp — no human sustains above 36 km/h
    vo2  = 31.025 + 3.238 * vmax - 3.248 * age_used + 0.1536 * vmax * age_used
    vo2  = max(10.0, min(85.0, round(vo2, 1)))

    # Classification tables
    if age_used < 18:
        thresholds = [(35, "Fraco"), (42, "Regular"), (49, "Bom"), (56, "Excelente")]
    elif sex_used == "F":
        thresholds = [(28, "Fraco"), (35, "Regular"), (43, "Bom"), (50, "Excelente")]
    else:
        thresholds = [(35, "Fraco"), (42, "Regular"), (51, "Bom"), (58, "Excelente")]

    classification = "Superior"
    for cutoff, label in thresholds:
        if vo2 < cutoff:
            classification = label
            break

    color_map = {
        "Fraco":     "#DC2626",
        "Regular":   "#D97706",
        "Bom":       "#16A34A",
        "Excelente": "#2563EB",
        "Superior":  "#7C3AED",
    }

    return {
        "value":          vo2,
        "classification": classification,
        "color":          color_map[classification],
        "age_used":       age_used,
        "warning":        warning,
    }


def calc_fatigue_index(speed_kmh: np.ndarray) -> dict:
    """
    fatigue = (mean_first_third - mean_last_third) / mean_first_third * 100
    Only considers moving frames (> 1 km/h) to avoid standing-still bias.
    Returns {"value": float, "color": str}.
    """
    moving = speed_kmh[speed_kmh > 1.0]
    n = len(moving)
    if n < 9:  # need at least 3 frames per third
        return {"value": 0.0, "color": "#16A34A"}
    third = n // 3
    first = float(np.nanmean(moving[:third]))
    last  = float(np.nanmean(moving[n - third:]))
    if first == 0:
        return {"value": 0.0, "color": "#16A34A"}
    value = (first - last) / first * 100.0
    value = round(value, 1)
    color = "#16A34A" if value < 10 else ("#D97706" if value < 20 else "#DC2626")
    return {"value": value, "color": color}
