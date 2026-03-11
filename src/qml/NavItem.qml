// src/qml/NavItem.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Props ──────────────────────────────────────────────────────────────
    property string   label:     ""
    property string   icon:      ""
    property bool     active:    false
    property bool     collapsed: false
    property QtObject theme

    signal clicked()

    // ── Dimensions ─────────────────────────────────────────────────────────
    width:  parent ? parent.width : 0
    height: 42

    property bool hovered: false

    // ── Background pill ────────────────────────────────────────────────────
    Rectangle {
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.leftMargin:     8
        anchors.rightMargin:    8
        anchors.verticalCenter: parent.verticalCenter
        height: 36
        radius: 8
        color: root.active  ? theme.accentBg
             : root.hovered ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.05)
             : "transparent"
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

        // Active left accent bar (inside pill, on left edge)
        Rectangle {
            visible: root.active
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            width:  3
            height: root.active ? 22 : 0
            radius: 2
            color:  theme.accent
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        }
    }

    // ── Icon ───────────────────────────────────────────────────────────────
    Text {
        id: iconText
        anchors.left:           parent.left
        anchors.leftMargin:     root.collapsed ? 0 : 22
        anchors.verticalCenter: parent.verticalCenter
        width:                  root.collapsed ? parent.width : implicitWidth
        horizontalAlignment:    root.collapsed ? Text.AlignHCenter : Text.AlignLeft
        text:           root.icon
        font.pixelSize: 15
        color: root.active ? theme.accent
             : root.hovered ? theme.textSecondary
             : theme.textMuted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Label ──────────────────────────────────────────────────────────────
    Text {
        anchors.left:           iconText.right
        anchors.leftMargin:     10
        anchors.verticalCenter: parent.verticalCenter
        text:           root.label
        font.family:    root.theme.fontBody
        font.pixelSize: 13
        font.weight:    root.active ? Font.DemiBold : Font.Normal
        color: root.active  ? theme.accentLight
             : root.hovered ? theme.textSecondary
             : theme.textMuted
        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation  { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color   { ColorAnimation   { duration: 150 } }
    }

    // ── Tooltip when collapsed ─────────────────────────────────────────────
    ToolTip {
        visible: root.collapsed && root.hovered
        text:    root.label
        delay:   500
        timeout: 3000
    }

    // ── Mouse ──────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: root.clicked()
    }
}
