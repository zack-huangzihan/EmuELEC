# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 0riginally created by Escalade (https://github.com/escalade)
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="python-evdev"
PKG_VERSION="5adc2abf1ec8a02c05c80cb1b3e34ba1d4237803"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/gvalkov/python-evdev"
PKG_URL="$PKG_SITE.git"
PKG_DEPENDS_TARGET="toolchain Python3:host Python3 distutilscross:host"
PKG_LONGDESC="Userspace evdev events"
PKG_TOOLCHAIN="manual"

pre_make_target() {
  export PYTHONXCPREFIX="${SYSROOT_PREFIX}/usr"
  export LDFLAGS="${LDFLAGS} -L${SYSROOT_PREFIX}/usr/lib -L${SYSROOT_PREFIX}/lib"
  export LDSHARED="${CC} -shared"
  find . -name setup.py -exec sed -i "s:/usr/include/linux/input.h :${SYSROOT_PREFIX}/usr/include/linux/input.h:g" \{} \;
  find . -name setup.py -exec sed -i "s:/usr/include/linux/input-event-codes.h :${SYSROOT_PREFIX}/usr/include/linux/input-event-codes.h:g" \{} \;
}

make_target() {
  python3 setup.py build_ext \
  build_ecodes --evdev-headers ${SYSROOT_PREFIX}/usr/include/linux/input.h:${SYSROOT_PREFIX}/usr/include/linux/input-event-codes.h \
  build_ext --include-dirs ${SYSROOT_PREFIX}/usr/include/
}

makeinstall_target() {
  python3 setup.py install --root=${INSTALL} --prefix=/usr
}

post_makeinstall_target() {

if [[ "$ARCH" == "arm" ]]; then
	libname="arm-linux-gnueabihf.so"
else
	libname="aarch64-linux-gnu.so"
fi

  # Seems like there's an issue in the build system.
  # C Modules get built using the correct target toolchain but the generated *.so
  # file names use the arch from the host system
  # tried to solve it but couldn't so I move them to the correct names for python
  # to grab them
  mv ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_ecodes.cpython-39-* \
    ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_ecodes.cpython-39-${libname}
  mv ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_input.cpython-39-* \
    ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_input.cpython-39-${libname}
  mv ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_uinput.cpython-39-* \
    ${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages/evdev/_uinput.cpython-39-${libname}
}
