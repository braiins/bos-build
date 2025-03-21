#!/usr/bin/env bash

set -eo pipefail
set +u

REPO_URL="${REPO_URL:-git@github.com:braiins}"

BUILD_DIR="${BUILD_DIR:-"./build"}"
BUILD_DIR="$(realpath "$BUILD_DIR")"

function git_timestamp() {
    local repo="$1"
    git -C "$BUILD_DIR/$repo" log -1 --format=format:%ct
}

# list of repositories to clone
repos=(
    "openwrt"
    "bos-assets"
    "bos-packages"
    "linux-stm"
    "u-boot-stm"
    "arm-trusted-firmware-stm"
)

git_args=()
[[ "$DEEP_CLONE" != "yes" ]] && git_args+=("--depth=1")
[[ -n "$TAG_NAME" ]] && git_args+=("--branch=$TAG_NAME")

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

for repo in "${repos[@]}"; do
    git clone "${git_args[@]}" "$REPO_URL/$repo.git"
    echo -e "OK\n"
done

# save timestamp of the last commit for reproducible builds
git_timestamp "arm-trusted-firmware-stm" \
    > "$BUILD_DIR/openwrt/package/boot/arm-trusted-firmware-stm32mp15/version.date"
git_timestamp "u-boot-stm" \
    > "$BUILD_DIR/openwrt/package/boot/uboot-stm32mp15/version.date"
git_timestamp "openwrt" \
    > "$BUILD_DIR/openwrt/version.date"
