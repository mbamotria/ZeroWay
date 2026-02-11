import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: backgroundLayer
    property var app
    anchors.fill: parent

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: app.backgroundSource
        fillMode: Image.PreserveAspectCrop
        FastBlur { anchors.fill: parent; source: backgroundImage; radius: app.blurRadius }
    }
    ShaderEffect {
        id: shaderLayer
        anchors.fill: parent
        visible: app.shaderEnabled
        property real t: 0
        property real strength: app.shaderStrength
        property color tint: app.shaderTint
        NumberAnimation on t {
            from: 0; to: 1; duration: app.shaderSpeed; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }
        fragmentShader: "
            uniform highp float t;
            uniform lowp float strength;
            uniform lowp vec4 tint;
            varying highp vec2 qt_TexCoord0;
            highp float hash(highp vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
            }
            void main() {
                highp vec2 uv = qt_TexCoord0 * 2.0;
                highp float n = hash(uv * 3.0 + t * 2.0);
                highp float n2 = hash(uv * 7.0 - t * 1.3);
                highp float v = mix(n, n2, 0.5);
                gl_FragColor = vec4(tint.rgb, v * strength);
            }
        "
    }
    Rectangle {
        id: ambientLayer
        anchors.fill: parent
        visible: app.ambientEnabled
        opacity: app.ambientOpacity
        rotation: -2
        scale: 1.08
        transformOrigin: Item.Center
        gradient: Gradient {
            GradientStop { id: stop1; position: 0.0; color: Qt.rgba(0.11, 0.33, 0.45, 0.55) }
            GradientStop { id: stop2; position: 0.6; color: Qt.rgba(0.05, 0.12, 0.18, 0.25) }
            GradientStop { id: stop3; position: 1.0; color: Qt.rgba(0.02, 0.04, 0.06, 0.35) }
        }
        NumberAnimation on rotation {
            from: -2; to: 2; duration: app.ambientSpeed; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }
        NumberAnimation on scale {
            from: 1.05; to: 1.12; duration: app.ambientSpeed; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: stop1; property: "position"; from: 0.0; to: 1.0; duration: app.ambientSpeed; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: stop2; property: "position"; from: 1.0; to: 0.0; duration: app.ambientSpeed; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }
    }
    Rectangle { anchors.fill: parent; color: app.cBg; opacity: app.overlayOpacity }
}
