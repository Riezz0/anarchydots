pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property int refCount: 0
    property bool needsStart
    property list<string> startArgs
    property bool needsStop
    property bool needsPause

    function start(extraArgs = []): void {
        needsStart = true;
        startArgs = extraArgs;
        checkProc.running = true;
    }

    function stop(): void {
        needsStop = true;
        checkProc.running = true;
    }

    function togglePause(): void {
        needsPause = true;
        checkProc.running = true;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0 // Might get too large for int

        reloadableId: "recorder"
    }

    Process {
        id: checkProc

        running: true
        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => {
            const running = code === 0;

            if (running && root.needsStop) {
                root.runRecorder([]);
                props.running = false;
                props.paused = false;
            } else if (running && root.needsPause) {
                root.runRecorder(["-p"]);
                props.paused = !props.paused;
            } else if (!running && root.needsStart) {
                root.runRecorder(root.startArgs);
                props.running = true;
                props.paused = false;
                props.elapsed = 0;
            } else if (running !== props.running && !commandProc.running) {
                // The recording was started/stopped outside the shell (e.g. via
                // keybind), or our command finished without reaching the optimistic state
                props.running = running;
                props.paused = false;
                props.elapsed = 0;
            }

            root.needsStart = false;
            root.needsStop = false;
            root.needsPause = false;
        }
    }

    // The command owns the transition: `caelestia record` blocks on slurp for
    // region captures, and waits for the recorder to finalise the file when
    // stopping. Reconcile once it has actually finished.
    // Run it through a shell wrapper with output detached: the CLI spawns
    // gpu-screen-recorder detached but inheriting its stdio. Under a QML
    // Process the inherited fds are pipes that Quickshell closes when the
    // Process exits, so the recorder dies with SIGPIPE on its next log line
    // seconds later (CLI exits 0, card rolls back to "Ready"). Redirecting to
    // /dev/null here keeps the recorders fds valid. Early failures are still
    // notified by the CLI itself ("Recording failed").
    Process {
        id: commandProc

        onExited: checkProc.running = true
    }

    function runRecorder(args: list<string>): void {
        let escaped = args.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ");
        commandProc.exec(["sh", "-c", `exec caelestia record ${escaped} >/dev/null 2>&1`]);
    }

    // Only poll while something is showing the state, i.e. the utilities drawer is open
    Timer {
        interval: 1000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true

        onTriggered: checkProc.running = true
    }

    Connections {
        function onSecondsChanged(): void {
            props.elapsed++;
        }

        enabled: props.running && !props.paused
        target: Time
    }
}
