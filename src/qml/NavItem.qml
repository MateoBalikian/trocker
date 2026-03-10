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
    height: 36

    // ── State ──────────────────────────────────────────────────────────────
    property bool hovered: false

    // ── Hover pill ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.leftMargin:     8
        anchors.rightMargin:    8
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        radius: 7
        color: root.active  ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.07)
             : root.hovered ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.04)
             : "transparent"
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // ── Active left bar ────────────────────────────────────────────────────
    Rectangle {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        width:  2
        height: root.active ? 18 : 0
        radius: 1
        color:  theme.textPrimary
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    // ── Icon ───────────────────────────────────────────────────────────────
    Text {
        id: iconText
        anchors.left:        parent.left
        anchors.leftMargin:  root.collapsed ? 0 : 18
        anchors.verticalCenter: parent.verticalCenter
        width:               root.collapsed ? parent.width : implicitWidth
        horizontalAlignment: root.collapsed ? Text.AlignHCenter : Text.AlignLeft
        text:           root.icon
        font.pixelSize: 14
        color: root.active ? theme.textPrimary : theme.textMuted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Label (hidden when collapsed) ──────────────────────────────────────
    Text {
        anchors.left:           iconText.right
        anchors.leftMargin:     10
        anchors.verticalCenter: parent.verticalCenter
        text:           root.label
        font.family:    root.theme.fontBody
        font.pixelSize: 12
        font.weight:    root.active ? Font.DemiBold : Font.Normal
        color: root.active ? theme.textPrimary : theme.textMuted
        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color   { ColorAnimation  { duration: 150 } }
    }

    // ── Tooltip (só quando collapsed) ─────────────────────────────────────
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
