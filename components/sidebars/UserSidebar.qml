import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: userSidebar
    property var app
    property var usersModel
    property var previewUserModel

    width: app.sidebarWidthPx
    height: parent.height
    color: app.cPanel
    x: app.userSidebarOpen ? 0 : -width
    y: 0
    opacity: app.userSidebarOpen ? 0.9 : 0
    visible: opacity > 0
    enabled: app.userSidebarOpen
    z: 10
    Behavior on x       { NumberAnimation { duration: app.animSidebar; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: app.animMedium; easing.type: Easing.OutCubic } }

    function focusSearch() {
        if (userSearchField) userSearchField.forceActiveFocus();
    }

    function clearSearch() {
        if (userSearchField) userSearchField.text = "";
        app.userSearchQuery = "";
    }

    function hasFilteredUserMatches() {
        var q = app.userSearchQuery.toLowerCase().trim();
        if (q === "") return true;
        var kids = userListView.contentItem.children;
        for (var i = 0; i < kids.length; i++) {
            var child = kids[i];
            if (child && child.visible && child.height > 0) return true;
        }
        return false;
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 40
        spacing: 10

        Text {
            text: qsTr("Select User")
            font.pixelSize: app.titleSizePx
            font.family: app.fontPrimary
            color: app.cText
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 20
        }
        Rectangle {
            id: userSearchBox
            width: parent.width - app.s(40)
            height: app.searchBoxHeightPx
            radius: app.searchBoxRadiusPx
            anchors.horizontalCenter: parent.horizontalCenter
            color: app.cPanel
            opacity: 0.85
            visible: app.sidebarSearchEnabled
            border.width: userSearchField.activeFocus ? 2 : 0
            border.color: app.cAccent
            Behavior on border.width { NumberAnimation { duration: app.animFast } }
            Text {
                id: userSearchPlaceholder
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: app.s(14)
                text: qsTr("Search users")
                color: app.cText
                opacity: userSearchField.text.length === 0 ? 0.6 : 0.0
                font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
            }
            TextInput {
                id: userSearchField
                anchors.fill: parent
                anchors.leftMargin: app.s(14)
                anchors.rightMargin: app.s(14)
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                color: app.cText
                clip: true
                onTextChanged: app.userSearchQuery = text
                Keys.forwardTo: [app]
            }
            MouseArea {
                anchors.fill: parent
                onClicked: userSearchField.forceActiveFocus()
            }
        }

        Item {
            id: userListArea
            width: parent.width
            height: parent.height - (app.sidebarSearchEnabled ? 140 : 100)

            ListView {
                id: userListView
                anchors.fill: parent
                clip: true
                model: app.previewEnabled ? previewUserModel : usersModel
                spacing: 12
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: {
                    if (app.previewEnabled) return 0;
                    for (var i = 0; i < usersModel.count; i++) {
                        if (app.getUserLoginName(i) === app.currentUsername) return i;
                    }
                    return 0;
                }

                delegate: Rectangle {
                    width: parent.width - 40
                    property string displayName: model.realName || model.name
                    property bool matches: {
                        var q = app.userSearchQuery.toLowerCase().trim();
                        if (q === "") return true;
                        return (model.name && model.name.toLowerCase().indexOf(q) >= 0)
                            || (displayName && displayName.toLowerCase().indexOf(q) >= 0);
                    }
                    height: matches ? app.userItemHeightPx : 0
                    radius: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: userListView.currentIndex === index ? app.cAccent : app.cPanel
                    opacity: matches ? 0.9 : 0.0
                    visible: matches
                    Behavior on scale { NumberAnimation { duration: app.animFast } }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 10

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 15

                            Rectangle {
                                width: app.s(60); height: app.s(60); radius: width / 2
                                color: app.cPanel
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: userAvatar
                                    property int avatarAttempt: 0
                                    property string avatarName: model.name
                                    anchors.fill: parent
                                    anchors.margins: app.s(3)
                                    source: app.getProfilePicture(model.name, avatarAttempt)
                                    fillMode: Image.PreserveAspectCrop
                                    onAvatarNameChanged: avatarAttempt = 0
                                    onStatusChanged: {
                                        if (status === Image.Error && avatarAttempt < app.avatarBasePaths.length - 1) {
                                            avatarAttempt += 1;
                                        }
                                    }
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: userAvatar.width; height: userAvatar.height
                                            radius: userAvatar.width / 2
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: userAvatar.status !== Image.Ready
                                        color: app.accentForName(model.name); radius: width / 2
                                        Text {
                                            anchors.centerIn: parent
                                            text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                                            font.pixelSize: app.avatarInitialSizePx; font.family: app.fontPrimary
                                            font.weight: Font.Bold; color: app.cText
                                        }
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text {
                                    text: model.name
                                    font.pixelSize: app.usernameSizePx; font.family: app.fontPrimary
                                    font.weight: Font.Medium; color: app.cText
                                }
                                Text {
                                    text: displayName
                                    font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                                    color: app.cText
                                }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: app.s(64); height: app.s(22); radius: height / 2
                            color: Qt.rgba(0, 0, 0, 0.2)
                            visible: (!app.previewEnabled && index === usersModel.lastIndex)
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
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            app.currentUsername    = model.name;
                            app.currentDisplayName = model.realName || model.name;
                            app.loginFailed   = false;
                            app.loginErrorMsg = "";
                            app.requestPasswordClear();
                            app.userSidebarOpen = false;
                            app.requestPasswordFocus();
                        }
                        onEntered: {
                            userListView.currentIndex = index;
                            parent.opacity = 1.0;
                            parent.scale   = 1.02;
                        }
                        onExited: { parent.opacity = 0.9; parent.scale = 1.0 }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("No users found")
                font.pixelSize: app.sessionSizePx
                font.family: app.fontPrimary
                color: app.cText
                opacity: (app.userSearchQuery.trim() !== "" && !hasFilteredUserMatches()) ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: app.animMedium } }
            }
        }
    }
}
