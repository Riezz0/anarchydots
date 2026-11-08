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
#
# Build dependencies (plugin/CMakeLists.txt requires them via find_package
# and pkg_check_modules; sensors via cmake/sensorslib.cmake):
#   Arch: cmake ninja pkg-config qt6-shadertools
#         libqalculate pipewire aubio libcava lm_sensors
# Note on cava: Arch ships the library as `libcava` (provides libcava.pc).
# The `cava` app package does NOT provide cava.pc, so
# `pkg-config --exists cava` fails even when `cava` is installed, and
# installing `cava` does not fix the build. Install `libcava` (provides
# libcava.pc). The upstream CMake also probes for `cava` for non-Arch
# distros; either pkg-config module satisfies it.

set -euo pipefail

# Build from the directory this script lives in, regardless of the
# invoking CWD. (Canonical quickshell location: ~/.config/quickshell/
# Anarchy-Shell; here it resolves to the anarchydots working tree.)
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${HOME}/.local"

command -v cmake >/dev/null || { echo "error: cmake not found" >&2; exit 1; }
command -v ninja >/dev/null || { echo "error: ninja not found" >&2; exit 1; }
command -v pkg-config >/dev/null || { echo "error: pkg-config not found (plugin deps)" >&2; exit 1; }

# Preflight: fail fast with all missing deps at once instead of dying
# mid-configure with a misleading pkg-config error (e.g. "Package 'cava'
# not found" on Arch, where the Arch package is `libcava`, not `cava`).
missing=()
need() { # need <label> <arch-package> <test...>
    local label="$1" pkg="$2"; shift 2
    if ! "$@" >/dev/null 2>&1; then
        missing+=("$pkg")
        echo "missing: $label ($pkg)" >&2
    fi
}
need "pkg-config: libqalculate"    libqalculate    pkg-config --exists libqalculate
need "pkg-config: libpipewire-0.3" pipewire        pkg-config --exists libpipewire-0.3
need "pkg-config: aubio"           aubio           pkg-config --exists aubio
# cava: Arch wants libcava (libcava.pc); accept cava.pc on other distros.
if ! pkg-config --exists libcava >/dev/null 2>&1 && ! pkg-config --exists cava >/dev/null 2>&1; then
    missing+=(libcava)
    echo "missing: pkg-config: libcava|cava (libcava)" >&2
fi
# sensors: libsensors + header (lm_sensors)
if [ ! -f /usr/include/sensors/sensors.h ] && ! pkg-config --exists libsensors >/dev/null 2>&1; then
    missing+=(lm_sensors)
    echo "missing: sensors (lm_sensors)" >&2
fi
# Qt6 ShaderTools (qt_add_shaders in plugin/CMakeLists.txt)
if [ ! -x /usr/lib/qt6/bin/qsb ] && ! command -v qsb >/dev/null 2>&1; then
    missing+=(qt6-shadertools)
    echo "missing: Qt6 ShaderTools (qsb) (qt6-shadertools)" >&2
fi
if [ ${#missing[@]} -gt 0 ]; then
    # Unique packages for the install command.
    uniq_missing=$(printf '%s\n' "${missing[@]}" | sort -u)
    echo "" >&2
    echo "Install the missing build dependencies, then re-run ./install.sh:" >&2
    echo "  sudo pacman -S --needed $(echo $uniq_missing | tr '\n' ' ' | sed 's/ *$//')" >&2
    echo "  # or: paru -S $(echo $uniq_missing | tr '\n' ' ' | sed 's/ *$//')" >&2
    exit 1
fi
echo "All build dependencies found."

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
