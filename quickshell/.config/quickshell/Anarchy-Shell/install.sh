#!/bin/bash

cd ~/anarchydots/quickshell/.config/quickshell/test-shell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DINSTALL_LIBDIR=lib/caelestia -DINSTALL_QMLDIR=lib/qt6/qml -DINSTALL_QSCONFDIR="$PWD"
cmake --build build
cmake --install build

