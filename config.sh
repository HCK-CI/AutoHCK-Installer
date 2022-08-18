#!/bin/bash

set -e

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bootstrap="${work_dir}/bootstrap"

source "${bootstrap}"

jq -n \
    --arg tools_hck "${TOOLSHCK_DIR}/toolsHCK.ps1" \
    --arg hlk_setup_scripts "${HLK_SETUP_SCRIPTS_DIR}" \
    --arg extra_software "${EXTRA_SOFTWARE_DIR}" \
    --arg playlists_path "${HLK_PLAYLISTS_DIR}" \
    --arg filters_path "${HCK_FILTERS_DIR}/UpdateFilters.sql" \
    --arg qemu_bin "${QEMU_BIN}" \
    --arg qemu_img_bin "${QEMU_IMG_BIN}" \
    --arg ivshmem_server_bin "${IVSHMEM_SERVER_BIN}" \
    --arg fs_daemon_bin "${FS_DAEMON_BIN}" \
    --arg fs_daemon_share_path "${WORKSPACE_PATH}/fs_share" \
    --arg images_path "${IMAGES_PATH}" \
    --arg fs_test_image "${IMAGES_PATH}/fs_test_image.qcow2" \
    --arg iso_path "${ISO_PATH}" \
    --arg workspace_path "${WORKSPACE_PATH}" \
    '{
        "config.json": {
          "iso_path": $iso_path,
          "extra_software": $extra_software,
          "workspace_path": $workspace_path,
          "toolshck_path": $tools_hck,
        },
        "lib/engines/hckinstall/hckinstall.json": {
          "hck_setup_scripts_path": $hlk_setup_scripts,
        },
        "lib/engines/hcktest/hcktest.json": {
          "playlists_path": $playlists_path,
          "filters_path": $filters_path
        },
        "lib/setupmanagers/qemuhck/qemu_machine.json": {
            "qemu_bin": $qemu_bin,
            "qemu_img_bin": $qemu_img_bin,
            "ivshmem_server_bin": $ivshmem_server_bin,
            "fs_daemon_bin": $fs_daemon_bin,
            "fs_daemon_share_path": $fs_daemon_share_path,
            "images_path": $images_path,
            "fs_test_image": $fs_test_image,
        }
     }'
