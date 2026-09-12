//@ pragma UseQApplication
//@ pragma AppId qplayer
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=,
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=,
import QtQuick
import Quickshell

ShellRoot {
    QPlayer {}
}
