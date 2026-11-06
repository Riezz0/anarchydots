pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight

    Component.onCompleted: Themes.scan()

    onVisibleChanged: {
        if (visible)
            Themes.scan();
    }

    // applying overlay
    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        visible: Themes.applying

        Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.large

            LoadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 40
                color: Colours.palette.m3primary
                animated: Themes.applying
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Themes.applyingName ? Tr.tr("Applying ⟨%1⟩ …").arg(Themes.applyingName) : ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }
        }
    }

    // empty state
    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.large
        visible: !Themes.applying && Themes.themes.length === 0

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "palette"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Tr.tr("No themes found")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.large
        }
    }

    // theme carousel
    GridView {
        id: grid

        anchors.fill: parent
        clip: true
        visible: !Themes.applying && Themes.themes.length > 0

        model: Themes.themes
        currentIndex: Themes.themes.findIndex(t => t.name === Themes.currentTheme)
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: cellWidth * 4

        cellWidth: 130
        cellHeight: 195

        delegate: Item {
            id: card

            required property var modelData
            required property int index

            readonly property bool selected: index === grid.currentIndex

            width: grid.cellWidth
            height: grid.cellHeight

            StyledRect {
                id: thumbWrapper

                anchors.fill: parent
                anchors.margins: Tokens.spacing.small
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3secondaryContainer
                border.color: card.selected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                border.width: card.selected ? 2 : 1
                opacity: card.selected ? 1 : 0.75
                scale: card.selected ? 1 : 0.88

                Behavior on scale {
                    Anim {}
                }

                Behavior on opacity {
                    Anim {}
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: 2

                    Image {
                        id: themeThumbnail
                        anchors.fill: parent
                        source: card.modelData?.thumbnail ? `file://${card.modelData.thumbnail}` : ""
                        cache: true
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: themeThumbnailMask
                        anchors.fill: themeThumbnail
                        radius: Tokens.rounding.medium
                        color: "white"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: themeThumbnail
                        source: themeThumbnail
                        maskSource: themeThumbnailMask
                    }
                }

                StateLayer {
                    radius: thumbWrapper.radius
                    color: Colours.palette.m3onSurface
                    onClicked: {
                        if (!card.selected)
                            grid.currentIndex = card.index;
                        Themes.apply(card.modelData);
                    }
                }
            }
        }
    }
}
