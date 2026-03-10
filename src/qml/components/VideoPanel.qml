// src/qml/components/VideoPanel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Item {
    id: root

    // ── Props ──────────────────────────────────────────────────────────────────
    property QtObject theme
    property string   projectName: ""
    property string   projectPath: ""

    signal backClicked()

    onProjectPathChanged: {
        if (videosManager && projectPath.length > 0) {
            videosManager.setProject(projectPath)
            videosManager.setProjectName(root.projectName)
        }
    }

    // Accent palette — same as ProjectsPage
    readonly property var accentPalette: [
        "#0071E3",
        "#30D158",
        "#FF9F0A",
        "#BF5AF2",
        "#FF375F",
    ]
    function accentFor(i) { return accentPalette[i % accentPalette.length] }

    // ── File dialog ────────────────────────────────────────────────────────────
    FileDialog {
        id:           addVideoDialog
        title:        "Select Video"
        nameFilters:  ["Video files (*.mp4 *.avi *.mov *.mkv *.webm)", "All files (*)"]
        onAccepted: {
            if (videosManager)
                videosManager.addVideo(selectedFile.toString())
        }
    }

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

        // Back button ── ← Projects
        Rectangle {
            id: backBtn
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            width:  backRow.implicitWidth + 20
            height: 30
            radius: 7
            color:        backHov ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
            border.color: backHov ? theme.border : "transparent"
            border.width: 1
            Behavior on color        { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            property bool backHov: false

            Row {
                id: backRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text:           "←"
                    font.pixelSize: 13
                    color:          theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:           "Projects"
                    font.family:    theme.fontBody
                    font.pixelSize: 11
                    color:          theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:  parent.backHov = true
                onExited:   parent.backHov = false
                onClicked:  root.backClicked()
            }
        }

        // Breadcrumb separator + project name
        Row {
            anchors.left:           backBtn.right
            anchors.leftMargin:     10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text:           "/"
                font.family:    theme.fontBody
                font.pixelSize: 14
                color:          Qt.rgba(theme.textMuted.r, theme.textMuted.g, theme.textMuted.b, 0.5)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text:               root.projectName
                font.family:        theme.fontDisplay
                font.weight:        Font.Normal
                font.pixelSize:     28
                font.letterSpacing: 0.5
                color:              theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Add Video button
        Rectangle {
            id: addBtn
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            width:  addBtnRow.implicitWidth + 24
            height: 34
            radius: 8
            color:  addBtnHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
            Behavior on color { ColorAnimation { duration: 150 } }

            property bool addBtnHov: false

            Row {
                id: addBtnRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text:           "+"
                    font.pixelSize: 17
                    font.weight:    Font.Light
                    color:          "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text:           "Add Video"
                    font.family:    theme.fontBody
                    font.pixelSize: 12
                    font.weight:    Font.Medium
                    color:          "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:  parent.addBtnHov = true
                onExited:   parent.addBtnHov = false
                onClicked:  addVideoDialog.open()
            }
        }
    }

    // ── Subtitle ───────────────────────────────────────────────────────────────
    Text {
        id: subtitle
        anchors.top:       header.bottom
        anchors.topMargin: 4
        anchors.left:      header.left
        text: {
            var n = videosManager ? videosManager.videos.length : 0
            return n === 0 ? "No videos yet"
                           : n + " video" + (n === 1 ? "" : "s")
        }
        font.family:    theme.fontBody
        font.pixelSize: 11
        color:          theme.textMuted
    }

    // ── Empty state ────────────────────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing:          14
        visible:          videosManager ? videosManager.videos.length === 0 : true

        // Film-strip icon placeholder
        Rectangle {
            width:  64; height: 64; radius: 16
            color:  theme.surface2
            border.color: theme.border
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter

            // Simple play-button shape via two rectangles
            Rectangle {
                anchors.centerIn: parent
                width: 20; height: 20; radius: 10
                color: "transparent"
                border.color: theme.textMuted
                border.width: 1.5

                Text {
                    anchors.centerIn:  parent
                    anchors.horizontalCenterOffset: 1
                    text:           "▶"
                    font.pixelSize: 10
                    color:          theme.textMuted
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:               "No videos yet"
            font.family:        theme.fontDisplay
            font.weight:        Font.Normal
            font.pixelSize:     24
            color:              theme.textPrimary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           "Add a video to start tracking"
            font.family:    theme.fontBody
            font.pixelSize: 12
            color:          theme.textMuted
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width:  150; height: 36; radius: 8
            color:  emptyAddHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
            Behavior on color { ColorAnimation { duration: 150 } }

            property bool emptyAddHov: false

            Text {
                anchors.centerIn: parent
                text:           "+ Add Video"
                font.family:    theme.fontBody
                font.pixelSize: 12
                font.weight:    Font.Medium
                color:          "white"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:  parent.emptyAddHov = true
                onExited:   parent.emptyAddHov = false
                onClicked:  addVideoDialog.open()
            }
        }
    }

    // ── Video cards grid ───────────────────────────────────────────────────────
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
        visible:             videosManager ? videosManager.videos.length > 0 : false

        Flow {
            id:      cardsFlow
            width:   scrollArea.availableWidth
            spacing: 16

            readonly property int  numCols: Math.max(1, Math.floor(width / 380))
            readonly property real cardW:   (width - spacing * (numCols - 1)) / numCols

            Repeater {
                model: videosManager ? videosManager.videos : []

                delegate: Rectangle {
                    id: card

                    width:  cardsFlow.cardW
                    height: 140
                    radius: 12

                    property bool   isActive: modelData ? modelData.isActive : false
                    property bool   cardHov:  hoverHandler.hovered
                    property var    vid:      modelData
                    property string accent:   root.accentFor(index)

                    color: isActive
                           ? Qt.rgba(0, 113/255, 227/255, 0.07)
                           : (cardHov ? theme.surface2 : theme.surface)

                    border.color: isActive
                                  ? Qt.rgba(0, 113/255, 227/255, 0.40)
                                  : (cardHov ? Qt.rgba(0, 113/255, 227/255, 0.22)
                                             : theme.border)
                    border.width: isActive ? 1 : 1

                    Behavior on color        { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }

                    // Left accent strip
                    Rectangle {
                        anchors.left:         parent.left
                        anchors.top:          parent.top
                        anchors.bottom:       parent.bottom
                        anchors.topMargin:    3
                        anchors.bottomMargin: 3
                        width:  3
                        radius: 2
                        color:  card.isActive ? "#0071E3" : card.accent
                    }

                    // Thumbnail area
                    Rectangle {
                        id: thumbRect
                        anchors.left:           parent.left
                        anchors.leftMargin:     20
                        anchors.verticalCenter: parent.verticalCenter
                        width:  130; height: 98
                        radius: 8
                        color:  theme.bg
                        border.color: theme.border
                        border.width: 1
                        clip:   true

                        Image {
                            anchors.fill: parent
                            source:       card.vid && card.vid.thumbnail ? ("file:///" + card.vid.thumbnail) : ""
                            fillMode:     Image.PreserveAspectCrop
                            visible:      card.vid ? card.vid.thumbnail !== "" : false
                        }

                        // Placeholder when no thumbnail
                        Text {
                            anchors.centerIn:              parent
                            anchors.horizontalCenterOffset: 1
                            text:           "▶"
                            font.pixelSize: 28
                            color:          theme.textMuted
                            visible:        !(card.vid ? card.vid.thumbnail !== "" : false)
                        }
                    }

                    // Video name
                    Text {
                        id:                  vidName
                        anchors.left:        thumbRect.right
                        anchors.leftMargin:  12
                        anchors.right:       parent.right
                        anchors.rightMargin: 14
                        anchors.top:         thumbRect.top
                        anchors.topMargin:   3
                        text:            card.vid ? card.vid.name : ""
                        font.family:     theme.fontDisplay
                        font.weight:     Font.Normal
                        font.pixelSize:  17
                        color:           theme.textPrimary
                        elide:           Text.ElideRight
                    }

                    // Duration
                    Text {
                        anchors.left:       thumbRect.right
                        anchors.leftMargin: 12
                        anchors.top:        vidName.bottom
                        anchors.topMargin:  3
                        text:           card.vid ? card.vid.duration : ""
                        font.family:    theme.fontBody
                        font.pixelSize: 11
                        color:          theme.textMuted
                    }

                    // Active badge
                    Rectangle {
                        visible:            card.isActive
                        anchors.left:       thumbRect.right
                        anchors.leftMargin: 12
                        anchors.bottom:     thumbRect.bottom
                        width:  activeLbl.implicitWidth + 14
                        height: 16
                        radius: 8
                        color:  Qt.rgba(0, 113/255, 227/255, 0.16)

                        Text {
                            id:              activeLbl
                            anchors.centerIn: parent
                            text:            "● Active"
                            font.family:     theme.fontBody
                            font.pixelSize:  9
                            font.weight:     Font.Medium
                            color:           "#0071E3"
                        }
                    }

                    // ── Hover action buttons ───────────────────────────────────
                    Row {
                        anchors.right:        parent.right
                        anchors.rightMargin:  12
                        anchors.bottom:       parent.bottom
                        anchors.bottomMargin: 10
                        spacing:              5
                        opacity:  card.cardHov ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        // Set Active (hidden if already active)
                        Rectangle {
                            visible:      !card.isActive
                            width:  72; height: 22; radius: 6
                            color:        setActHov ? "#0071E3"
                                                    : Qt.rgba(0, 113/255, 227/255, 0.10)
                            border.color: setActHov ? "#0071E3"
                                                    : Qt.rgba(0, 113/255, 227/255, 0.28)
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            property bool setActHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Set Active"
                                font.family:    theme.fontBody
                                font.pixelSize: 8
                                font.weight:    Font.Medium
                                color:          parent.setActHov ? "white" : "#0071E3"
                                Behavior on color { ColorAnimation { duration: 110 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:  parent.setActHov = true
                                onExited:   parent.setActHov = false
                                onClicked: {
                                    if (videosManager && card.vid)
                                        videosManager.setActive(card.vid.name)
                                }
                            }
                        }

                        // Rename
                        Rectangle {
                            width: 58; height: 22; radius: 6
                            color:        renHov ? Qt.rgba(1, 1, 1, 0.08)
                                                 : Qt.rgba(1, 1, 1, 0.04)
                            border.color: theme.border
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 110 } }

                            property bool renHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Rename"
                                font.family:    theme.fontBody
                                font.pixelSize: 8
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
                                    if (card.vid) {
                                        vidRenameDialog.oldName = card.vid.name
                                        vidRenameField.text     = card.vid.name
                                        vidRenameDialog.open()
                                    }
                                }
                            }
                        }

                        // Delete
                        Rectangle {
                            width: 50; height: 22; radius: 6
                            color:        delHov ? Qt.rgba(1, 0.22, 0.37, 0.15)
                                                 : Qt.rgba(1, 1, 1, 0.04)
                            border.color: delHov ? Qt.rgba(1, 0.22, 0.37, 0.45) : theme.border
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            property bool delHov: false

                            Text {
                                anchors.centerIn: parent
                                text:           "Delete"
                                font.family:    theme.fontBody
                                font.pixelSize: 8
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
                                    if (card.vid) {
                                        vidDeleteDialog.videoName = card.vid.name
                                        vidDeleteDialog.open()
                                    }
                                }
                            }
                        }
                    }
                } // delegate Rectangle
            } // Repeater
        } // Flow
    } // ScrollView

    // ══════════════════════════════════════════════════════════════════════════
    // Rename Video dialog
    // ══════════════════════════════════════════════════════════════════════════
    Popup {
        id:      vidRenameDialog
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
                text:             "Rename Video"
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
                border.color: vidRenameField.activeFocus ? "#0071E3" : theme.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id:              vidRenameField
                    anchors.fill:    parent
                    anchors.margins: 1
                    background:      Item {}
                    color:           theme.textPrimary
                    font.family:     theme.fontBody
                    font.pixelSize:  12
                    leftPadding:     12
                    Keys.onReturnPressed: vidRenameDialog.doRename()
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color:        vrCancelHov ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                    border.color: theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool vrCancelHov: false

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
                        onEntered:  parent.vrCancelHov = true
                        onExited:   parent.vrCancelHov = false
                        onClicked:  vidRenameDialog.close()
                    }
                }

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color: vrSaveHov ? Qt.darker("#0071E3", 1.12) : "#0071E3"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool vrSaveHov: false

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
                        onEntered:  parent.vrSaveHov = true
                        onExited:   parent.vrSaveHov = false
                        onClicked:  vidRenameDialog.doRename()
                    }
                }
            }
        }

        function doRename() {
            var n = vidRenameField.text.trim()
            if (n.length > 0 && videosManager)
                videosManager.renameVideo(oldName, n)
            close()
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Delete Video dialog
    // ══════════════════════════════════════════════════════════════════════════
    Popup {
        id:      vidDeleteDialog
        anchors.centerIn: Overlay.overlay
        width:   320
        height:  162
        modal:   true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string videoName: ""

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
                text:             "Delete Video"
                font.family:      theme.fontDisplay
                font.weight:      Font.Normal
                font.pixelSize:   20
                color:            theme.textPrimary
            }

            Text {
                width:          parent.width
                text:           "Delete \u201c" + vidDeleteDialog.videoName + "\u201d? This cannot be undone."
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
                    color:        vdCancelHov ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                    border.color: theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool vdCancelHov: false

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
                        onEntered:  parent.vdCancelHov = true
                        onExited:   parent.vdCancelHov = false
                        onClicked:  vidDeleteDialog.close()
                    }
                }

                Rectangle {
                    width: 72; height: 32; radius: 7
                    color: vdConfirmHov ? Qt.darker("#FF375F", 1.1) : "#FF375F"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    property bool vdConfirmHov: false

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
                        onEntered:  parent.vdConfirmHov = true
                        onExited:   parent.vdConfirmHov = false
                        onClicked: {
                            if (videosManager)
                                videosManager.deleteVideo(vidDeleteDialog.videoName)
                            vidDeleteDialog.close()
                        }
                    }
                }
            }
        }
    }
}
