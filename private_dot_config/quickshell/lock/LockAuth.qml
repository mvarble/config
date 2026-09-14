import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Password check for the lockscreen, shared by every screen's lock surface so
// typing on any monitor fills the same buffer. Uses the hyprlock PAM service
// (/etc/pam.d/hyprlock, which includes `login`).
Scope {
    id: root

    // Text typed so far. Cleared once handed to PAM.
    property string buffer: ""
    // Last feedback for the user (e.g. "Incorrect password"); empty for none.
    property string message: ""
    property bool messageIsError: false
    readonly property bool busy: pam.active

    signal succeeded

    function submit(): void {
        if (pam.active || buffer === "")
            return;
        message = "";
        if (!pam.start()) {
            message = "Could not start authentication";
            messageIsError = true;
        }
    }

    function reset(): void {
        if (pam.active)
            pam.abort();
        buffer = "";
        message = "";
        messageIsError = false;
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
            root.buffer = "";
        }

        // Informational PAM output (e.g. faillock notices). The password
        // prompt itself arrives with responseRequired and isn't shown.
        onPamMessage: {
            if (responseRequired)
                return;
            root.messageIsError = messageIsError;
            root.message = message;
        }

        onCompleted: result => {
            root.buffer = "";
            if (result === PamResult.Success) {
                root.message = "";
                root.succeeded();
            } else {
                root.messageIsError = true;
                root.message = result === PamResult.MaxTries ? "Too many attempts" : "Incorrect password";
            }
        }

        onError: error => {
            root.buffer = "";
            root.messageIsError = true;
            root.message = "Authentication error: " + PamError.toString(error);
        }
    }
}
