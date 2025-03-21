#!/usr/bin/env bash

set -eo pipefail

BUILD_DIR="${BUILD_DIR:-"./build"}"
BUILD_DIR="$(realpath "$BUILD_DIR")"

FW_MAJOR="${FW_MAJOR:-"2024-03-26-0-5aa91fcb-24.03-plus"}"
FW_VERSION="${FW_VERSION:-"2025-02-21-0-e05df053-25.01-plus"}"
FW_REQUIRE="${FW_REQUIRE:-"2023-09-07-0-022c6ed2-23.09-plus"}"

BOS_ASSETS_DIR="${BOS_ASSETS_DIR:-"$BUILD_DIR/bos-assets"}"
VERSION_PATH="${VERSION_PATH:-"$(realpath "./sysupgrade/version.json")"}"

function openwrt_nix() {
    ${BASH} "$BUILD_DIR/openwrt/scripts/nix.sh" "$@"
}

# add build keys
cp "./keys/test" "$BUILD_DIR/openwrt/key-build"
cp "./keys/test.pub" "$BUILD_DIR/openwrt/key-build.pub"

# configure feeds
cp "$BUILD_DIR/openwrt/feeds.conf.default" "$BUILD_DIR/openwrt/feeds.conf"
echo "src-link bos $BUILD_DIR/bos-packages" >> "$BUILD_DIR/openwrt/feeds.conf"

# prepare OpenWrt configuration
cp "./defaults/stm32mp15_ii1.conf" "$BUILD_DIR/openwrt/.config.bos"
cd "$BUILD_DIR/openwrt"

sed -i "s#%MAJOR%#${FW_MAJOR}#g" ".config.bos"
sed -i "s#%VERSION%#${FW_VERSION}#g" ".config.bos"
sed -i "s#%REQUIRE%#${FW_REQUIRE}#g" ".config.bos"

sed -i "s#%BOS_ASSETS_DIR%#${BOS_ASSETS_DIR}#g" ".config.bos"
sed -i "s#%VERSION_PATH%#${VERSION_PATH}#g" ".config.bos"

# prepare feeds
openwrt_nix ./scripts/feeds update -a
openwrt_nix ./scripts/feeds install -a

# make default configuration
mv ".config.bos" ".config"
openwrt_nix make defconfig
