# src/modules/reports_metrics.py
"""Physiological metric calculators for Reports."""

import numpy as np


def calc_sprint_count(speed_kmh: np.ndarray, fps: float,
                      threshold_kmh: float = 20.0, min_gap_s: float = 1.0) -> int:
    """Counts sprints above threshold with a minimum gap between them."""
    above  = speed_kmh >= threshold_kmh
    count  = 0
    in_sprint = False
    gap_frames = int(min_gap_s * fps)
    frames_since_end = gap_frames  # start ready

    for v in above:
        if v:
            if not in_sprint and frames_since_end >= gap_frames:
                count   += 1
                in_sprint = True
            frames_since_end = 0
        else:
            if in_sprint:
                in_sprint = False
            frames_since_end += 1

    return count


def calc_vo2max(max_speed_kmh: float, age: int | None, sex: str | None) -> dict:
    """
    Léger formula: VO2max = 31.025 + 3.238*vmax - 3.248*age + 0.1536*vmax*age
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

    vmax = max_speed_kmh
    vo2  = 31.025 + 3.238 * vmax - 3.248 * age_used + 0.1536 * vmax * age_used
    vo2  = max(0.0, round(vo2, 1))

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
    Returns {"value": float, "color": str}.
    """
    n = len(speed_kmh)
    if n < 3:
        return {"value": 0.0, "color": "#16A34A"}
    third = n // 3
    first = float(np.nanmean(speed_kmh[:third]))
    last  = float(np.nanmean(speed_kmh[n - third:]))
    if first == 0:
        return {"value": 0.0, "color": "#16A34A"}
    value = (first - last) / first * 100.0
    if value < 10:
        color = "#16A34A"
    elif value < 20:
        color = "#D97706"
    else:
        color = "#DC2626"
    return {"value": round(value, 1), "color": color}
