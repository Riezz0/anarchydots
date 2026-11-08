#!/usr/bin/env bash
#
# Builds Anarchy-Shell (caelestia QML sources + C++ plugin) in place from
# ~/.config/quickshell/Anarchy-Shell.
#
# Layout: ~/.config/quickshell/Anarchy-Shell *is* the anarchydots working
# tree (symlink), and quickshell runs the QML in place via
# `quickshell -c Anarchy-Shell`. The build therefore only needs to:
#   1. compile plugin/ -> Caelestia.* QML modules in ~/.local/lib/qt6/qml
#   2. compile extras/ -> version binary in ~/.local/lib/caelestia
# The "shell" module (QML sources copied to INSTALL_QSCONFDIR) stays
# disabled: with source == destination it would copy assets/components/...
# and the transformed shell.qml back onto the source tree, overwriting it.

set -euo pipefail

# Build from the directory this script lives in, regardless of the
# invoking CWD. (Canonical quickshell location: ~/.config/quickshell/
# Anarchy-Shell; here it resolves to the anarchydots working tree.)
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${HOME}/.local"

command -v cmake >/dev/null || { echo "error: cmake not found" >&2; exit 1; }
command -v ninja >/dev/null || { echo "error: ninja not found" >&2; exit 1; }
command -v pkg-config >/dev/null || { echo "error: pkg-config not found (plugin deps)" >&2; exit 1; }

cd -- "$SRC_DIR"

configure() {
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DINSTALL_LIBDIR=lib/caelestia \
        -DINSTALL_QMLDIR=lib/qt6/qml \
        -DENABLE_MODULES="extras;plugin" \
        -DVERSION=0.0.0 -DGIT_REVISION=unknown
}

# VERSION/GIT_REVISION: this checkout lives inside anarchydots (no tags),
# so pass upstream fallbacks instead of `git describe` on the parent repo.
# (CMakeLists.txt already falls back, but be explicit.)

if ! configure; then
    echo "Configure failed, cleaning build/ and retrying..." >&2
    rm -rf build
    configure
fi

if ! cmake --build build; then
    echo "Build failed, cleaning build/ and retrying..." >&2
    rm -rf build
    configure
    cmake --build build
fi

# Install the compiled QML modules + version binary. QML sources are
# already in place under ~/.config/quickshell/Anarchy-Shell and are not
# copied anywhere.
cmake --install build

rm -rf -- "$SRC_DIR/build"

echo "Installed Caelestia QML modules to $PREFIX/lib/qt6/qml"
echo "Installed version binary to $PREFIX/lib/caelestia/version"
echo "Restart the shell: anarchy-shell"
