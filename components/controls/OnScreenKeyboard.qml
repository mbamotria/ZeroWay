import QtQuick 2.15

Rectangle {
    id: oskPanel
    property var app
    property var targetInput

    width: Math.min(app.oskWidth, parent.width - app.s(40))
    height: app.oskHeight
    radius: app.s(16)
    color: app.cPanel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: app.outerMarginPx
    z: 20
    y: app.oskOpen ? (parent.height - height - app.outerMarginPx) : (parent.height + app.s(30))
    opacity: app.oskOpen ? 0.96 : 0.0
    visible: app.oskEnabled && (opacity > 0.01 || app.oskOpen)
    Behavior on y { NumberAnimation { duration: app.animSidebar + 80; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { duration: app.animMedium } }

    function insertText(text) {
        if (!targetInput || !text) return;
        var out = app.oskLabelFor(text);
        if (app.oskShift) app.oskShift = false;
        targetInput.insert(targetInput.cursorPosition, out);
        targetInput.forceActiveFocus();
    }

    function backspace() {
        if (!targetInput) return;
        if (targetInput.selectionStart !== targetInput.selectionEnd) {
            targetInput.remove(targetInput.selectionStart, targetInput.selectionEnd);
            return;
        }
        var pos = targetInput.cursorPosition;
        if (pos > 0) targetInput.remove(pos - 1, pos);
    }

    function clearAll() {
        if (!targetInput) return;
        targetInput.text = "";
        targetInput.forceActiveFocus();
    }

    Column {
        anchors.fill: parent
        anchors.margins: app.s(16)
        spacing: app.s(10)

        Item {
            width: parent.width
            height: app.s(30)
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Keyboard")
                font.pixelSize: app.sessionSizePx
                font.family: app.fontPrimary
                color: app.cText
                opacity: 0.8
            }
            Rectangle {
                width: app.s(28); height: app.s(28); radius: width / 2
                color: Qt.rgba(0, 0, 0, 0.2)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: app.sessionSizePx; color: app.cText }
                MouseArea {
                    anchors.fill: parent
                    onClicked: app.oskOpen = false
                }
            }
        }

        Repeater {
            model: app.oskLayout
            delegate: Item {
                width: parent.width
                height: app.s(42)
                Row {
                    anchors.centerIn: parent
                    spacing: app.s(8)
                    Repeater {
                        model: modelData
                        delegate: Rectangle {
                            width: app.s(48); height: app.s(42); radius: app.s(8)
                            color: app.cBg
                            opacity: 0.95
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: app.oskLabelFor(modelData)
                                font.pixelSize: app.sessionSizePx
                                font.family: app.fontPrimary
                                color: app.cText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: insertText(modelData)
                                onPressed: parent.opacity = 1.0
                                onReleased: parent.opacity = 0.95
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: app.s(42)
            Row {
                anchors.centerIn: parent
                spacing: app.s(8)
                Repeater {
                    model: app.oskBottom
                    delegate: Rectangle {
                        height: app.s(42)
                        radius: app.s(8)
                        color: modelData === "shift" && app.oskShift ? app.cAccent : app.cBg
                        opacity: 0.95
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)
                        width: {
                            if (modelData === "space") return app.s(300);
                            if (modelData === "enter") return app.s(110);
                            if (modelData === "backspace") return app.s(130);
                            if (modelData === "clear") return app.s(90);
                            return app.s(80);
                        }
                        Text {
                            anchors.centerIn: parent
                            text: modelData === "space" ? qsTr("Space")
                                 : modelData === "backspace" ? qsTr("Back")
                                 : modelData === "shift" ? (app.oskShift ? qsTr("Shift") : qsTr("Shift"))
                                 : modelData === "clear" ? qsTr("Clear")
                                 : qsTr("Enter")
                            font.pixelSize: app.sessionSizePx
                            font.family: app.fontPrimary
                            color: app.cText
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData === "space") insertText(" ");
                                else if (modelData === "backspace") backspace();
                                else if (modelData === "clear") clearAll();
                                else if (modelData === "shift") app.oskShift = !app.oskShift;
                                else if (modelData === "enter") app.performLogin(targetInput ? targetInput.text : "");
                            }
                            onPressed: parent.opacity = 1.0
                            onReleased: parent.opacity = 0.95
                        }
                    }
                }
            }
        }
    }
}
