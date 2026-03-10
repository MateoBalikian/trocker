// src/qml/main.qml
import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    title: "Trocker"
    color: "#111114"  // prevents white flash before QML renders
    visible: true

    property bool collapsed:   false
    property int  activeIndex: 0

    Theme { id: theme }

    Rectangle {
        anchors.fill: parent
        color: theme.bg

        Sidebar {
            id: sidebar
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.bottom: parent.bottom
            theme:          theme
            collapsed:      root.collapsed
            activeIndex:    root.activeIndex
            onNavSelected:      (i) => root.activeIndex = i
            onToggleCollapse:   root.collapsed = !root.collapsed
        }

        // ── Content placeholder ────────────────────────────────────────────
        Item {
            anchors.left:   sidebar.right
            anchors.top:    parent.top
            anchors.right:  parent.right
            anchors.bottom: parent.bottom

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.activeIndex === 0 ? "Projects"
                        : root.activeIndex === 1 ? "Tracker"
                        : root.activeIndex === 2 ? "Homography"
                        : root.activeIndex === 3 ? "Reports"
                        : "Settings"
                    font.family:      "Rajdhani"
                    font.weight:      Font.Bold
                    font.pixelSize:   52
                    font.letterSpacing: 2
                    color:            theme.textPrimary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           "content area"
                    font.family:    "Poppins"
                    font.pixelSize: 12
                    color:          theme.textMuted
                }
            }
        }
    }
}
