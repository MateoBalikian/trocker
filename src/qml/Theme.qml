// src/qml/Theme.qml
import QtQuick

QtObject {
    // ── Backgrounds ────────────────────────────────────────────────────────
    readonly property color bg:       "#0D0D14"
    readonly property color surface:  "#161621"
    readonly property color surface2: "#1D1D2C"
    readonly property color surface3: "#242438"

    // ── Borders ────────────────────────────────────────────────────────────
    readonly property color border:      "#222230"
    readonly property color borderHover: "#303050"

    // ── Text ───────────────────────────────────────────────────────────────
    readonly property color textPrimary:   "#EEEEF8"
    readonly property color textSecondary: "#A0A0C0"
    readonly property color textMuted:     "#6868A0"

    // ── Accent ─────────────────────────────────────────────────────────────
    readonly property color accent:      "#4282FF"
    readonly property color accentHover: "#6098FF"
    readonly property color accentBg:    "#13213F"   // active nav bg
    readonly property color accentLight: "#C0D8FF"   // active nav text

    // ── Semantic ───────────────────────────────────────────────────────────
    readonly property color green:   "#2DD480"
    readonly property color orange:  "#FF9830"
    readonly property color red:     "#FF4560"

    // ── Typography ─────────────────────────────────────────────────────────
    readonly property string fontDisplay: "Rajdhani"
    readonly property string fontBody:    "Poppins"

    // ── Sidebar dimensions ─────────────────────────────────────────────────
    readonly property int sidebarExpanded:  240
    readonly property int sidebarCollapsed: 64
    readonly property int collapseMs:       280
}
