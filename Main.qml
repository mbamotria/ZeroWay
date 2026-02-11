import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0
import "components/background" as Bg
import "components/clock" as Clock
import "components/sidebars" as Sidebars
import "components/center" as Center
import "components/controls" as Controls

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    focus: true

    // ─────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────
    property string currentUsername: ""
    property string currentDisplayName: ""
    property int    currentSessionIndex: 0
    property string currentSessionName:  ""
    property bool   loginFailed: false
    property string loginErrorMsg: ""
    property bool   userSidebarOpen: false
    property bool   sessionSidebarOpen: false
    // caps lock hint removed (system doesn't expose reliable state)
    property bool   usernameHover: false
    property bool   sessionHover: false
    property bool   passwordHover: false
    property bool   loginHover: false
    property int    focusIndex: 0
    property var    focusTargets: []
    property string userSearchQuery: ""
    property string sessionSearchQuery: ""
    property bool   oskOpen: false
    property bool   oskShift: false

    // ─────────────────────────────────────────────────────────────
    // Config helpers + theme knobs (read from theme.conf)
    // ─────────────────────────────────────────────────────────────
    function cfgString(key, def) {
        var v = config.stringValue(key);
        return (v && v !== "") ? v : def;
    }
    function cfgNumber(key, def) {
        var v = config.stringValue(key);
        return (v && v !== "") ? Number(v) : def;
    }
    function cfgList(key, defCsv) {
        var raw = cfgString(key, defCsv);
        var out = [];
        var parts = raw.split(",");
        for (var i = 0; i < parts.length; i++) {
            var v = parts[i] ? parts[i].trim() : "";
            if (v !== "") out.push(v);
        }
        return out;
    }

    function firstNonEmpty(values, fallback) {
        for (var i = 0; i < values.length; i++) {
            var v = values[i];
            if (v !== undefined && v !== null && v !== "") return String(v);
        }
        return fallback || "";
    }

    property color  cText:   cfgString("color_text", "#C2C2C5")
    property color  cBg:     cfgString("color_bg", "#0F0E0E")
    property color  cPanel:  cfgString("color_panel", "#061E29")
    property color  cAccent: cfgString("color_accent", "#1D546D")
    property color  cError:  cfgString("color_error", "#ff6b6b")
    property var    accentPalette: cfgString("accent_palette", "#1D546D,#2B7A78,#3A506B,#5C4B51,#6C5B7B,#355C7D").split(",")

    property string fontPrimary: cfgString("font_primary", "SF Pro Display")
    property string fontDisplay: cfgString("font_display", "Orbitron")

    property int timeSize:     cfgNumber("time_size", 88)
    property int dateSize:     cfgNumber("date_size", 26)
    property int titleSize:    cfgNumber("title_size", 22)
    property int usernameSize: cfgNumber("username_size", 18)
    property int passwordSize: cfgNumber("password_size", 17)
    property int sessionSize:  cfgNumber("session_size", 14)
    property int profileInitialSize: cfgNumber("profile_initial_size", 48)
    property int avatarInitialSize:  cfgNumber("avatar_initial_size", 24)
    property int refreshIconSize:    cfgNumber("refresh_icon_size", 14)
    property int powerIconSize:      cfgNumber("power_icon_size", 22)
    property int loginIconSize:      cfgNumber("login_icon_size", 24)

    property int outerMargin:       cfgNumber("outer_margin", 60)
    property int centerSpacing:     cfgNumber("center_spacing", 24)
    property int sidebarWidth:      cfgNumber("sidebar_width", 400)
    property int userItemHeight:    cfgNumber("user_item_height", 80)
    property int sessionItemHeight: cfgNumber("session_item_height", 64)
    property int loginBoxWidth:     cfgNumber("login_box_width", 380)
    property int loginBoxHeight:    cfgNumber("login_box_height", 62)

    property string backgroundPath: cfgString("background", "WhiteAbstract.jpg")
    property url backgroundSource: Qt.resolvedUrl(backgroundPath)
    property real blurRadius:       cfgNumber("blur_radius", 2)
    property real overlayOpacity:   cfgNumber("overlay_opacity", 0.35)
    property bool ambientEnabled:   cfgNumber("ambient_enabled", 1) === 1
    property real ambientOpacity:   cfgNumber("ambient_opacity", 0.18)
    property int  ambientSpeed:     cfgNumber("ambient_speed", 28000)
    property bool shaderEnabled:    cfgNumber("shader_enabled", 1) === 1
    property real shaderStrength:   cfgNumber("shader_strength", 0.12)
    property int  shaderSpeed:      cfgNumber("shader_speed", 36000)
    property color shaderTint:      cfgString("shader_tint", "#1E4254")
    property bool spotlightEnabled: cfgNumber("spotlight_enabled", 0) === 1
    property bool sidebarSearchEnabled: cfgNumber("sidebar_search_enabled", 0) === 1
    property bool oskEnabled:       cfgNumber("osk_enabled", 1) === 1
    property bool oskDefaultOpen:   cfgNumber("osk_default_open", 0) === 1
    property bool debugLogging:     cfgNumber("debug_logging", 0) === 1
    property var  avatarBasePaths:  cfgList("avatar_base_paths", "/var/lib/AccountsService/icons,/usr/share/sddm/faces,/usr/local/share/sddm/faces")
    property int  oskWidth:         s(cfgNumber("osk_width", 820))
    property int  oskHeight:        s(cfgNumber("osk_height", 320))
    property var  oskLayout: [
        ["`","1","2","3","4","5","6","7","8","9","0","-","="],
        ["q","w","e","r","t","y","u","i","o","p","[","]","\\"],
        ["a","s","d","f","g","h","j","k","l",";","'"],
        ["z","x","c","v","b","n","m",",",".","/"]
    ]
    property var oskBottom: ["shift","space","backspace","enter","clear"]
    // session tags removed
    property bool previewEnabled:   cfgNumber("preview_enabled", 0) === 1
    property string previewUser:    cfgString("preview_user", "jane")
    property string previewDisplay: cfgString("preview_display", "Jane Doe")
    property string previewSession: cfgString("preview_session", "Hyprland")
    property var previewUsersRaw:   cfgString("preview_users", "jane:Jane Doe|alex:Alex Kim|river:River Gray").split("|")
    property var previewSessionsRaw: cfgString("preview_sessions", "Hyprland|Plasma|GNOME|XFCE|i3").split("|")

    property int scaleBaseWidth:  cfgNumber("scale_base_width", 1920)
    property int scaleBaseHeight: cfgNumber("scale_base_height", 1080)
    property real scaleMin:       cfgNumber("scale_min", 0.8)
    property real scaleMax:       cfgNumber("scale_max", 1.6)
    property real scaleFactor: Math.max(scaleMin, Math.min(scaleMax, Math.min((root.width || scaleBaseWidth) / scaleBaseWidth, (root.height || scaleBaseHeight) / scaleBaseHeight)))
    function s(v) { return Math.round(v * scaleFactor); }

    property int timeSizePx:     s(timeSize)
    property int dateSizePx:     s(dateSize)
    property int titleSizePx:    s(titleSize)
    property int usernameSizePx: s(usernameSize)
    property int passwordSizePx: s(passwordSize)
    property int sessionSizePx:  s(sessionSize)
    property int profileInitialSizePx: s(profileInitialSize)
    property int avatarInitialSizePx:  s(avatarInitialSize)
    property int refreshIconSizePx:    s(refreshIconSize)
    property int powerIconSizePx:      s(powerIconSize)
    property int loginIconSizePx:      s(loginIconSize)
    property int outerMarginPx:       s(outerMargin)
    property int centerSpacingPx:     s(centerSpacing)
    property int sidebarWidthPx:      s(sidebarWidth)
    property int userItemHeightPx:    s(userItemHeight)
    property int sessionItemHeightPx: s(sessionItemHeight)
    property int loginBoxWidthPx:     s(loginBoxWidth)
    property int loginBoxHeightPx:    s(loginBoxHeight)
    property int searchBoxHeightPx:   s(34)
    property int searchBoxRadiusPx:   s(17)

    property int animFast:    cfgNumber("anim_fast", 120)
    property int animMedium:  cfgNumber("anim_medium", 200)
    property int animSidebar: cfgNumber("anim_sidebar", 220)

    // ─────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────
    function getUserLoginName(idx) {
        if (!userModel || !userModel.data || userModel.count === 0) return (userModel && userModel.lastUser) ? userModel.lastUser : "";
        return firstNonEmpty([
            userModel.data(idx, 256),
            userModel.data(idx, 257),
            userModel.data(idx, 2),
            userModel.data(idx, 1),
            userModel.data(idx, 0)
        ], userModel.lastUser || "");
    }

    function getUserDisplayName(idx) {
        if (!userModel || !userModel.data || userModel.count === 0) return (userModel && userModel.lastUser) ? userModel.lastUser : "";
        return firstNonEmpty([
            userModel.data(idx, 2),
            userModel.data(idx, 258),
            userModel.data(idx, 259),
            userModel.data(idx, 1),
            userModel.data(idx, 0),
            getUserLoginName(idx)
        ], "");
    }

    function getSessionName(idx) {
        if (!sessionModel || !sessionModel.data || sessionModel.count === 0) return "Hyprland";
        return firstNonEmpty([
            sessionModel.data(idx, 0),
            sessionModel.data(idx, 2),
            sessionModel.data(idx, 261),
            sessionModel.data(idx, 210),
            sessionModel.data(idx, 1),
            sessionModel.data(idx, 256),
            sessionModel.data(idx, 257),
            sessionModel.data(idx, 258),
            sessionModel.data(idx, 259),
            sessionModel.data(idx, 260)
        ], "Session " + idx);
    }

    function syncSessionFromModel() {
        if (sessionModel.count === 0) return;
        var sidx = (sessionModel.lastIndex >= 0 && sessionModel.lastIndex < sessionModel.count)
                    ? sessionModel.lastIndex : root.currentSessionIndex;
        if (sidx < 0 || sidx >= sessionModel.count) sidx = 0;
        root.currentSessionIndex = sidx;
        root.currentSessionName  = getSessionName(sidx);
    }

    function getProfilePicture(username, attempt) {
        if (!username) return "";
        if (!avatarBasePaths || avatarBasePaths.length === 0) return "";
        var idx = (attempt === undefined || attempt === null) ? 0 : Number(attempt);
        if (idx < 0) idx = 0;
        if (idx >= avatarBasePaths.length) idx = avatarBasePaths.length - 1;
        return avatarBasePaths[idx] + "/" + username;
    }

    function accentForName(name) {
        if (!name || accentPalette.length === 0) return root.cAccent;
        var hash = 0;
        for (var i = 0; i < name.length; i++) {
            hash = ((hash << 5) - hash) + name.charCodeAt(i);
            hash |= 0;
        }
        var idx = Math.abs(hash) % accentPalette.length;
        var c = accentPalette[idx];
        return (c && c.trim) ? c.trim() : c;
    }

    // Caps lock hint removed (system does not expose reliable state).

    function setFocusIndex(idx) {
        if (!focusTargets || focusTargets.length === 0) return;
        var count = focusTargets.length;
        var next = (idx + count) % count;
        focusIndex = next;
        var target = focusTargets[next];
        if (target && target.forceActiveFocus) target.forceActiveFocus();
    }

    function focusNext(dir) {
        setFocusIndex(focusIndex + dir);
    }

    function buildPreviewModels() {
        previewUserModel.clear();
        for (var i = 0; i < previewUsersRaw.length; i++) {
            var entry = previewUsersRaw[i];
            if (!entry || entry === "") continue;
            var parts = entry.split(":");
            var name = parts[0] || ("user" + i);
            var real = parts.length > 1 ? parts[1] : name;
            previewUserModel.append({ "name": name, "realName": real });
        }

        previewSessionModel.clear();
        for (var j = 0; j < previewSessionsRaw.length; j++) {
            var s = previewSessionsRaw[j];
            if (!s || s === "") continue;
            previewSessionModel.append({ "name": s });
        }
    }

    function userNameAt(idx) {
        if (root.previewEnabled) {
            var u = previewUserModel.get(idx);
            return u ? u.name : "";
        }
        return getUserLoginName(idx);
    }

    function userDisplayAt(idx) {
        if (root.previewEnabled) {
            var u = previewUserModel.get(idx);
            return u ? (u.realName || u.name) : "";
        }
        return getUserDisplayName(idx);
    }

    function userMatchesCount() {
        var q = root.userSearchQuery.toLowerCase().trim();
        var count = root.previewEnabled ? previewUserModel.count : userModel.count;
        if (q === "") return count;
        var matches = 0;
        for (var i = 0; i < count; i++) {
            var name = userNameAt(i);
            var display = userDisplayAt(i);
            if ((name && name.toLowerCase().indexOf(q) >= 0) ||
                (display && display.toLowerCase().indexOf(q) >= 0)) {
                matches++;
            }
        }
        return matches;
    }

    function sessionNameAt(idx) {
        if (root.previewEnabled) {
            var s = previewSessionModel.get(idx);
            return s ? s.name : "";
        }
        return getSessionName(idx);
    }

    function sessionMatchesCount() {
        var q = root.sessionSearchQuery.toLowerCase().trim();
        var count = root.previewEnabled ? previewSessionModel.count : sessionModel.count;
        if (q === "") return count;
        var matches = 0;
        for (var i = 0; i < count; i++) {
            var name = sessionNameAt(i);
            if (name && name.toLowerCase().indexOf(q) >= 0) matches++;
        }
        return matches;
    }

    function oskLabelFor(key) {
        var map = {
            "`": "~", "1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^",
            "7": "&", "8": "*", "9": "(", "0": ")", "-": "_", "=": "+",
            "[": "{", "]": "}", "\\": "|", ";": ":", "'": "\"", ",": "<", ".": ">", "/": "?"
        };
        if (oskShift && map[key]) return map[key];
        if (oskShift && key.length === 1 && key.toLowerCase() !== key.toUpperCase()) return key.toUpperCase();
        return key;
    }



    function performLogin(password) {
        var username = root.currentUsername;
        if (root.debugLogging) {
            console.log("LOGIN: user=" + username
                        + " session=" + root.currentSessionName
                        + " idx=" + root.currentSessionIndex);
        }

        if (!username || username === "") {
            root.loginFailed   = true;
            root.loginErrorMsg = qsTr("No user selected.");
            return;
        }
        if (!password || password === "") {
            root.loginFailed   = true;
            root.loginErrorMsg = qsTr("Please enter your password.");
            return;
        }

        root.loginFailed   = false;
        root.loginErrorMsg = "";
        if (loginPanel) loginPanel.pulse();
        sddm.login(username, password, root.currentSessionIndex);
    }

    function requestPasswordClear() {
        if (loginPanel) loginPanel.clearPassword();
    }

    function requestPasswordFocus() {
        if (loginPanel) loginPanel.focusPassword();
    }

    function openUserSidebar() {
        root.userSidebarOpen = !root.userSidebarOpen;
        root.sessionSidebarOpen = false;
        if (root.userSidebarOpen) {
            if (userSidebarComp) userSidebarComp.focusSearch();
        } else {
            if (userSidebarComp) userSidebarComp.clearSearch();
        }
    }

    function openSessionSidebar() {
        root.sessionSidebarOpen = !root.sessionSidebarOpen;
        root.userSidebarOpen = false;
        if (root.sessionSidebarOpen) {
            if (sessionSidebarComp) sessionSidebarComp.focusSearch();
        } else {
            if (sessionSidebarComp) sessionSidebarComp.clearSearch();
        }
    }

    function closeSidebars() {
        root.sessionSidebarOpen = false;
        root.userSidebarOpen = false;
        if (userSidebarComp) userSidebarComp.clearSearch();
        if (sessionSidebarComp) sessionSidebarComp.clearSearch();
    }

    ListModel { id: previewUserModel }
    ListModel { id: previewSessionModel }

    Shortcut {
        sequence: "Alt+U"
        context: Qt.ApplicationShortcut
        onActivated: openUserSidebar()
    }

    Shortcut {
        sequence: "Alt+S"
        context: Qt.ApplicationShortcut
        onActivated: openSessionSidebar()
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Escape) {
            closeSidebars();
            root.oskOpen = false;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Tab) {
            focusNext((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
            return;
        }

        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_S) {
                openSessionSidebar();
                event.accepted = true;
            } else if (event.key === Qt.Key_U) {
                openUserSidebar();
                event.accepted = true;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Background
    Bg.BackgroundLayer { app: root }

    // Clock
    Clock.ClockBlock { app: root }

    // User sidebar
    Sidebars.UserSidebar {
        id: userSidebarComp
        app: root
        usersModel: userModel
        previewUserModel: previewUserModel
    }

    // Centered login area
    Center.LoginPanel {
        id: loginPanel
        app: root
    }

    // On-screen keyboard
    Controls.OnScreenKeyboard {
        app: root
        targetInput: loginPanel.passField
    }

    // Session sidebar
    Sidebars.SessionSidebar {
        id: sessionSidebarComp
        app: root
        sessionsModel: sessionModel
        previewSessionModel: previewSessionModel
    }

    // Power buttons
    Controls.PowerRow { app: root }

    // Dismiss overlays on outside click  (z:5, below dropdown z:200)
    MouseArea {
        anchors.fill: parent
        enabled: root.sessionSidebarOpen || root.userSidebarOpen
        z: 5
        onClicked: {
            closeSidebars();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SDDM login failure
    // ─────────────────────────────────────────────────────────────
    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginFailed   = true;
            root.loginErrorMsg = qsTr("Wrong password — try again.");
            if (loginPanel) {
                loginPanel.clearPassword();
                loginPanel.focusPassword();
                loginPanel.shake();
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Startup
    // ─────────────────────────────────────────────────────────────
    Component.onCompleted: {
        if (root.debugLogging) {
            console.log("=== SDDM Theme Init ===");
            console.log("Users:", userModel.count, "lastUser:", userModel.lastUser,
                        "lastIndex:", userModel.lastIndex);
            console.log("Sessions:", sessionModel.count, "lastIndex:", sessionModel.lastIndex);
        }

        if (root.previewEnabled) {
            buildPreviewModels();
            root.currentUsername    = root.previewUser !== "" ? root.previewUser : "preview";
            root.currentDisplayName = root.previewDisplay !== "" ? root.previewDisplay : root.currentUsername;
            root.currentSessionIndex = 0;
            root.currentSessionName  = root.previewSession !== "" ? root.previewSession : "Session";
        } else {
            var uidx = (userModel.lastIndex >= 0 && userModel.lastIndex < userModel.count)
                        ? userModel.lastIndex : 0;
            if (userModel.count > 0) {
                root.currentUsername    = getUserLoginName(uidx);
                root.currentDisplayName = getUserDisplayName(uidx);
            } else {
                root.currentUsername    = userModel.lastUser || "";
                root.currentDisplayName = userModel.lastUser || "";
            }
            if (root.debugLogging) {
                console.log("Active user:", root.currentUsername, "/", root.currentDisplayName);
            }

            root.currentSessionIndex = 0;
            root.currentSessionName  = getSessionName(0);
            syncSessionFromModel();
            if (root.debugLogging) {
                console.log("Active session:", root.currentSessionName, "idx:", root.currentSessionIndex);
            }
        }

        if (root.debugLogging) {
            for (var i = 0; i < sessionModel.count; i++) {
                console.log("  session[" + i + "]"
                            + " r0=" + sessionModel.data(i, 0)
                            + " r2=" + sessionModel.data(i, 2)
                            + " r210=" + sessionModel.data(i, 210)
                            + " r261=" + sessionModel.data(i, 261));
            }
        }

        if (loginPanel) loginPanel.focusPassword();
        focusTargets = [loginPanel.usernameButton, loginPanel.passField, loginPanel.sessionSelector, loginPanel.loginIcon];
        root.oskOpen = root.oskDefaultOpen;
    }

    Connections {
        target: sessionModel
        ignoreUnknownSignals: true
        function onCountChanged() {
            if (!root.previewEnabled) syncSessionFromModel();
        }
    }
}
