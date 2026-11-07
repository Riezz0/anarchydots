pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Updates backed by arch-update: `arch-update -c` checks non-interactively
// (and refreshes the state files the timer also writes), while `arch-update`
// itself is interactive so it is launched in a terminal. The pending list is
// read from ~/.local/state/arch-update/last_updates_check_* with FileViews
// that hot-reload when the systemd timer updates them.
PageBase {
    id: root

    title: Tr.tr("Updates")

    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/arch-update`

    property list<string> packages: []
    property list<string> aurPackages: []
    property string lastCheck: ""
    property bool checking: false

    Component.onCompleted: checkProc.running = true

    function parseList(text: string): list<string> {
        return text.split("\n").map(s => s.trim()).filter(s => s.length > 0);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        FileView {
            id: pkgFile

            path: `${root.stateDir}/last_updates_check_packages`
            watchChanges: true
            onFileChanged: reload()
            onLoaded: root.packages = root.parseList(text())
        }

        FileView {
            id: aurFile

            path: `${root.stateDir}/last_updates_check_aur`
            watchChanges: true
            onFileChanged: reload()
            onLoaded: root.aurPackages = root.parseList(text())
        }

        FileView {
            id: timeFile

            path: `${root.stateDir}/last_updates_check_time`
            watchChanges: true
            onFileChanged: reload()
            onLoaded: root.lastCheck = text().trim()
        }

        Process {
            id: checkProc

            onExited: {
                root.checking = false;
                pkgFile.reload();
                aurFile.reload();
                timeFile.reload();
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("Status")
        }

        InfoRow {
            first: true
            label: Tr.tr("Pending updates")
            value: (root.packages.length + root.aurPackages.length).toString()
        }

        InfoRow {
            last: true
            label: Tr.tr("Last checked")
            value: root.lastCheck || Tr.tr("Never")
        }

        SectionHeader {
            text: Tr.tr("Actions")
        }

        RowButton {
            first: true
            icon: "refresh"
            text: Tr.tr("Check now")
            subtext: Tr.tr("Ask arch-update to check for updates")
            disabled: root.checking
            onClicked: {
                root.checking = true;
                checkProc.exec(["arch-update", "-c"]);
            }
        }

        RowButton {
            last: true
            icon: "download"
            text: Tr.tr("Install updates")
            subtext: Tr.tr("Run arch-update in a terminal")
            onClicked: Quickshell.execDetached([...GlobalConfig.general.apps.terminal, "--class", "arch-update", "--title", "arch-update", "--hold", "arch-update"])
        }

        SectionHeader {
            text: Tr.tr("Pending packages")
        }

        InfoRow {
            first: true
            label: Tr.tr("Total")
            value: (root.packages.length + root.aurPackages.length).toString()
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: pkgText.implicitHeight + Tokens.padding.medium * 2

            StyledText {
                id: pkgText

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                text: {
                    const all = root.packages.concat(root.aurPackages);
                    if (all.length === 0)
                        return Tr.tr("No pending updates");
                    return all.join("\n");
                }

                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
