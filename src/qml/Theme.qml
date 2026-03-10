// src/qml/Theme.qml
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bg:       "#111114"
    readonly property color surface:  "#161619"
    readonly property color surface2: "#1C1C22"

    // Borders
    readonly property color border:   "#1E1E26"

    // Text
    readonly property color textPrimary: "#E8E8ED"
    readonly property color textMuted:   "#555560"

    // Accent
    readonly property color accent:      "#0071E3"   // Apple blue
    readonly property color accentHover: "#0077ED"

    // Semantic
    readonly property color green: "#4ade80"

    // Typography — centralised font family names
    readonly property string fontDisplay: "Bebas Neue"
    readonly property string fontBody:    "Space Grotesk"

    // Sidebar dimensions
    readonly property int sidebarExpanded:  220
    readonly property int sidebarCollapsed: 64
    readonly property int collapseMs:       280
}
