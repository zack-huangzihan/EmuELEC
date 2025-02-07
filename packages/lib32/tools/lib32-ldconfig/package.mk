# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-ldconfig"
PKG_VERSION="1"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://www.gnu.org/software/libc/"
PKG_URL=""
PKG_DEPENDS_TARGET="glibc"
PKG_LONGDESC="ldconfig binary and service"
PKG_NEED_UNPACK+=" $(get_pkg_directory glibc)"
PKG_TOOLCHAIN="manual"

make_target() {
  # Nah, we don't build it, just steal it from glibc
  cp "$(get_build_dir glibc)/.${TARGET_NAME}/elf/ldconfig" ${PKG_BUILD}/ldconfig
  ${TARGET_PREFIX}strip ${PKG_BUILD}/ldconfig
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -ra ${PKG_BUILD}/ldconfig ${INSTALL}/usr/bin/
  if [ "${PROJECT}" = "Rockchip" ]; then
    mkdir -p ${INSTALL}/etc/profile.d
    # Temporary workaround for faulty libmali until we understand why it is not searched correctly
    echo 'export LD_LIBRARY_PATH="/emuelec/lib32:/usr/lib32:$LD_LIBRARY_PATH"' > ${INSTALL}/etc/profile.d/99-rk-mali-workaround.conf
  fi
}

post_install() {
  enable_service ldconfig-boot.service
  enable_service ldconfig-watch.path
}