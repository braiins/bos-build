#!/usr/bin/env bash

set -eo pipefail

BUILD_DIR="${BUILD_DIR:-"./build"}"
BUILD_DIR="$(realpath "$BUILD_DIR")"

MAKE_JOBS="${MAKE_JOBS:-"$(($(nproc)+1))"}"

function openwrt_nix() {
    ${BASH} "$BUILD_DIR/openwrt/scripts/nix.sh" "$@"
}

cd "$BUILD_DIR/openwrt"
openwrt_nix make -j"$MAKE_JOBS" "$@"
