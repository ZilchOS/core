{ name ? "linux", stdenv, fetchurl, gnumake, flex, gnubison, zstd }:

stdenv.mkDerivation {
  pname = name;
  version = "5.15";

  src = fetchurl {
    # local = /downloads/linux-5.15.tar.xz;
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.tar.xz";
    sha256 = "57b2cf6991910e3b67a1b3490022e8a0674b6965c74c12da1e99d138d1991ee8";
  };

  outputs = [ "kernel" "config" ];

  buildInputs = [ gnumake flex gnubison zstd ];

  prePatch = ''
    sed -i 's|#!/usr/bin/awk|#!${stdenv.busybox}/bin/awk|' \
      scripts/*.sh scripts/*/*.sh
    sed -i 's|#!/bin/sh|#!${stdenv.busybox}/bin/ash|' \
      scripts/*.sh scripts/*/*.sh scripts/remove-stale-files
  '';

  patches = [ ./linux-no-objtool.patch ];

  configurePhase = ''
    ./scripts/kconfig/merge_config.sh -n -m \
      arch/x86/configs/tiny.config \
      kernel/configs/kvm_guest.config \
      ${./config}
    make LLVM=1 KCONFIG_ALLCONFIG=.config allnoconfig
    cat .config
  '';

  buildPhase = ''
    make -j $NPROC CC=cc HOSTCC=cc ARCH=x86_64 headers
    mkdir -p extra-headers/asm
    cp ./usr/include/asm/types.h extra-headers/asm/

    HOSTCC="cc"
    HOSTCC="$HOSTCC -idirafter $(pwd)/include/uapi"
    HOSTCC="$HOSTCC -idirafter $(pwd)/arch/x86/include/uapi"
    HOSTCC="$HOSTCC -idirafter $(pwd)/extra-headers"

    make -j $NPROC "HOSTCC=$HOSTCC" LLVM=1 \
      KBUILD_BUILD_USER=zilch \
      KBUILD_BUILD_HOST=zilchos.org \
      KBUILD_BUILD_TIMESTAMP=1970-01-01
  '';

  installPhase = ''
    find|grep -i bzimage
    cat arch/x86/boot/bzImage > $kernel
    cat .config > $config
  '';

  allowedRequisites = [ ];
  allowedReferences = [ ];
}
