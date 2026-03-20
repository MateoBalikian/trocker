# src/modules/reports.py
# Reports module for Trocker — player metrics and visualizations.
# Migrated and rebuilt from the original Trocker reports module.

import os
import json
import cv2
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("QtAgg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.backends.backend_qtagg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.gridspec import GridSpec
from matplotlib.collections import LineCollection
from scipy.signal import savgol_filter
from scipy.ndimage import gaussian_filter

from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel,
    QListWidget, QListWidgetItem, QFileDialog, QMessageBox, QTabWidget
)
from PySide6.QtCore import Qt, QObject, Slot, QTimer
from PySide6.QtGui import QColor


# =============================================================================
# DARK THEME
# =============================================================================

_DARK_SS = """
QWidget { background-color: #0D0D14; color: #EEEEF8; font-size: 12px; }
QLabel  { color: #A0A0C0; background: transparent; }
QPushButton {
    background-color: #1D1D2C; color: #A0A0C0;
    border: 1px solid #222230; border-radius: 7px; padding: 6px 14px;
}
QPushButton:hover  { background-color: #242438; color: #EEEEF8; border-color: #303050; }
QPushButton:pressed { background-color: #13213F; color: #C0D8FF; }
QPushButton[role="primary"] {
    background-color: #4282FF; color: #FFFFFF;
    border-color: transparent; font-weight: bold;
}
QPushButton[role="primary"]:hover { background-color: #6098FF; }
QComboBox {
    background-color: #161621; color: #EEEEF8;
    border: 1px solid #222230; border-radius: 6px; padding: 4px 8px;
}
QComboBox::drop-down { border: none; }
QComboBox QAbstractItemView {
    background-color: #1D1D2C; color: #EEEEF8;
    border: 1px solid #303050; selection-background-color: #4282FF;
}
QListWidget {
    background-color: #161621; border: 1px solid #222230;
    border-radius: 8px; outline: none;
}
QListWidget::item { padding: 5px 10px; border-radius: 4px; color: #A0A0C0; }
QListWidget::item:hover { background-color: #1D1D2C; color: #EEEEF8; }
QTabWidget::pane { border: 1px solid #222230; background-color: #0D0D14; }
QTabBar::tab {
    background-color: #161621; color: #6868A0;
    padding: 8px 20px; border: 1px solid #222230;
    border-bottom: none; border-radius: 6px 6px 0 0;
}
QTabBar::tab:selected { background-color: #0D0D14; color: #EEEEF8; }
QTabBar::tab:hover    { background-color: #1D1D2C; color: #A0A0C0; }
QScrollBar:vertical   { background: #0D0D14; width: 8px; border-radius: 4px; }
QScrollBar::handle:vertical { background: #222230; border-radius: 4px; min-height: 20px; }
QScrollBar::handle:vertical:hover { background: #303050; }
QGroupBox {
    background-color: #161621; border: 1px solid #222230;
    border-radius: 10px; margin-top: 14px; padding-top: 10px;
    font-weight: bold; color: #6868A0; font-size: 10px; letter-spacing: 1px;
}
QGroupBox::title {
    subcontrol-origin: margin; subcontrol-position: top left;
    padding: 0 8px; color: #6868A0; font-size: 10px;
}
"""

# Matplotlib light theme
MPL_LIGHT = {
    "figure.facecolor":  "#FFFFFF",
    "axes.facecolor":    "#FFFFFF",
    "axes.edgecolor":    "#CCCCCC",
    "axes.labelcolor":   "#1A1A1A",
    "axes.titlecolor":   "#111111",
    "axes.grid":         True,
    "grid.color":        "#EEEEEE",
    "grid.linewidth":    0.8,
    "grid.linestyle":    "--",
    "grid.alpha":        1.0,
    "xtick.color":       "#1A1A1A",
    "ytick.color":       "#1A1A1A",
    "text.color":        "#1A1A1A",
    "legend.facecolor":  "#FFFFFF",
    "legend.edgecolor":  "#CCCCCC",
    "legend.labelcolor": "#1A1A1A",
}

# Paleta de cores para jogadores (vibrantes sobre fundo branco)
PLAYER_COLORS = [
    "#2563EB", "#16A34A", "#DC2626", "#D97706",
    "#7C3AED", "#DB2777", "#0891B2", "#65A30D",
    "#EA580C", "#9333EA", "#0D9488", "#B45309",
]

# Zonas de intensidade (km/h)
SPEED_ZONES = [
    (0,  7,  "#94A3B8", "Walk"),
    (7,  14, "#16A34A", "Jog"),
    (14, 21, "#D97706", "Run"),
    (21, 28, "#EA580C", "High Run"),
    (28, 999,"#DC2626", "Sprint"),
]

# Kwargs padrão para legend (fundo branco, legível)
_LEGEND_KW = dict(fontsize=8, facecolor="white", edgecolor="#CCCCCC", labelcolor="#1A1A1A")


# =============================================================================
# PLAYER METRICS ENGINE
# =============================================================================

class PlayerMetrics:
    """Calcula todas as métricas de um jogador a partir das coordenadas em metros."""

    def __init__(self, marker_id: int, x: np.ndarray, y: np.ndarray,
                 fps: float, name: str = None):
        self.marker_id = marker_id
        self.name      = name or f"p{marker_id}"
        self.fps       = fps

        # Suaviza coordenadas com Savitzky-Golay
        window = max(5, int(round(fps * 0.5)) | 1)
        polyorder = min(3, window - 1)
        xi = pd.Series(x.astype(float)).interpolate(method="linear", limit_direction="both").values
        yi = pd.Series(y.astype(float)).interpolate(method="linear", limit_direction="both").values
        self.x = savgol_filter(xi, window_length=window, polyorder=polyorder)
        self.y = savgol_filter(yi, window_length=window, polyorder=polyorder)

        self._compute()

    def _compute(self):
        dx = np.diff(self.x)
        dy = np.diff(self.y)
        dist_per_frame = np.sqrt(dx**2 + dy**2)

        self.speed_ms  = dist_per_frame * self.fps          # m/s por frame
        self.speed_kmh = self.speed_ms * 3.6                # km/h por frame
        self.accel     = np.diff(self.speed_ms) * self.fps  # m/s² por frame

        # Tempo em cada zona (segundos)
        self.zone_times = {}
        for lo, hi, color, label in SPEED_ZONES:
            mask = (self.speed_kmh >= lo) & (self.speed_kmh < hi)
            self.zone_times[label] = float(np.sum(mask) / self.fps)

        # Métricas sumárias
        self.total_distance = float(np.nansum(dist_per_frame))
        self.total_time     = float(len(self.x) / self.fps)
        self.avg_speed_kmh  = float(np.nanmean(self.speed_kmh))
        self.max_speed_kmh  = float(np.nanmax(self.speed_kmh))
        self.avg_accel      = float(np.nanmean(self.accel))
        self.max_accel      = float(np.nanmax(self.accel))
        self.max_decel      = float(np.nanmin(self.accel))

        # Arrays temporais (para plots)
        n = len(self.speed_ms)
        self.time_axis = np.arange(n) / self.fps   # segundos
        self.dist_per_frame = dist_per_frame        # reutilizado em plot_distance


# =============================================================================
# PLOT HELPERS
# =============================================================================

def _style_ax(ax, title, xlabel, ylabel, *, legend=True, legend_kw=None,
              grid_axis="both", clean_spines=False):
    """Aplica estilo padrão a um eixo matplotlib (título, labels, grid, legenda)."""
    ax.set_title(title, color="#111111", fontsize=12, fontweight="bold")
    ax.set_xlabel(xlabel, color="#1A1A1A", fontsize=9)
    ax.set_ylabel(ylabel, color="#1A1A1A", fontsize=9)
    ax.tick_params(labelsize=8, colors="#1A1A1A")
    if legend:
        ax.legend(**{**_LEGEND_KW, **(legend_kw or {})})
    ax.grid(True, color="#EEEEEE", linewidth=0.8, axis=grid_axis)
    if clean_spines:
        ax.spines[["top", "right"]].set_visible(False)
        ax.spines[["left", "bottom"]].set_color("#CCCCCC")


# =============================================================================
# PLOT FUNCTIONS
# =============================================================================

def plot_speed_over_time(players: list, ax, title="Speed Over Time"):
    ax.cla()
    ax.set_facecolor(MPL_LIGHT["axes.facecolor"])
    window = max(3, int(players[0].fps * 0.5))  # fps igual para todos
    for i, p in enumerate(players):
        color = PLAYER_COLORS[i % len(PLAYER_COLORS)]
        smooth = pd.Series(p.speed_kmh).rolling(window, center=True, min_periods=1).mean().values
        ax.plot(p.time_axis, smooth, color=color, linewidth=1.8,
                alpha=0.9, label=p.name)
    # Linhas de referência de zona legíveis sobre fundo branco
    zone_refs = {"Jog": (7, SPEED_ZONES[1][2]), "Run": (14, SPEED_ZONES[2][2]),
                 "High Run": (21, SPEED_ZONES[3][2]), "Sprint": (28, SPEED_ZONES[4][2])}
    for lbl, (val, color) in zone_refs.items():
        ax.axhline(y=val, color=color, linewidth=0.8, linestyle="--", alpha=0.55)
        ax.text(0.01, val + 0.4, lbl, color="#555555", fontsize=7,
                va="bottom", transform=ax.get_yaxis_transform())
    _style_ax(ax, title, "Time (s)", "Speed (km/h)")


def plot_accel_over_time(players: list, ax, title="Acceleration Over Time"):
    ax.cla()
    ax.set_facecolor(MPL_LIGHT["axes.facecolor"])
    for i, p in enumerate(players):
        color = PLAYER_COLORS[i % len(PLAYER_COLORS)]
        t = p.time_axis[1:]
        ax.plot(t, p.accel, color=color, linewidth=1.2, alpha=0.8, label=p.name)
        ax.fill_between(t, p.accel, 0, where=(p.accel > 0), alpha=0.12, color="#16A34A")
        ax.fill_between(t, p.accel, 0, where=(p.accel < 0), alpha=0.12, color="#DC2626")
    ax.axhline(0, color="#888888", linewidth=0.9, linestyle="--")
    _style_ax(ax, title, "Time (s)", "Accel (m/s²)")


def plot_distance_over_time(players: list, ax, title="Cumulative Distance"):
    ax.cla()
    ax.set_facecolor(MPL_LIGHT["axes.facecolor"])
    for i, p in enumerate(players):
        color = PLAYER_COLORS[i % len(PLAYER_COLORS)]
        dist_cumsum = np.cumsum(p.dist_per_frame)
        ax.plot(p.time_axis, dist_cumsum, color=color, linewidth=1.8, label=p.name)
    _style_ax(ax, title, "Time (s)", "Distance (m)")


def plot_bar_comparison(players: list, metric: str, ylabel: str, title: str, ax):
    ax.cla()
    ax.set_facecolor(MPL_LIGHT["axes.facecolor"])
    names  = [p.name for p in players]
    values = [getattr(p, metric) for p in players]
    colors = [PLAYER_COLORS[i % len(PLAYER_COLORS)] for i in range(len(players))]
    bars = ax.bar(names, values, color=colors, alpha=0.88, width=0.6,
                  edgecolor="white", linewidth=0.8)
    vmax = max(abs(v) for v in values) if values else 1
    for bar, val in zip(bars, values):
        bar_h = bar.get_height()
        # Valor sempre em preto, legível em qualquer posição
        offset = vmax * 0.025 if bar_h >= 0 else -vmax * 0.05
        va = "bottom" if bar_h >= 0 else "top"
        ax.text(bar.get_x() + bar.get_width() / 2,
                bar_h + offset, f"{val:.1f}",
                ha="center", va=va,
                color="#1A1A1A", fontsize=9, fontweight="bold")
    ax.tick_params(axis="x", rotation=30, labelsize=9, colors="#1A1A1A")
    _style_ax(ax, title, "", ylabel, legend=False, grid_axis="y", clean_spines=True)
    if values:
        margin = vmax * 0.22
        lo = min(0, min(values)) - margin
        hi = max(0, max(values)) + margin
        ax.set_ylim(lo, hi)


def plot_zone_bars(players: list, ax, title="Time in Speed Zones"):
    ax.cla()
    ax.set_facecolor(MPL_LIGHT["axes.facecolor"])
    zone_labels = [z[3] for z in SPEED_ZONES]
    zone_colors = [z[2] for z in SPEED_ZONES]
    names = [p.name for p in players]
    bottoms = np.zeros(len(players))
    for label, color in zip(zone_labels, zone_colors):
        vals = np.array([p.zone_times.get(label, 0) for p in players])
        ax.bar(names, vals, bottom=bottoms, color=color,
               alpha=0.88, label=label, width=0.6, edgecolor="white", linewidth=0.5)
        bottoms += vals
    ax.tick_params(axis="x", rotation=30, labelsize=9, colors="#1A1A1A")
    _style_ax(ax, title, "", "Time (s)",
              legend_kw={"loc": "upper right"}, grid_axis="y", clean_spines=True)


def plot_trajectory(player: "PlayerMetrics", ax, title=None,
                    field_length=None, field_width=None):
    ax.cla()
    ax.set_facecolor("#F0F4F0")
    x, y = player.x, player.y
    speed = np.concatenate([[0], player.speed_kmh])

    # Downsample para no maximo 2000 pontos (manter velocidade)
    step = max(1, len(x) // 2000)
    xi = x[::step]
    yi = y[::step]
    si = speed[::step]

    # Agrupa por zona e plota cada zona como LineCollection
    for lo, hi, color, label in SPEED_ZONES:
        mask = (si >= lo) & (si < hi)
        if not np.any(mask):
            continue
        # Cria segmentos para os pontos nessa zona
        segs = []
        for j in range(1, len(xi)):
            if mask[j]:
                segs.append([(xi[j-1], yi[j-1]), (xi[j], yi[j])])
        if segs:
            lc = LineCollection(segs, color=color, linewidth=2.5,
                                alpha=0.9, capstyle="round")
            ax.add_collection(lc)

    # Ponto inicial e final
    ax.scatter([x[0]],  [y[0]],  color="#16A34A", s=60, zorder=5, label="Start")
    ax.scatter([x[-1]], [y[-1]], color="#DC2626", s=60, zorder=5, label="End")

    # Contorno do campo
    if field_length and field_width:
        rect = mpatches.Rectangle((0, 0), field_length, field_width,
                                   linewidth=1.5, edgecolor="#555555",
                                   facecolor="none", linestyle="--")
        ax.add_patch(rect)

    # Legenda compacta de zonas
    zone_patches = [mpatches.Patch(facecolor=c, edgecolor="none", label=lbl)
                    for _, _, c, lbl in SPEED_ZONES]
    ax.legend(handles=zone_patches, fontsize=6, facecolor="white",
              edgecolor="#CCCCCC", labelcolor="#1A1A1A",
              loc="upper right", handlelength=1.2, handleheight=0.8)

    _style_ax(ax, title or player.name, "X (m)", "Y (m)",
              legend=False, clean_spines=True)
    if field_length and field_width:
        ax.set_aspect("equal", adjustable="box")
        ax.set_xlim(0, field_length)
        ax.set_ylim(0, field_width)
    else:
        ax.autoscale()
        ax.set_aspect("equal", adjustable="datalim")


def plot_heatmap(player: "PlayerMetrics", ax, title=None,
                 field_length=None, field_width=None):
    ax.cla()
    ax.set_facecolor("#F8F8F8")
    x, y = player.x, player.y

    # Histograma 2D — muito mais rapido que KDE e legivel para movimento linear
    h, xedges, yedges = np.histogram2d(x, y, bins=60)
    h = gaussian_filter(h.T, sigma=1.5)

    extent = [xedges[0], xedges[-1], yedges[0], yedges[-1]]
    im = ax.imshow(h, extent=extent, origin="lower", aspect="auto",
                   cmap="hot", interpolation="bilinear")

    # Contorno do campo
    if field_length and field_width:
        rect = mpatches.Rectangle((0, 0), field_length, field_width,
                                   linewidth=1.5, edgecolor="#444444",
                                   facecolor="none", linestyle="--")
        ax.add_patch(rect)
    _style_ax(ax, title or player.name, "X (m)", "Y (m)",
              legend=False, clean_spines=True)
    ax.set_aspect("equal", adjustable="box")
    if field_length and field_width:
        ax.set_xlim(0, field_length)
        ax.set_ylim(0, field_width)


# =============================================================================
# REPORTS WINDOW
# =============================================================================

class ReportsWindow(QMainWindow):
    def __init__(self, video_path=None, project_path=None):
        super().__init__()
        self.setWindowTitle("Reports")
        self.setGeometry(80, 80, 1600, 950)
        self.setStyleSheet(_DARK_SS)

        self.video_path   = video_path
        self.project_path = project_path
        self.df           = None
        self.fps          = 24.0
        self.players      = {}      # mid → PlayerMetrics
        self.player_names = {}      # mid → str
        self.field_length = None
        self.field_width  = None

        self._init_ui()
        self._auto_load()

    # ── UI ────────────────────────────────────────────────────────────────────

    def _init_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QHBoxLayout(central)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        # ── Left panel: player selection ──────────────────────────────────────
        left = QWidget()
        left.setFixedWidth(220)
        left.setStyleSheet("background-color: #161621; border-right: 1px solid #222230;")
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(12, 16, 12, 12)
        left_layout.setSpacing(8)

        lbl = QLabel("PLAYERS")
        lbl.setStyleSheet("color: #6868A0; font-size: 10px; font-weight: bold; letter-spacing: 1.5px;")
        left_layout.addWidget(lbl)

        self.player_list = QListWidget()
        self.player_list.setSelectionMode(QListWidget.SelectionMode.NoSelection)
        left_layout.addWidget(self.player_list)

        sel_row = QHBoxLayout()
        btn_all  = QPushButton("All")
        btn_none = QPushButton("None")
        btn_all.clicked.connect(self._select_all)
        btn_none.clicked.connect(self._select_none)
        sel_row.addWidget(btn_all)
        sel_row.addWidget(btn_none)
        left_layout.addLayout(sel_row)

        # Status
        self.status_lbl = QLabel("")
        self.status_lbl.setWordWrap(True)
        self.status_lbl.setStyleSheet("color: #6868A0; font-size: 10px; padding: 4px;")
        left_layout.addWidget(self.status_lbl)

        root.addWidget(left)

        # ── Right: tabs ───────────────────────────────────────────────────────
        right = QWidget()
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(12, 12, 12, 12)
        right_layout.setSpacing(8)

        # Toolbar
        toolbar = QHBoxLayout()

        self.csv_label = QLabel("No data loaded")
        self.csv_label.setStyleSheet("color: #6868A0; font-style: italic;")
        toolbar.addWidget(self.csv_label)
        toolbar.addStretch()

        btn_load = QPushButton("Open CSV")
        btn_load.clicked.connect(self._open_csv)
        toolbar.addWidget(btn_load)

        btn_refresh = QPushButton("↻ Refresh")
        btn_refresh.setProperty("role", "primary")
        btn_refresh.clicked.connect(self._refresh)
        toolbar.addWidget(btn_refresh)

        right_layout.addLayout(toolbar)

        # Tabs
        self.tabs = QTabWidget()
        right_layout.addWidget(self.tabs)

        # Tab: Overview (barras comparativas)
        self.tab_overview = QWidget()
        self._build_overview_tab()
        self.tabs.addTab(self.tab_overview, "Overview")

        # Tab: Speed & Accel (linhas temporais)
        self.tab_speed = QWidget()
        self._build_speed_tab()
        self.tabs.addTab(self.tab_speed, "Speed & Accel")

        # Tab: Trajectory
        self.tab_traj = QWidget()
        self._build_traj_tab()
        self.tabs.addTab(self.tab_traj, "Trajectories")

        # Tab: Heatmap
        self.tab_heat = QWidget()
        self._build_heat_tab()
        self.tabs.addTab(self.tab_heat, "Heatmaps")

        root.addWidget(right, stretch=1)

        # Conecta tab change uma única vez aqui (evita duplicação em showEvent)
        self.tabs.currentChanged.connect(lambda _: self._refresh())

    # ── Tab builders ──────────────────────────────────────────────────────────

    def _build_figure_tab(self, tab_widget, figsize=(14, 8)):
        """Helper: cria Figure + FigureCanvas em um tab widget."""
        layout = QVBoxLayout(tab_widget)
        layout.setContentsMargins(0, 8, 0, 0)
        with plt.rc_context(MPL_LIGHT):
            fig = Figure(figsize=figsize, facecolor="white")
        canvas = FigureCanvas(fig)
        layout.addWidget(canvas)
        return fig, canvas

    def _build_overview_tab(self):
        self.fig_overview, self.canvas_overview = self._build_figure_tab(
            self.tab_overview, figsize=(14, 8))

    def _build_speed_tab(self):
        self.fig_speed, self.canvas_speed = self._build_figure_tab(
            self.tab_speed, figsize=(14, 9))

    def _build_traj_tab(self):
        self.fig_traj, self.canvas_traj = self._build_figure_tab(
            self.tab_traj, figsize=(14, 8))

    def _build_heat_tab(self):
        self.fig_heat, self.canvas_heat = self._build_figure_tab(
            self.tab_heat, figsize=(14, 8))

    # ── Data loading ──────────────────────────────────────────────────────────

    def _video_stem_base(self):
        """Retorna (stem, base) do vídeo ativo, removendo sufixo _tracked."""
        stem = os.path.splitext(os.path.basename(self.video_path))[0]
        base = stem[:-8] if stem.endswith("_tracked") else stem
        return stem, base

    def _auto_load(self):
        """Carrega automaticamente o CSV de homografia do projeto."""
        if not self.project_path or not self.video_path:
            return

        stem, base = self._video_stem_base()

        homog_dir = os.path.join(self.project_path, "data", "homography")
        candidates = [
            os.path.join(homog_dir, f"{base}_homography.csv"),
            os.path.join(homog_dir, f"{base}_tracked_homography.csv"),
            os.path.join(homog_dir, f"{stem}_homography.csv"),
        ]
        for path in candidates:
            if os.path.isfile(path):
                self._load_csv(path)
                return

        # Fallback fuzzy
        if os.path.isdir(homog_dir):
            for f in sorted(os.listdir(homog_dir)):
                if f.startswith(base) and f.endswith("_homography.csv"):
                    self._load_csv(os.path.join(homog_dir, f))
                    return

    def _open_csv(self):
        start = os.path.join(self.project_path or "", "data", "homography")
        path, _ = QFileDialog.getOpenFileName(
            self, "Select Homography CSV", start, "CSV Files (*.csv)")
        if path:
            self._load_csv(path)

    def _load_csv(self, path: str):
        try:
            self.df = pd.read_csv(path)
            self.csv_label.setText(f"✓ {os.path.basename(path)}")
            self.csv_label.setStyleSheet("color: #2DD480; font-weight: bold;")

            # Detecta FPS do vídeo
            if self.video_path and os.path.isfile(self.video_path):
                cap = cv2.VideoCapture(self.video_path)
                fps = cap.get(cv2.CAP_PROP_FPS)
                cap.release()
                if fps > 0:
                    self.fps = fps

            # Carrega nomes dos jogadores e dimensões do campo
            self._load_player_names()
            self._load_field_dimensions()

            # Calcula métricas
            self._compute_metrics()

            # Popula lista de jogadores
            self._populate_player_list()

            # Desenha gráficos
            self._refresh()

        except Exception as e:
            QMessageBox.critical(self, "Error", f"Could not load CSV:\n{e}")

    def _load_field_dimensions(self):
        """Lê field_length e field_width do JSON da matriz de homografia."""
        self.field_length = None
        self.field_width  = None
        if not self.project_path or not self.video_path:
            return
        stem, base = self._video_stem_base()
        metadata_dir = os.path.join(self.project_path, "metadata")
        candidates = [
            os.path.join(metadata_dir, f"{base}_homography_matrix.json"),
            os.path.join(metadata_dir, f"{base}_tracked_homography_matrix.json"),
            os.path.join(metadata_dir, f"{stem}_homography_matrix.json"),
        ]
        if os.path.isdir(metadata_dir):
            for f in os.listdir(metadata_dir):
                if f.startswith(base) and f.endswith("_homography_matrix.json"):
                    p = os.path.join(metadata_dir, f)
                    if p not in candidates:
                        candidates.append(p)
        for path in candidates:
            if os.path.isfile(path):
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    fl = data.get("field_length")
                    fw = data.get("field_width")
                    if fl and fw:
                        self.field_length = float(fl)
                        self.field_width  = float(fw)
                        return
                except Exception:
                    pass

    def _load_player_names(self):
        self.player_names = {}
        if not self.project_path or not self.video_path:
            return
        _, base = self._video_stem_base()
        path = os.path.join(self.project_path, "metadata", f"{base}_players.json")
        if not os.path.isfile(path):
            return
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.player_names = {int(k): v for k, v in data.items()}
        except Exception:
            pass

    def _compute_metrics(self):
        if self.df is None:
            return
        mids = sorted({int(c[1:-2]) for c in self.df.columns
                       if c.startswith("p") and c.endswith("_x")})
        self.players = {}
        for mid in mids:
            x = self.df[f"p{mid}_x"].values
            y = self.df[f"p{mid}_y"].values
            name = self.player_names.get(mid, f"p{mid}")
            self.players[mid] = PlayerMetrics(mid, x, y, self.fps, name)

    def _populate_player_list(self):
        self.player_list.blockSignals(True)
        self.player_list.clear()
        for i, (mid, p) in enumerate(self.players.items()):
            item = QListWidgetItem(f"  {p.name}")
            item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
            item.setCheckState(Qt.CheckState.Checked)
            item.setData(Qt.ItemDataRole.UserRole, mid)
            color = PLAYER_COLORS[i % len(PLAYER_COLORS)]
            item.setForeground(QColor(color))
            self.player_list.addItem(item)
        self.player_list.blockSignals(False)
        try:
            self.player_list.itemChanged.disconnect(self._on_player_check)
        except RuntimeError:
            pass
        self.player_list.itemChanged.connect(self._on_player_check)

    def _get_selected_players(self):
        selected = []
        for i in range(self.player_list.count()):
            item = self.player_list.item(i)
            if item.checkState() == Qt.CheckState.Checked:
                mid = item.data(Qt.ItemDataRole.UserRole)
                if mid in self.players:
                    selected.append(self.players[mid])
        return selected

    def _set_all_checked(self, state):
        self.player_list.blockSignals(True)
        for i in range(self.player_list.count()):
            self.player_list.item(i).setCheckState(state)
        self.player_list.blockSignals(False)
        self._refresh()

    def _select_all(self):
        self._set_all_checked(Qt.CheckState.Checked)

    def _select_none(self):
        self._set_all_checked(Qt.CheckState.Unchecked)

    def _on_player_check(self, _item):
        pass  # Refresh apenas pelo botão ↻ Refresh

    # ── Rendering ─────────────────────────────────────────────────────────────

    def _refresh(self):
        players = self._get_selected_players()
        if not players:
            return
        tab = self.tabs.currentIndex()
        if tab == 0:
            self._draw_overview(players)
        elif tab == 1:
            self._draw_speed(players)
        elif tab == 2:
            self._draw_trajectories(players)
        elif tab == 3:
            self._draw_heatmaps(players)
        # Atualiza status
        total_dist = sum(p.total_distance for p in players)
        self.status_lbl.setText(
            f"{len(players)} players\n"
            f"Duration: {players[0].total_time:.0f}s\n"
            f"Total dist: {total_dist:.0f}m"
        )

    def _draw_overview(self, players):
        self.fig_overview.clf()
        with plt.rc_context(MPL_LIGHT):
            gs = GridSpec(2, 3, figure=self.fig_overview,
                          hspace=0.45, wspace=0.35,
                          left=0.07, right=0.97, top=0.93, bottom=0.12)
            ax1 = self.fig_overview.add_subplot(gs[0, 0])
            ax2 = self.fig_overview.add_subplot(gs[0, 1])
            ax3 = self.fig_overview.add_subplot(gs[0, 2])
            ax4 = self.fig_overview.add_subplot(gs[1, 0])
            ax5 = self.fig_overview.add_subplot(gs[1, 1])
            ax6 = self.fig_overview.add_subplot(gs[1, 2])

            plot_bar_comparison(players, "total_distance",
                                "Distance (m)", "Total Distance", ax1)
            plot_bar_comparison(players, "max_speed_kmh",
                                "Speed (km/h)", "Max Speed", ax2)
            plot_bar_comparison(players, "avg_speed_kmh",
                                "Speed (km/h)", "Avg Speed", ax3)
            plot_bar_comparison(players, "max_accel",
                                "Accel (m/s²)", "Max Acceleration", ax4)
            plot_bar_comparison(players, "max_decel",
                                "Decel (m/s²)", "Max Deceleration", ax5)
            plot_zone_bars(players, ax6, "Time in Speed Zones")

        self.canvas_overview.draw_idle()

    def _draw_speed(self, players):
        self.fig_speed.clf()
        with plt.rc_context(MPL_LIGHT):
            gs = GridSpec(3, 1, figure=self.fig_speed,
                          hspace=0.45, left=0.07, right=0.97,
                          top=0.94, bottom=0.08)
            ax1 = self.fig_speed.add_subplot(gs[0])
            ax2 = self.fig_speed.add_subplot(gs[1])
            ax3 = self.fig_speed.add_subplot(gs[2])

            plot_speed_over_time(players, ax1)
            plot_accel_over_time(players, ax2)
            plot_distance_over_time(players, ax3)

        self.canvas_speed.draw_idle()

    def _draw_grid_plots(self, fig, canvas, players, plot_fn):
        """Renderiza plots em grid (1 por jogador) numa figura compartilhada."""
        fig.clf()
        with plt.rc_context(MPL_LIGHT):
            n = len(players)
            cols = min(4, n)
            rows = (n + cols - 1) // cols
            gs = GridSpec(rows, cols, figure=fig,
                          hspace=0.4, wspace=0.3,
                          left=0.05, right=0.97, top=0.93, bottom=0.08)
            for i, p in enumerate(players):
                ax = fig.add_subplot(gs[i // cols, i % cols])
                plot_fn(p, ax, field_length=self.field_length,
                        field_width=self.field_width)
        canvas.draw_idle()

    def _draw_trajectories(self, players):
        self._draw_grid_plots(self.fig_traj, self.canvas_traj, players, plot_trajectory)

    def _draw_heatmaps(self, players):
        self._draw_grid_plots(self.fig_heat, self.canvas_heat, players, plot_heatmap)

    def showEvent(self, event):
        super().showEvent(event)
        QTimer.singleShot(100, self._refresh)

    def closeEvent(self, event):
        plt.close("all")
        super().closeEvent(event)


# =============================================================================
# FACTORY + BRIDGE
# =============================================================================

def run_reports(video_path=None, project_path=None):
    return ReportsWindow(video_path=video_path, project_path=project_path)


class ReportsManager(QObject):
    def __init__(self, videos_manager, parent=None):
        super().__init__(parent)
        self._videos_manager = videos_manager
        self._window         = None

    @Slot()
    def open_tool(self):
        video_path   = self._videos_manager.activeVideoPath
        project_path = self._videos_manager.activeProjectPath
        if not video_path or not project_path:
            return
        if self._window is not None:
            self._window.deleteLater()
        self._window = ReportsWindow(
            video_path=video_path,
            project_path=project_path,
        )
        self._window.show()
