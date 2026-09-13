import QtQuick

Item {
    id: passwordRoot

    property string password: ""
    property bool shakeActive: false
    property bool showPassword: false
    property alias textInput: input

    signal accepted(string password)

    width: 320
    height: 52

    Rectangle {
        id: container
        anchors.fill: parent
        radius: rootLock.barRadius
        color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.4)
        border.color: passwordRoot.shakeActive ? theme.color1
            : input.activeFocus ? theme.color4 : Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.15)
        border.width: rootLock.popupBorderThickness

        Behavior on border.color { ColorAnimation { duration: 200 } }

        SequentialAnimation {
            id: shakeAnim
            running: false
            NumberAnimation { target: container; property: "x"; to: container.x + 8; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; to: container.x - 8; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; to: container.x + 5; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; to: container.x - 5; duration: 50; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; to: container.x; duration: 50; easing.type: Easing.InOutQuad }
            ScriptAction { script: passwordRoot.shakeActive = false }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "󰌾"
                font.pixelSize: 18
                font.family: "JetBrainsMono Nerd Font"
                color: input.activeFocus ? theme.color4 : theme.color7
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 70
                height: parent.height - 8
                color: theme.foreground
                selectionColor: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.4)
                echoMode: passwordRoot.showPassword ? TextInput.Normal : TextInput.Password
                font.pixelSize: 17
                font.family: "JetBrainsMono Nerd Font"
                verticalAlignment: TextInput.AlignVCenter
                focus: true
                clip: true

                property string placeholderText: "Password"

                Text {
                    visible: input.text.length === 0 && !input.activeFocus
                    text: input.placeholderText
                    color: theme.color7
                    font: input.font
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: submit()
                Keys.onEnterPressed: submit()
            }

            // Eye toggle button
            Rectangle {
                width: 32; height: 32; radius: 6
                color: eyeArea.containsMouse ? Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.2) : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: passwordRoot.showPassword ? "󰈈" : "󰈉"
                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color7
                }

                MouseArea {
                    id: eyeArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: passwordRoot.showPassword = !passwordRoot.showPassword
                }
            }
        }
    }

    function submit() {
        if (input.text.length > 0) {
            passwordRoot.password = input.text
            passwordRoot.accepted(input.text)
        }
    }

    function shake() {
        passwordRoot.shakeActive = true
        shakeAnim.start()
    }

    function clear() {
        input.text = ""
    }

    function reset() {
        input.text = ""
        passwordRoot.shakeActive = false
        input.forceActiveFocus()
    }
}
