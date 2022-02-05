{ name ? "linux", stdenv, fetchurl, gnumake, flex, gnubison }:

stdenv.mkDerivation {
  pname = name;
  version = "5.15";

  src = fetchurl {
    # local = /downloads/linux-5.15.tar.xz;
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.tar.xz";
    sha256 = "57b2cf6991910e3b67a1b3490022e8a0674b6965c74c12da1e99d138d1991ee8";
  };

  buildInputs = [
    gnumake
    flex gnubison
  ];

  patchPhase = ''
    sed -i 's|#!/usr/bin/awk|#!${stdenv.busybox}/bin/awk|' \
      scripts/*.sh scripts/*/*.sh
    sed -i 's|#!/bin/sh|#!${stdenv.busybox}/bin/ash|' \
      scripts/*.sh scripts/*/*.sh scripts/remove-stale-files
  '';

  configurePhase = ''
    export KBUILD_BUILD_TIMESTAMP=0
    export KBUILD_USER=zilch
    export KBUILD_HOST=zilchos.org
    make LLVM=1 allnoconfig
    make LLVM=1 kvm_guest.config
  '';

  buildPhase = ''
    make -j $NPROC CC=cc HOSTCC=cc ARCH=x86_64 headers
    mkdir -p extra-headers/asm
    cp ./usr/include/asm/types.h extra-headers/asm/

    HOSTCC="cc"
    HOSTCC="$HOSTCC -idirafter $(pwd)/include/uapi"
    HOSTCC="$HOSTCC -idirafter $(pwd)/arch/x86/include/uapi"
    HOSTCC="$HOSTCC -idirafter $(pwd)/extra-headers"

    export KBUILD_BUILD_TIMESTAMP=0
    export KBUILD_USER=zilch
    export KBUILD_HOST=zilchos.org

    make -j $NPROC "HOSTCC=$HOSTCC" LLVM=1
  '';

  installPhase = ''
    find|grep -i bzimage
    cat arch/x86/boot/bzImage > $out
  '';

  allowedRequisites = [ ];
  allowedReferences = [ ];
}
