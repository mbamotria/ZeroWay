import QtQuick 2.15

Item {
    id: clockBlock
    property var app

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: app.outerMarginPx
        spacing: 6

        Text {
            id: timeText
            text: Qt.formatTime(new Date(), "HH:mm")
            font.pixelSize: app.timeSizePx
            font.family: app.fontDisplay
            color: app.cText
        }
        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            font.pixelSize: app.dateSizePx
            font.family: app.fontPrimary
            color: app.cText
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), "HH:mm");
            dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d");
        }
    }
}
