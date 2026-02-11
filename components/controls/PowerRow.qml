import QtQuick 2.15

Row {
    id: powerRow
    property var app

    function triggerPowerAction(action) {
        if (action === "poweroff" && sddm.powerOff) {
            sddm.powerOff();
            return;
        }
        if (action === "reboot" && sddm.reboot) {
            sddm.reboot();
            return;
        }
        if (action === "suspend" && sddm.suspend) {
            sddm.suspend();
        }
    }

    anchors.bottom: parent.bottom; anchors.right: parent.right
    anchors.margins: app.outerMarginPx; spacing: app.s(20)

    Rectangle {
        id: oskButton
        visible: app.oskEnabled
        width: app.s(48); height: app.s(48); radius: width / 2
        color: app.cPanel; opacity: 0.8
        Text { anchors.centerIn: parent; text: "⌨"; font.pixelSize: app.powerIconSizePx; color: app.cText }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onClicked: app.oskOpen = !app.oskOpen
            onEntered: parent.opacity = 1.0
            onExited:  parent.opacity = 0.8
        }
    }

    Repeater {
        model: [
            { icon: "⏻", action: "poweroff" },
            { icon: "⟳", action: "reboot" },
            { icon: "⏾", action: "suspend" }
        ]
        delegate: Rectangle {
            width: app.s(48); height: app.s(48); radius: width / 2; color: app.cPanel; opacity: 0.8
            Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: app.powerIconSizePx; color: app.cText }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onClicked: powerRow.triggerPowerAction(modelData.action)
                onEntered: parent.opacity = 1.0
                onExited:  parent.opacity = 0.8
            }
        }
    }
}
