import QtQuick 2.15

Rectangle {
    id: sessionSidebar
    property var app
    property var sessionsModel
    property var previewSessionModel

    width: app.sidebarWidthPx
    height: parent.height
    color: app.cPanel
    x: app.sessionSidebarOpen ? (parent.width - width) : parent.width
    y: 0
    opacity: app.sessionSidebarOpen ? 0.9 : 0
    visible: opacity > 0
    enabled: app.sessionSidebarOpen
    z: 10
    Behavior on x       { NumberAnimation { duration: app.animSidebar; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: app.animMedium; easing.type: Easing.OutCubic } }

    function focusSearch() {
        if (sessionSearchField) sessionSearchField.forceActiveFocus();
    }

    function clearSearch() {
        if (sessionSearchField) sessionSearchField.text = "";
        app.sessionSearchQuery = "";
    }

    function hasFilteredSessionMatches() {
        var q = app.sessionSearchQuery.toLowerCase().trim();
        if (q === "") return true;
        var liveLists = [sessionList, fallbackSessionList];
        for (var i = 0; i < liveLists.length; i++) {
            var list = liveLists[i];
            if (!list || !list.visible || !list.contentItem) continue;
            var kids = list.contentItem.children;
            for (var j = 0; j < kids.length; j++) {
                var child = kids[j];
                if (child && child.visible && child.height > 0) return true;
            }
        }
        return false;
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 40
        spacing: 10

        Text {
            text: qsTr("Select Session")
            font.pixelSize: app.titleSizePx
            font.family: app.fontPrimary
            color: app.cText
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 20
        }
        Rectangle {
            id: sessionSearchBox
            width: parent.width - app.s(40)
            height: app.searchBoxHeightPx
            radius: app.searchBoxRadiusPx
            anchors.horizontalCenter: parent.horizontalCenter
            color: app.cPanel
            opacity: 0.85
            visible: app.sidebarSearchEnabled
            border.width: sessionSearchField.activeFocus ? 2 : 0
            border.color: app.cAccent
            Behavior on border.width { NumberAnimation { duration: app.animFast } }
            Text {
                id: sessionSearchPlaceholder
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: app.s(14)
                text: qsTr("Search sessions")
                color: app.cText
                opacity: sessionSearchField.text.length === 0 ? 0.6 : 0.0
                font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
            }
            TextInput {
                id: sessionSearchField
                anchors.fill: parent
                anchors.leftMargin: app.s(14)
                anchors.rightMargin: app.s(14)
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                color: app.cText
                clip: true
                onTextChanged: app.sessionSearchQuery = text
                Keys.forwardTo: [app]
            }
            MouseArea {
                anchors.fill: parent
                onClicked: sessionSearchField.forceActiveFocus()
            }
        }

        Item {
            id: sessionListArea
            width: parent.width
            height: parent.height - (app.sidebarSearchEnabled ? 140 : 100)

            // Real sessions
            ListView {
                id: sessionList
                anchors.fill: parent
                clip: true
                model: app.previewEnabled ? previewSessionModel : sessionsModel
                spacing: 12
                boundsBehavior: Flickable.StopAtBounds
                visible: app.previewEnabled ? (previewSessionModel.count > 0) : (sessionsModel.count > 0)
                currentIndex: app.currentSessionIndex

                delegate: Rectangle {
                    width: parent.width - 40
                    property bool matches: {
                        var q = app.sessionSearchQuery.toLowerCase().trim();
                        if (q === "") return true;
                        return (model.name && model.name.toLowerCase().indexOf(q) >= 0);
                    }
                    height: matches ? app.sessionItemHeightPx : 0
                    radius: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: app.currentSessionIndex === index ? app.cAccent : app.cPanel
                    opacity: matches ? 0.9 : 0.0
                    visible: matches

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16; anchors.rightMargin: 16
                        spacing: 10
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: app.accentForName(model.name)
                            opacity: 0.85
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.name
                            font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                            color: app.cText
                            elide: Text.ElideRight
                            width: parent.width - app.s(90)
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: app.s(64); height: app.s(22); radius: height / 2
                            color: Qt.rgba(0, 0, 0, 0.2)
                            visible: (!app.previewEnabled && index === sessionsModel.lastIndex)
                                  || (app.previewEnabled && index === 0)
                            Text {
                                anchors.centerIn: parent
                                text: qsTr("RECENT")
                                font.pixelSize: app.sessionSizePx - 2
                                font.family: app.fontPrimary
                                color: app.cText
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            app.currentSessionIndex = index;
                            app.currentSessionName  = model.name;
                            app.sessionSidebarOpen = false;
                        }
                        onEntered: parent.opacity = 1.0
                        onExited:  parent.opacity = 0.9
                    }
                }
            }

            // Fallback when sessionsModel is empty
            ListView {
                anchors.fill: parent
                clip: true; visible: (!app.previewEnabled && sessionsModel.count === 0)
                id: fallbackSessionList
                model: ["Hyprland", "Plasma", "GNOME", "XFCE", "i3"]
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    width: parent.width - 40
                    property bool matches: {
                        var q = app.sessionSearchQuery.toLowerCase().trim();
                        if (q === "") return true;
                        return (modelData && modelData.toLowerCase().indexOf(q) >= 0);
                    }
                    height: matches ? app.sessionItemHeightPx : 0
                    radius: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: app.cPanel
                    opacity: matches ? 0.9 : 0.0
                    visible: matches
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16; anchors.rightMargin: 16
                        spacing: 10
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: app.accentForName(modelData)
                            opacity: 0.85
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData; font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                            color: app.cText; elide: Text.ElideRight
                            width: parent.width - app.s(90)
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: app.s(64); height: app.s(22); radius: height / 2
                            color: Qt.rgba(0, 0, 0, 0.2)
                            visible: (!app.previewEnabled && index === sessionsModel.lastIndex)
                                  || (app.previewEnabled && index === 0)
                            Text {
                                anchors.centerIn: parent
                                text: qsTr("RECENT")
                                font.pixelSize: app.sessionSizePx - 2
                                font.family: app.fontPrimary
                                color: app.cText
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            app.currentSessionName  = modelData;
                            app.currentSessionIndex = index;
                            app.sessionSidebarOpen = false;
                        }
                        onEntered: parent.opacity = 1.0
                        onExited:  parent.opacity = 0.9
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("No sessions found")
                font.pixelSize: app.sessionSizePx
                font.family: app.fontPrimary
                color: app.cText
                opacity: (app.sessionSearchQuery.trim() !== "" && !hasFilteredSessionMatches()) ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: app.animMedium } }
            }
        }
    }
}
