#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

LOCAL_CONFIG="/storage/.local/share"
CONFIG_DIR="/emuelec/configs/duckstation"

mkdir -p "${LOCAL_CONFIG}"

if [ ! -d "${CONFIG_DIR}" ]; then
    mkdir -p "${CONFIG_DIR}"
	cp -rf "/usr/config/emuelec/configs/duckstation/*" "${CONFIG_DIR}"
fi

if [ -d "${LOCAL_CONFIG}/duckstation" ]; then
	rm -rf "${LOCAL_CONFIG}"
fi

if [ ! -L "${LOCAL_CONFIG}/duckstation" ]; then
    ln -sf "${CONFIG_DIR}" "${LOCAL_CONFIG}/duckstation"
fi

if [[ "${1}" == *"duckstation_gui.pbp"* ]]; then
    duckstation-nogui -fullscreen
else
    duckstation-nogui -fullscreen -settings "${CONFIG_DIR}/settings.ini" -- "${1}" > /dev/null 2>&1
fi
