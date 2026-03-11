// src/qml/components/ProjectsPage.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Props ──────────────────────────────────────────────────────────────────
    property QtObject theme

    // Accent palette — cycles per card index
    readonly property var accentPalette: [
        "#4282FF",  // blue
        "#2DD480",  // green
        "#FF9830",  // orange
        "#BF5AF2",  // purple
        "#FF4560",  // red
    ]

    function accentFor(i) { return accentPalette[i % accentPalette.length] }

    // ── Sub-view navigation ────────────────────────────────────────────────────
    // 0 = projects list   1 = video panel for an opened project
    property int subView:        0
    property var openedProject:  null

    // ── Header ─────────────────────────────────────────────────────────────────
    Item {
        id: header
        visible: root.subView === 0
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
            font.family:        theme.fontDisplay
            font.weight:        Font.Bold
            font.pixelSize:     34
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
            color:  newBtnHov ? theme.accentHover : theme.accent
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
                    font.family:      theme.fontBody
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
        visible: root.subView === 0
        anchors.top:        header.bottom
        anchors.topMargin:  4
        anchors.left:       header.left
        text: {
            var n = projectsManager ? projectsManager.projects.length : 0
            return n === 0 ? "No projects yet"
                           : n + " project" + (n === 1 ? "" : "s")
        }
        font.family:    theme.fontBody
        font.pixelSize: 11
        color:          theme.textMuted
    }

    // ── Empty state ────────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing:          14
        visible:          root.subView === 0 && (projectsManager ? projectsManager.projects.length === 0 : true)

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
            font.family:        theme.fontDisplay
            font.weight:        Font.Bold
            font.pixelSize:     28
            color:              theme.textPrimary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Create your first project to start tracking"
            font.family:    theme.fontBody
            font.pixelSize: 12
            color:          theme.textMuted
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width:  160; height: 36; radius: 8
            color:  emptyBtnHov ? theme.accentHover : theme.accent
            Behavior on color { ColorAnimation { duration: 150 } }

            property bool emptyBtnHov: false

            Text {
                anchors.centerIn: parent
                text:           "+ New Project"
                font.family:    theme.fontBody
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
        visible:             root.subView === 0 && (projectsManager ? projectsManager.projects.length > 0 : false)

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
                    height: 148
                    radius: 12
                    color:        cardHov ? theme.surface2 : theme.surface
                    border.color: cardHov
                                  ? Qt.rgba(66/255, 130/255, 255/255, 0.40)
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
                        anchors.topMargin:    4
                        anchors.bottomMargin: 4
                        width:  4
                        radius: 2
                        color:  card.accent
                    }

                    // ── Project initial circle ────────────────────────────────
                    Rectangle {
                        id: initCircle
                        anchors.left:       parent.left
                        anchors.leftMargin: 22
                        anchors.top:        parent.top
                        anchors.topMargin:  22
                        width: 40; height: 40; radius: 10
                        color: Qt.rgba(
                            Qt.color(card.accent).r,
                            Qt.color(card.accent).g,
                            Qt.color(card.accent).b,
                            0.16
                        )

                        Text {
                            anchors.centerIn: parent
                            text:           card.proj ? card.proj.name.charAt(0).toUpperCase() : ""
                            font.family:    theme.fontDisplay
                            font.weight:    Font.Bold
                            font.pixelSize: 20
                            color:          card.accent
                        }
                    }

                    // ── Project name ──────────────────────────────────────────
                    Text {
                        id: cardTitle
                        anchors.left:           initCircle.right
                        anchors.leftMargin:     12
                        anchors.right:          parent.right
                        anchors.rightMargin:    16
                        anchors.top:            initCircle.top
                        text:            card.proj ? card.proj.name : ""
                        font.family:     theme.fontDisplay
                        font.weight:     Font.Bold
                        font.pixelSize:  20
                        color:           theme.textPrimary
                        elide:           Text.ElideRight
                    }

                    // ── Video count chip (below name) ─────────────────────────
                    Row {
                        anchors.left:    cardTitle.left
                        anchors.top:     cardTitle.bottom
                        anchors.topMargin: 5
                        spacing: 6

                        Text {
                            text: {
                                if (!card.proj) return ""
                                var n = card.proj.videoCount
                                return n + " video" + (n === 1 ? "" : "s")
                            }
                            font.family:    theme.fontBody
                            font.pixelSize: 11
                            color:          theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // ── Bottom metadata ───────────────────────────────────────
                    Row {
                        anchors.left:         parent.left
                        anchors.leftMargin:   22
                        anchors.bottom:       parent.bottom
                        anchors.bottomMargin: 16
                        spacing: 7
                        visible: !card.cardHov

                        Text {
                            text:           card.proj ? card.proj.date : ""
                            font.family:    theme.fontBody
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
                            width: 54; height: 26; radius: 7
                            color: openHov ? theme.accent : theme.accentBg
                            border.color: openHov ? theme.accent : Qt.rgba(66/255, 130/255, 255/255, 0.35)
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            property bool openHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Open"
                                font.family:    theme.fontBody
                                font.pixelSize: 10
                                font.weight:    Font.Medium
                                color:          parent.openHov ? "white" : theme.accentLight
                                Behavior on color { ColorAnimation { duration: 110 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:  parent.openHov = true
                                onExited:   parent.openHov = false
                                onClicked: {
                                    if (card.proj) {
                                        root.openedProject = card.proj
                                        if (videosManager) {
                                            videosManager.setProject(card.proj.path)
                                            videosManager.setProjectName(card.proj.name)
                                        }
                                        root.subView = 1
                                    }
                                }
                            }
                        }

                        // Rename
                        Rectangle {
                            width: 62; height: 26; radius: 7
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
                                font.family:    theme.fontBody
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
                            width: 54; height: 26; radius: 7
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
                                font.family:    theme.fontBody
                                font.pixelSize: 9
                                font.weight:    Font.Medium
                                color:          parent.delHov ? theme.red : theme.textMuted
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

    // ── Video Panel (sub-view 1) ───────────────────────────────────────────────
    VideoPanel {
        anchors.fill: parent
        theme:        root.theme
        projectName:  root.openedProject ? root.openedProject.name : ""
        projectPath:  root.openedProject ? root.openedProject.path : ""
        visible:      root.subView === 1
        onBackClicked: root.subView = 0
    }

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
                font.family:      theme.fontDisplay
                font.weight:      Font.Normal
                font.pixelSize:   20
                color:            theme.textPrimary
            }

            Rectangle {
                width:  parent.width
                height: 36
                radius: 8
                color:  theme.surface
                border.color: nameField.activeFocus ? theme.accent : theme.border
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
                    font.family:      theme.fontBody
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
                        font.family:    theme.fontBody
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
                    color: createHov ? theme.accentHover : theme.accent
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool createHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Create"
                        font.family:    theme.fontBody
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
                font.family:      theme.fontDisplay
                font.weight:      Font.Normal
                font.pixelSize:   20
                color:            theme.textPrimary
            }

            Rectangle {
                width:  parent.width
                height: 36
                radius: 8
                color:  theme.surface
                border.color: renameField.activeFocus ? theme.accent : theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id:              renameField
                    anchors.fill:    parent
                    anchors.margins: 1
                    background:      Item {}
                    color:           theme.textPrimary
                    font.family:     theme.fontBody
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
                        font.family:    theme.fontBody
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
                    color: saveHov ? theme.accentHover : theme.accent
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool saveHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Save"
                        font.family:    theme.fontBody
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
                font.family:      theme.fontDisplay
                font.weight:      Font.Normal
                font.pixelSize:   20
                color:            theme.textPrimary
            }

            Text {
                width:          parent.width
                text:           "Delete \u201c" + deleteDialog.projectName + "\u201d? This cannot be undone."
                font.family:    theme.fontBody
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
                        font.family:    theme.fontBody
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
                    color: delConfirmHov ? Qt.darker(theme.red, 1.1) : theme.red
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool delConfirmHov: false

                    Text {
                        anchors.centerIn: parent
                        text:           "Delete"
                        font.family:    theme.fontBody
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
