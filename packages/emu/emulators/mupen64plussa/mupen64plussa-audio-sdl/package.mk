# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mupen64plussa-audio-sdl"
PKG_VERSION="af6af5b1fd4fdb435c836be15371dd047f395c4d"
PKG_SHA256="265ccdd56736f9cb4144196ad6673d2728a8ebd1e7b9c4280a632c3a343be261"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/mupen64plus/mupen64plus-audio-sdl"
PKG_URL="https://github.com/mupen64plus/mupen64plus-audio-sdl/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plussa-core"
PKG_SHORTDESC="mupen64plus-audio-sdl"
PKG_LONGDESC="Mupen64Plus Standalone Audio SDL"
PKG_TOOLCHAIN="manual"

PKG_MAKE_OPTS_TARGET+="USE_GLES=1"

make_target() {
  export HOST_CPU=aarch64
  export APIDIR=$(get_install_dir mupen64plussa-core)/usr/local/include/mupen64plus
  export USE_GLES=1
  export SDL_CFLAGS="-I$SYSROOT_PREFIX/usr/include/SDL2 -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"
  export CROSS_COMPILE="$TARGET_PREFIX"
  export V=1
  export VC=0
  BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  make -C projects/unix clean
  make -C projects/unix all ${PKG_MAKE_OPTS_TARGET}
}

makeinstall_target() {
  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib
  UPLUGINDIR=${ULIBDIR}/mupen64plus
  mkdir -p ${UPLUGINDIR}
  cp ${PKG_BUILD}/projects/unix/mupen64plus-audio-sdl.so ${UPLUGINDIR}
  #$STRIP ${UPLUGINDIR}/mupen64plus-audio-sdl.so
  chmod 0644 ${UPLUGINDIR}/mupen64plus-audio-sdl.so
}

