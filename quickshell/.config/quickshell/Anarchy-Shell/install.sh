#!/usr/bin/env bash
#
# Builds Anarchy-Shell (caelestia QML sources + C++ plugin) and installs it
# system-wide.
#
# Layout: ~/.config/quickshell/Anarchy-Shell is the Quickshell config
# directory, and quickshell runs it via `quickshell -c Anarchy-Shell`.
# The build installs:
#   1. plugin/         -> system QML modules (/usr/lib/qt6/qml)
#   2. extras/         -> system version binary (/usr/lib/caelestia)
#   3. shell QML files -> ~/.config/quickshell/Anarchy-Shell
#   4. pywal bridge    -> ~/.local/bin
#
# NOTE: if ~/.config/quickshell/Anarchy-Shell is a stow symlink into the
# repo, the shell-module install writes the QML sources back over the
# checkout (including the transformed shell.qml).
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

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    echo "error: run this installer as your normal user, not root (it writes to \$HOME)." >&2
    exit 1
fi

# Build from the directory this script lives in, regardless of the
# invoking CWD. Resolve the script itself through stow symlinks first, so
# this also works when ~/.config/quickshell/Anarchy-Shell is a real
# directory containing per-file symlinks (stow without folding).
SELF="$(readlink -f -- "${BASH_SOURCE[0]}")"
SRC_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd -P)"
PREFIX="/usr"

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

# Start from a clean cache so the new install prefix/module list always apply.
rm -rf -- build

cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/ \
    -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/Anarchy-Shell"

cmake --build build

sudo cmake --install build
sudo chown -R "$(id -un)" "$HOME/.config/quickshell/Anarchy-Shell"

rm -rf -- "$SRC_DIR/build"

# ---------------------------------------------------------------
# Helper scripts / pywal bridge
# ---------------------------------------------------------------
# Only the two pywal bridge helpers belong in ~/.local/bin. The rest of the
# helper scripts are already stowed into /usr/local/bin by the offline
# installer, so they are intentionally not touched here.
find_repo_root() {
    local dir

    # Explicit override, e.g. ANARCHYDOTS_DIR=~/dots ./install.sh
    if [ -n "${ANARCHYDOTS_DIR:-}" ] && [ -d "$ANARCHYDOTS_DIR/local-bin" ]; then
        printf '%s\n' "$ANARCHYDOTS_DIR"
        return 0
    fi

    # Real script location (already resolved through stow symlinks above).
    dir="$SRC_DIR"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/local-bin" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir="$(dirname -- "$dir")"
    done

    # Fall back to common clone names in case the shell was copied rather
    # than stowed from the repo.
    for dir in "$HOME/anarchydots" "$HOME/dots" "$HOME/mydots" "$HOME/.config/anarchydots"; do
        if [ -d "$dir/local-bin" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
    done

    # Last resort: locate the package by its unique helper file.
    local helper
    helper="$(find "$HOME" -maxdepth 6 -type f \
        -path '*/local-bin/bin/wal-to-caelestia' -print -quit 2>/dev/null || true)"
    if [ -n "$helper" ]; then
        printf '%s\n' "${helper%/local-bin/bin/wal-to-caelestia}"
        return 0
    fi

    return 1
}

if REPO_ROOT="$(find_repo_root)"; then
    echo "Repo root: $REPO_ROOT"
    if command -v stow >/dev/null 2>&1; then
        # Undo a previous all-scripts stow into ~/.local, then place only the
        # bridge helpers there.
        mkdir -p "$HOME/.local/bin"
        # If a previous stow folded ~/.local/bin itself into a symlink to our
        # package, replace the link with a real directory before touching the
        # entries (removing the link does not delete the repo files).
        if [ -L "$HOME/.local/bin" ] && [ "$(readlink -f "$HOME/.local/bin")" = "$REPO_ROOT/local-bin/bin" ]; then
            rm -f "$HOME/.local/bin"
            mkdir -p "$HOME/.local/bin"
        fi
        stow -D -t "$HOME/.local" scripts >/dev/null 2>&1 || true
        rm -f "$HOME/.local/bin/wal-to-caelestia" \
              "$HOME/.local/bin/wal-to-caelestia.py" \
              "$HOME/.local/bin/shell-theme-sync" \
              "$HOME/.local/bin/shell-theme-sync.sh"
        stow -d "$REPO_ROOT" -R -t "$HOME/.local" local-bin
        if [ -e "$HOME/.local/bin/wal-to-caelestia" ] && [ -e "$HOME/.local/bin/shell-theme-sync" ]; then
            echo "Stowed pywal bridge helpers into $HOME/.local/bin"
        else
            echo "error: pywal bridge helpers were not stowed into $HOME/.local/bin" >&2
            echo "       repo root: $REPO_ROOT" >&2
            exit 1
        fi
    else
        echo "error: stow not found; cannot set up the pywal bridge helpers" >&2
        echo "       install 'stow', or create these links manually:" >&2
        echo "       ln -s <repo>/local-bin/bin/wal-to-caelestia ~/.local/bin/wal-to-caelestia" >&2
        echo "       ln -s <repo>/local-bin/bin/shell-theme-sync ~/.local/bin/shell-theme-sync" >&2
        exit 1
    fi
else
    echo "error: could not locate the anarchydots checkout for the pywal bridge" >&2
    echo "       re-run with: ANARCHYDOTS_DIR=/path/to/anarchydots $0" >&2
    exit 1
fi

echo "Installed Caelestia QML modules to $PREFIX/lib/qt6/qml"
echo "Installed version binary to $PREFIX/lib/caelestia/version"
echo "Restart the shell: anarchy-shell"
