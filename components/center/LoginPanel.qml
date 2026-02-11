import QtQuick 2.15
import QtGraphicalEffects 1.15

Column {
    id: loginPanel
    property var app
    property alias passField: passField
    property alias usernameButton: usernameButton
    property alias sessionSelector: sessionSelector
    property alias loginIcon: loginIcon

    function pulse() { loginPulse.restart(); }
    function shake() { shakeAnim.start(); }
    function clearPassword() { passField.text = ""; }
    function focusPassword() { passField.forceActiveFocus(); }

    anchors.centerIn: parent
    spacing: app.centerSpacingPx

    // Profile picture
    Rectangle {
        id: profileContainer
        width: app.s(120); height: app.s(120); radius: width / 2
        color: "transparent"
        anchors.horizontalCenter: parent.horizontalCenter

        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                app.openUserSidebar();
            }
            onEntered: { profileRing.scale = 1.05; profileRing.opacity = 1.0; profileRing.border.color = app.cAccent }
            onExited:  { profileRing.scale = 1.0;  profileRing.opacity = 0.7; profileRing.border.color = app.cAccent }
        }

        Image {
            id: profilePicture
            property int avatarAttempt: 0
            anchors.fill: parent; anchors.margins: 4
            source: app.getProfilePicture(app.currentUsername, avatarAttempt)
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: {
                if (status === Image.Error && avatarAttempt < app.avatarBasePaths.length - 1) {
                    avatarAttempt += 1;
                }
            }
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: profilePicture.width; height: profilePicture.height
                    radius: profilePicture.width / 2
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: profilePicture.status !== Image.Ready
                color: app.accentForName(app.currentUsername); radius: width / 2
                Text {
                    anchors.centerIn: parent
                    text: app.currentDisplayName ? app.currentDisplayName.charAt(0).toUpperCase() : "?"
                    font.pixelSize: app.profileInitialSizePx; font.family: app.fontPrimary
                    font.weight: Font.Bold; color: app.cAccent
                }
            }
        }
        Connections {
            target: app
            function onCurrentUsernameChanged() {
                profilePicture.avatarAttempt = 0;
            }
        }

        Rectangle {
            id: profileRing
            anchors.fill: parent; color: "transparent"; radius: width / 2
            border.width: 3; border.color: app.cAccent; opacity: 0.7
            Behavior on scale        { NumberAnimation { duration: app.animMedium; easing.type: Easing.OutCubic } }
            Behavior on opacity      { NumberAnimation { duration: app.animMedium } }
            Behavior on border.color { ColorAnimation  { duration: app.animMedium } }
        }

        Rectangle {
            width: app.s(28); height: app.s(28); radius: width / 2; color: app.cAccent
            anchors.bottom: parent.bottom; anchors.right: parent.right
            Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: app.refreshIconSizePx; color: app.cText; rotation: 90 }
        }
    }

    // Username button
    Rectangle {
        id: usernameButton
        width: usernameText.contentWidth + app.s(60)
        height: app.s(36); radius: height / 2
        color: app.userSidebarOpen ? app.cAccent : app.cPanel
        opacity: 0.85
        border.width: (activeFocus || app.usernameHover) ? 2 : 0
        border.color: app.cAccent
        anchors.horizontalCenter: parent.horizontalCenter
        Behavior on color   { ColorAnimation  { duration: app.animMedium } }
        Behavior on opacity { NumberAnimation  { duration: app.animMedium } }
        Behavior on width   { NumberAnimation  { duration: app.animFast } }
        Behavior on border.width { NumberAnimation { duration: app.animFast } }
        activeFocusOnTab: true
        Keys.forwardTo: [app]

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 24
            height: parent.height + 14
            radius: height / 2
            color: app.cAccent
            opacity: (app.spotlightEnabled && (parent.activeFocus || app.usernameHover)) ? 0.18 : 0.0
            z: -1
            Behavior on opacity { NumberAnimation { duration: app.animMedium } }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                id: usernameText
                text: app.currentDisplayName !== "" ? app.currentDisplayName : "…"
                font.pixelSize: app.usernameSizePx; font.family: app.fontPrimary
                font.weight: Font.Medium; color: app.cText
            }
        }

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                app.openUserSidebar();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: app.openUserSidebar()
            onEntered: { app.usernameHover = true; usernameButton.opacity = 1.0; usernameButton.scale = 1.03 }
            onExited:  { app.usernameHover = false; usernameButton.opacity = 0.85; usernameButton.scale = 1.0 }
        }
    }

    // Password row
    Rectangle {
        id: loginBox
        width: app.loginBoxWidthPx; height: app.loginBoxHeightPx; radius: height / 2
        color: app.cPanel; opacity: 0.68
        anchors.horizontalCenter: parent.horizontalCenter
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: app.passwordHover = true
            onExited:  app.passwordHover = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 26
            height: parent.height + 16
            radius: height / 2
            color: app.cAccent
            opacity: (app.spotlightEnabled && (passField.activeFocus || app.passwordHover)) ? 0.18 : 0.0
            z: -1
            Behavior on opacity { NumberAnimation { duration: app.animMedium } }
        }

        SequentialAnimation {
            id: shakeAnim
            PropertyAnimation { target: loginBox; property: "x"; to: loginBox.x - 10; duration: 50 }
            PropertyAnimation { target: loginBox; property: "x"; to: loginBox.x + 10; duration: 50 }
            PropertyAnimation { target: loginBox; property: "x"; to: loginBox.x - 6;  duration: 50 }
            PropertyAnimation { target: loginBox; property: "x"; to: loginBox.x + 6;  duration: 50 }
            PropertyAnimation { target: loginBox; property: "x"; to: loginBox.x;      duration: 50 }
        }
        SequentialAnimation {
            id: loginPulse
            PropertyAnimation { target: loginBox; property: "scale"; to: 1.02; duration: 80 }
            PropertyAnimation { target: loginBox; property: "scale"; to: 1.0; duration: 120 }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            anchors.topMargin: 10;  anchors.bottomMargin: 10
            spacing: 10

            Rectangle {
                id: passwordContainer
                width: parent.width - (loginIcon.width + 10); height: parent.height
                radius: height / 2; color: "transparent"
                border.width: 0
                clip: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 22
                    text: qsTr("Password")
                    color: app.loginFailed ? app.cError : app.cText
                    font.pixelSize: app.passwordSizePx; font.family: app.fontPrimary
                    visible: passField.text.length === 0
                    Behavior on color { ColorAnimation { duration: app.animMedium } }
                }

                TextInput {
                    id: passField
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 22; anchors.rightMargin: 14
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: app.passwordSizePx; font.family: app.fontPrimary
                    color: app.cText
                    echoMode: TextInput.Password
                    selectByMouse: true; cursorVisible: true; focus: true
                    clip: true
                    Keys.forwardTo: [app]

                    onTextChanged: {
                        if (app.loginFailed) {
                            app.loginFailed   = false;
                            app.loginErrorMsg = "";
                        }
                    }
                    onAccepted:           app.performLogin(passField.text)
                    Keys.onReturnPressed: app.performLogin(passField.text)
                    Keys.onEnterPressed:  app.performLogin(passField.text)
                }

            }

            Rectangle {
                id: loginIcon
                width: app.s(42); height: app.s(42); radius: width / 2; color: app.cAccent
                anchors.verticalCenter: parent.verticalCenter
                Behavior on scale { NumberAnimation { duration: app.animFast } }
                activeFocusOnTab: true
                Keys.forwardTo: [app]
                border.width: (activeFocus || app.loginHover) ? 2 : 0
                border.color: app.cText
                Behavior on border.width { NumberAnimation { duration: app.animFast } }
                Text { anchors.centerIn: parent; text: "→"; font.pixelSize: app.loginIconSizePx; color: app.cText }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        app.performLogin(passField.text);
                        event.accepted = true;
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: app.performLogin(passField.text)
                    onEntered: { app.loginHover = true; loginIcon.scale = 1.12 }
                    onExited:  { app.loginHover = false; loginIcon.scale = 1.0 }
                }
            }
        }
    }

    // Error label
    Text {
        id: errorText
        anchors.horizontalCenter: parent.horizontalCenter
        text: app.loginErrorMsg
        color: app.cError
        font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
        opacity: app.loginFailed ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: app.animMedium } }
    }

    // Session selector pill
    Rectangle {
        id: sessionSelector
        width: sessionText.contentWidth + app.s(60)
        height: app.s(36); radius: height / 2
        color: app.sessionSidebarOpen ? app.cAccent : app.cPanel
        opacity: 0.85
        border.width: (activeFocus || app.sessionHover) ? 2 : 0
        border.color: app.cAccent
        anchors.horizontalCenter: parent.horizontalCenter
        Behavior on color   { ColorAnimation  { duration: app.animMedium } }
        Behavior on opacity { NumberAnimation  { duration: app.animMedium } }
        Behavior on width   { NumberAnimation  { duration: app.animFast } }
        Behavior on border.width { NumberAnimation { duration: app.animFast } }
        activeFocusOnTab: true
        Keys.forwardTo: [app]

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 24
            height: parent.height + 14
            radius: height / 2
            color: app.cAccent
            opacity: (app.spotlightEnabled && (parent.activeFocus || app.sessionHover)) ? 0.18 : 0.0
            z: -1
            Behavior on opacity { NumberAnimation { duration: app.animMedium } }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: sessionText
                anchors.verticalCenter: parent.verticalCenter
                text: app.currentSessionName !== "" ? app.currentSessionName : "—"
                font.pixelSize: app.sessionSizePx; font.family: app.fontPrimary
                color: app.cText; elide: Text.ElideRight
            }
        }

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                app.openSessionSidebar();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onClicked: app.openSessionSidebar()
            onEntered: { app.sessionHover = true; parent.opacity = 1.0 }
            onExited:  { app.sessionHover = false; parent.opacity = 0.85 }
        }
    }
}
