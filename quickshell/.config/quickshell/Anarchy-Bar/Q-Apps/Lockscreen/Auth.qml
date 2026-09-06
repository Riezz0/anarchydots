import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: authRoot

    signal authSucceeded()
    signal authFailed()

    property bool authenticating: false
    property string password: ""

    PamContext {
        id: pamContext

        onCompleted: {
            authRoot.authenticating = false
            if (result === PamResult.Success) {
                authRoot.authSucceeded()
            } else {
                authRoot.authFailed()
            }
        }

        onError: {
            authRoot.authenticating = false
            authRoot.authFailed()
        }

        onResponseRequiredChanged: {
            if (pamContext.responseRequired) {
                pamContext.respond(authRoot.password)
            }
        }
    }

    function startAuth(pass) {
        if (authenticating) return
        password = pass
        authenticating = true
        pamContext.start()
    }

    function cancel() {
        if (authenticating) {
            pamContext.abort()
            authenticating = false
        }
    }
}
