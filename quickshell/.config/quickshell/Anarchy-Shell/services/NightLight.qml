pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shared with Anarchy-Bar (see SettingsPopup.qml). Anarchy-Bar only stores
    // {enabled} and uses a fixed 4000K; this service reads "temperature" when
    // present and defaults to 4000K so both shells stay in sync.
    readonly property string configPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/Anarchy-Bar/nightlight.json`

    property bool enabled: false
    property int temperature: 4000

    property bool _loading: false

    function setEnabled(value: bool): void {
        enabled = value;
    }

    function setTemperature(value: int): void {
        temperature = Math.max(1000, Math.min(6500, Math.round(value)));
    }

    function save(): void {
        const dir = root.configPath.substring(0, root.configPath.lastIndexOf("/"));
        const json = JSON.stringify({
            enabled: root.enabled,
            temperature: root.temperature
        });
        saveProc.command = ["sh", "-c", `mkdir -p '${dir}' && printf '%s' '${json}' > '${root.configPath}'`];
        saveProc.running = true;
    }

    function apply(): void {
        if (root.enabled) {
            // Kill any previous instance first so temperature changes take
            // effect, then start detached so it survives shell restarts.
            restartProc.command = ["sh", "-c", `pkill hyprsunset 2>/dev/null; sleep 0.2; nohup setsid bash -c 'hyprsunset -t ${root.temperature} </dev/null >/dev/null 2>&1'`];
            restartProc.running = true;
        } else {
            stopProc.command = ["pkill", "hyprsunset"];
            stopProc.running = true;
        }
    }

    onEnabledChanged: {
        if (root._loading)
            return;
        root.save();
        root.apply();
    }

    onTemperatureChanged: {
        if (root._loading)
            return;
        root.save();
        if (root.enabled)
            root.apply();
    }

    Component.onCompleted: nightlightFileView.reload()

    Process {
        id: saveProc

        running: false
        stdout: SplitParser {}
    }

    Process {
        id: restartProc

        running: false
        stdout: SplitParser {}
    }

    Process {
        id: stopProc

        running: false
        stdout: SplitParser {}
    }

    FileView {
        id: nightlightFileView

        path: root.configPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(nightlightFileView.text() || "{}");
                if (!data)
                    return;
                root._loading = true;
                if (data.enabled !== undefined)
                    root.enabled = !!data.enabled;
                if (data.temperature !== undefined && !isNaN(data.temperature))
                    root.temperature = Math.max(1000, Math.min(6500, Math.round(data.temperature)));
                root._loading = false;
                root.apply();
            } catch (e) {}
        }
    }
}
