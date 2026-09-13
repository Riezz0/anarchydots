import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: authRoot

    signal authSucceeded()
    signal authFailed()

    property string currentText: ""
    property bool unlockInProgress: false

    onCurrentTextChanged: {}

    function tryUnlock() {
        if (currentText === "") return
        unlockInProgress = true
        pam.start()
    }

    function cancel() {
        if (pam.active) {
            pam.abort()
            unlockInProgress = false
        }
    }

    PamContext {
        id: pam

        configDirectory: Qt.resolvedUrl("pam")
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(authRoot.currentText)
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                authRoot.authSucceeded()
            } else {
                authRoot.currentText = ""
                authRoot.authFailed()
            }
            authRoot.unlockInProgress = false
        }

        onError: {
            authRoot.unlockInProgress = false
            authRoot.authFailed()
        }
    }
}
