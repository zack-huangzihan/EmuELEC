# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Team CoreELEC (https://coreelec.org)

PKG_NAME="SDL2_mixer"
PKG_VERSION="2.0.4"
PKG_SHA256=""
PKG_LICENSE="GPLv3"
PKG_SITE="http://www.libsdl.org/projects/SDL_mixer/release"
PKG_URL="$PKG_SITE/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib SDL2 mpg123-compat libvorbis libvorbisidec libogg opusfile libmodplug flac"
PKG_LONGDESC="SDL_mixer 2.0.1"
PKG_DEPENDS_HOST="toolchain:host SDL2:host"

pre_configure_target() {

  PKG_CONFIGURE_OPTS_TARGET="--disable-sdltest \
							 --disable-music-midi-fluidsynth \
							 --enable-music-flac \
							 --enable-music-mod-modplug \
							 --enable-music-ogg-tremor \
							 --enable-music-ogg \
							 --enable-music-mp3"
}
