import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 1280
    height: 800
    minimumWidth: 1280
    minimumHeight: 800
    title: "Trocker"
    visible: true

    color: "#1a1d23"

    Text {
        anchors.centerIn: parent
        text: "TROCKER"
        color: "#f5a623"
        font.family: "Rajdhani"
        font.pixelSize: 48
        font.letterSpacing: 4
    }
}
