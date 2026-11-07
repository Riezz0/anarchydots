#!/bin/bash

cd ~/anarchydots/quickshell/.config/quickshell/Anarchy-Shell
# Anarchy-Shell lives inside the anarchydots repo which has no tags;
# CMake would fatal-error on git describe. Pass a fallback version.
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DINSTALL_LIBDIR=lib/caelestia -DINSTALL_QMLDIR=lib/qt6/qml -DINSTALL_QSCONFDIR="$PWD" -DVERSION=0.0.0 -DGIT_REVISION=unknown
if [ $? -ne 0 ]; then
    echo "Configure failed, cleaning build/ and retrying..."
    rm -rf build
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DINSTALL_LIBDIR=lib/caelestia -DINSTALL_QMLDIR=lib/qt6/qml -DINSTALL_QSCONFDIR="$PWD" -DVERSION=0.0.0 -DGIT_REVISION=unknown
fi
cmake --build build
if [ $? -ne 0 ]; then
    echo "Build failed, cleaning build/ and retrying..."
    rm -rf build
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DINSTALL_LIBDIR=lib/caelestia -DINSTALL_QMLDIR=lib/qt6/qml -DINSTALL_QSCONFDIR="$PWD" -DVERSION=0.0.0 -DGIT_REVISION=unknown
    cmake --build build
fi
cmake --install build

rm -rf /home/$USER/.config/quickshell/Anarchy-Shell/build/
