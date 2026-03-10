// src/qml/components/ProjectsPage.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Props ──────────────────────────────────────────────────────────────────
    property QtObject theme

    // Accent palette — cycles per card index
    readonly property var accentPalette: [
        "#0071E3",  // blue
        "#30D158",  // green
        "#FF9F0A",  // orange
        "#BF5AF2",  // purple
        "#FF375F",  // red
    ]

    function accentFor(i) { return accentPalette[i % accentPalette.length] }

    // ── Header ─────────────────────────────────────────────────────────────────
    Item {
        id: header
        anchors.top:         parent.top
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.topMargin:   32
        anchors.leftMargin:  32
        anchors.rightMargin: 32
        height: 44

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:               "Projects"
            font.family:        "Rajdhani"
            font.weight:        Font.Bold
            font.pixelSize:     28
            font.letterSpacing: 1
            color:              theme.textPrimary
        }

        // ── New Project button ────────────────────────────────────────────────
        Rectangle {
            id: newBtn
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            width:  newBtnRow.implicitWidth + 24
            height: 34
            radius: 8
            color:  newBtnHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
            Behavior on color { ColorAnimation { duration: 150 } }

            property bool newBtnHov: false

            Row {
                id: newBtnRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text:             "+"
                    font.pixelSize:   17
                    font.weight:      Font.Light
                    color:            "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:             "New Project"
                    font.family:      "Poppins"
                    font.pixelSize:   12
                    font.weight:      Font.Medium
                    color:            "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:  parent.newBtnHov = true
                onExited:   parent.newBtnHov = false
                onClicked:  { nameField.text = ""; newProjectDialog.open() }
            }
        }
    }

    // ── Subtitle ───────────────────────────────────────────────────────────────
    Text {
        id: subtitle
        anchors.top:        header.bottom
        anchors.topMargin:  4
        anchors.left:       header.left
        text: {
            var n = projectsManager ? projectsManager.projects.length : 0
            return n === 0 ? "No projects yet"
                           : n + " project" + (n === 1 ? "" : "s")
        }
        font.family:    "Poppins"
        font.pixelSize: 11
        color:          theme.textMuted
    }

    // ── Empty state ────────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing:          14
        visible:          projectsManager ? projectsManager.projects.length === 0 : true

        Rectangle {
            width:  64; height: 64; radius: 16
            color:  theme.surface2
            border.color: theme.border
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.centerIn: parent
                text:           "⊞"
                font.pixelSize: 26
                color:          theme.textMuted
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:               "No projects yet"
            font.family:        "Rajdhani"
            font.weight:        Font.Bold
            font.pixelSize:     22
            color:              theme.textPrimary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Create your first project to start tracking"
            font.family:    "Poppins"
            font.pixelSize: 12
            color:          theme.textMuted
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width:  160; height: 36; radius: 8
            color:  emptyBtnHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
            Behavior on color { ColorAnimation { duration: 150 } }

            property bool emptyBtnHov: false

            Text {
                anchors.centerIn: parent
                text:           "+ New Project"
                font.family:    "Poppins"
                font.pixelSize: 12
                font.weight:    Font.Medium
                color:          "white"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:  parent.emptyBtnHov = true
                onExited:   parent.emptyBtnHov = false
                onClicked:  { nameField.text = ""; newProjectDialog.open() }
            }
        }
    }

    // ── Project cards grid ─────────────────────────────────────────────────────
    ScrollView {
        id: scrollArea
        anchors.top:         subtitle.bottom
        anchors.topMargin:   24
        anchors.left:        parent.left
        anchors.right:       parent.right
        anchors.bottom:      parent.bottom
        anchors.leftMargin:  32
        anchors.rightMargin: 32
        clip:                true
        visible:             projectsManager ? projectsManager.projects.length > 0 : false

        Flow {
            id:      cardsFlow
            width:   scrollArea.availableWidth
            spacing: 16

            // Card width — fills width with 1..N columns (min 220px each)
            readonly property int  numCols: Math.max(1, Math.floor(width / 240))
            readonly property real cardW:   (width - spacing * (numCols - 1)) / numCols

            Repeater {
                id:    cardsRepeater
                model: projectsManager ? projectsManager.projects : []

                delegate: Rectangle {
                    id: card

                    width:  cardsFlow.cardW
                    height: 120
                    radius: 10
                    color:        cardHov ? theme.surface2 : theme.surface
                    border.color: cardHov
                                  ? Qt.rgba(0, 113/255, 227/255, 0.35)
                                  : theme.border
                    border.width: 1
                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    property bool   cardHov: hoverHandler.hovered
                    property var    proj:    modelData   // {name, date, videoCount}
                    property string accent:  root.accentFor(index)

                    // ── Hover handler (passive — works through child MouseAreas) ──
                    HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }

                    // ── Left accent strip ──────────────────────────────────────
                    Rectangle {
                        anchors.left:         parent.left
                        anchors.top:          parent.top
                        anchors.bottom:       parent.bottom
                        anchors.topMargin:    3
                        anchors.bottomMargin: 3
                        width:  3
                        radius: 2
                        color:  card.accent
                    }

                    // ── Project initial circle ────────────────────────────────
                    Rectangle {
                        id: initCircle
                        anchors.left:       parent.left
                        anchors.leftMargin: 20
                        anchors.top:        parent.top
                        anchors.topMargin:  18
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(
                            Qt.color(card.accent).r,
                            Qt.color(card.accent).g,
                            Qt.color(card.accent).b,
                            0.14
                        )

                        Text {
                            anchors.centerIn: parent
                            text:           card.proj ? card.proj.name.charAt(0).toUpperCase() : ""
                            font.family:    "Rajdhani"
                            font.weight:    Font.Bold
                            font.pixelSize: 16
                            color:          card.accent
                        }
                    }

                    // ── Project name ──────────────────────────────────────────
                    Text {
                        anchors.left:           initCircle.right
                        anchors.leftMargin:     12
                        anchors.right:          parent.right
                        anchors.rightMargin:    16
                        anchors.verticalCenter: initCircle.verticalCenter
                        text:            card.proj ? card.proj.name : ""
                        font.family:     "Rajdhani"
                        font.weight:     Font.Bold
                        font.pixelSize:  15
                        color:           theme.textPrimary
                        elide:           Text.ElideRight
                    }

                    // ── Bottom metadata ───────────────────────────────────────
                    Row {
                        anchors.left:         parent.left
                        anchors.leftMargin:   20
                        anchors.bottom:       parent.bottom
                        anchors.bottomMargin: 14
                        spacing: 8
                        visible: !card.cardHov

                        Text {
                            text:           card.proj ? card.proj.date : ""
                            font.family:    "Poppins"
                            font.pixelSize: 10
                            color:          theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: {
                                if (!card.proj) return ""
                                var n = card.proj.videoCount
                                return n + " video" + (n === 1 ? "" : "s")
                            }
                            font.family:    "Poppins"
                            font.pixelSize: 10
                            color:          theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // ── Hover action buttons ──────────────────────────────────
                    Row {
                        anchors.right:        parent.right
                        anchors.rightMargin:  12
                        anchors.bottom:       parent.bottom
                        anchors.bottomMargin: 10
                        spacing:              6
                        opacity:  card.cardHov ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        // Open
                        Rectangle {
                            width: 50; height: 24; radius: 6
                            color: openHov ? "#0071E3" : Qt.rgba(0, 113/255, 227/255, 0.12)
                            border.color: openHov ? "#0071E3" : Qt.rgba(0, 113/255, 227/255, 0.3)
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            property bool openHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Open"
                                font.family:    "Poppins"
                                font.pixelSize: 9
                                font.weight:    Font.Medium
                                color:          parent.openHov ? "white" : "#0071E3"
                                Behavior on color { ColorAnimation { duration: 110 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:  parent.openHov = true
                                onExited:   parent.openHov = false
                                onClicked:  console.log("Open project:", card.proj ? card.proj.name : "")
                            }
                        }

                        // Rename
                        Rectangle {
                            width: 62; height: 24; radius: 6
                            color: renHov
                                   ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.08)
                                   : Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.04)
                            border.color: theme.border
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 110 } }

                            property bool renHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Rename"
                                font.family:    "Poppins"
                                font.pixelSize: 9
                                font.weight:    Font.Medium
                                color:          theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:  parent.renHov = true
                                onExited:   parent.renHov = false
                                onClicked: {
                                    renameDialog.oldName = card.proj.name
                                    renameField.text     = card.proj.name
                                    renameDialog.open()
                                }
                            }
                        }

                        // Delete
                        Rectangle {
                            width: 52; height: 24; radius: 6
                            color:        delHov ? Qt.rgba(1, 0.22, 0.37, 0.15)
                                                 : Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.04)
                            border.color: delHov ? Qt.rgba(1, 0.22, 0.37, 0.45) : theme.border
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            property bool delHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Delete"
                                font.family:    "Poppins"
                                font.pixelSize: 9
                                font.weight:    Font.Medium
                                color:          parent.delHov ? "#FF375F" : theme.textMuted
                                Behavior on color { ColorAnimation { duration: 110 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:  parent.delHov = true
                                onExited:   parent.delHov = false
                                onClicked: {
                                    deleteDialog.projectName = card.proj.name
                                    deleteDialog.open()
                                }
                            }
                        }
                    }
                } // delegate Rectangle
            } // Repeater
        } // Flow
    } // ScrollView

    // ══════════════════════════════════════════════════════════════════════════
    // New Project dialog
    // ══════════════════════════════════════════════════════════════════════════
    Popup {
        id:           newProjectDialog
        anchors.centerIn: Overlay.overlay
        width:  360
        height: 186
        modal:  true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color:        theme.surface2
            border.color: theme.border
            border.width: 1
            radius:       12
        }

        Column {
            anchors.fill:    parent
            anchors.margins: 24
            spacing:         16

            Text {
                text:             "New Project"
                font.family:      "Rajdhani"
                font.weight:      Font.Bold
                font.pixelSize:   18
                color:            theme.textPrimary
            }

            Rectangle {
                width:  parent.width
                height: 36
                radius: 8
                color:  theme.surface
                border.color: nameField.activeFocus ? "#0071E3" : theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id:               nameField
                    anchors.fill:     parent
                    anchors.margins:  1
                    placeholderText:  "Project name"
                    background:       Item {}
                    color:            theme.textPrimary
                    placeholderTextColor: theme.textMuted
                    font.family:      "Poppins"
                    font.pixelSize:   12
                    leftPadding:      12
                    Keys.onReturnPressed: newProjectDialog.doCreate()
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color:        cancelHov1 ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.06) : "transparent"
                    border.color: theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool cancelHov1: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Cancel"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        color:          theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.cancelHov1 = true
                        onExited:   parent.cancelHov1 = false
                        onClicked:  { newProjectDialog.close(); nameField.text = "" }
                    }
                }

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color: createHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool createHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Create"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        font.weight:    Font.Medium
                        color:          "white"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.createHov = true
                        onExited:   parent.createHov = false
                        onClicked:  newProjectDialog.doCreate()
                    }
                }
            }
        }

        function doCreate() {
            var name = nameField.text.trim()
            if (name.length > 0 && projectsManager) {
                projectsManager.createProject(name)
                nameField.text = ""
                close()
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Rename dialog
    // ══════════════════════════════════════════════════════════════════════════
    Popup {
        id:      renameDialog
        anchors.centerIn: Overlay.overlay
        width:   360
        height:  186
        modal:   true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string oldName: ""

        background: Rectangle {
            color:        theme.surface2
            border.color: theme.border
            border.width: 1
            radius:       12
        }

        Column {
            anchors.fill:    parent
            anchors.margins: 24
            spacing:         16

            Text {
                text:             "Rename Project"
                font.family:      "Rajdhani"
                font.weight:      Font.Bold
                font.pixelSize:   18
                color:            theme.textPrimary
            }

            Rectangle {
                width:  parent.width
                height: 36
                radius: 8
                color:  theme.surface
                border.color: renameField.activeFocus ? "#0071E3" : theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id:              renameField
                    anchors.fill:    parent
                    anchors.margins: 1
                    background:      Item {}
                    color:           theme.textPrimary
                    font.family:     "Poppins"
                    font.pixelSize:  12
                    leftPadding:     12
                    Keys.onReturnPressed: renameDialog.doRename()
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color:        cancelHov2 ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.06) : "transparent"
                    border.color: theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool cancelHov2: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Cancel"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        color:          theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.cancelHov2 = true
                        onExited:   parent.cancelHov2 = false
                        onClicked:  renameDialog.close()
                    }
                }

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color: saveHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool saveHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Save"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        font.weight:    Font.Medium
                        color:          "white"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.saveHov = true
                        onExited:   parent.saveHov = false
                        onClicked:  renameDialog.doRename()
                    }
                }
            }
        }

        function doRename() {
            var newName = renameField.text.trim()
            if (newName.length > 0 && projectsManager) {
                projectsManager.renameProject(oldName, newName)
                close()
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Delete confirm dialog
    // ══════════════════════════════════════════════════════════════════════════
    Popup {
        id:      deleteDialog
        anchors.centerIn: Overlay.overlay
        width:   320
        height:  162
        modal:   true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string projectName: ""

        background: Rectangle {
            color:        theme.surface2
            border.color: theme.border
            border.width: 1
            radius:       12
        }

        Column {
            anchors.fill:    parent
            anchors.margins: 24
            spacing:         12

            Text {
                text:             "Delete Project"
                font.family:      "Rajdhani"
                font.weight:      Font.Bold
                font.pixelSize:   18
                color:            theme.textPrimary
            }

            Text {
                width:          parent.width
                text:           "Delete \u201c" + deleteDialog.projectName + "\u201d? This cannot be undone."
                font.family:    "Poppins"
                font.pixelSize: 11
                color:          theme.textMuted
                wrapMode:       Text.WordWrap
            }

            Row {
                anchors.right: parent.right
                spacing:       8
                topPadding:    4

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color:        cancelHov3 ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.06) : "transparent"
                    border.color: theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool cancelHov3: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Cancel"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        color:          theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.cancelHov3 = true
                        onExited:   parent.cancelHov3 = false
                        onClicked:  deleteDialog.close()
                    }
                }

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color: delConfirmHov ? Qt.darker("#FF375F", 1.1) : "#FF375F"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool delConfirmHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Delete"
                        font.family:    "Poppins"
                        font.pixelSize: 11
                        font.weight:    Font.Medium
                        color:          "white"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:  parent.delConfirmHov = true
                        onExited:   parent.delConfirmHov = false
                        onClicked: {
                            if (projectsManager)
                                projectsManager.deleteProject(deleteDialog.projectName)
                            deleteDialog.close()
                        }
                    }
                }
            }
        }
    }
}
