{ pname ? "busybox", fetchurl, stdenv, gnumake, linux-headers }:

stdenv.mkDerivation rec {
  inherit pname;
  version = "1.36.1";

  src = fetchurl {
    # local = /downloads/busybox-1.36.1.tar.bz2;
    url = "https://busybox.net/downloads/busybox-1.36.1.tar.bz2";
    sha256 = "b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314";
  };

  buildInputs = [ stdenv.clang stdenv.busybox gnumake ];

  postPatch = ''
    echo -e '#!${stdenv.busybox}/bin/ash\nprintf 9999' \
      > scripts/gcc-version.sh
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|g' \
      scripts/gen_build_files.sh \
      scripts/mkconfigs scripts/embedded_scripts scripts/trylink \
      scripts/generate_BUFSIZ.sh \
      applets/usage_compressed applets/busybox.mkscripts applets/install.sh
  '';

  extraBuildFlags = [
    "CONFIG_SHELL=${stdenv.busybox}/bin/ash"
    "CC=cc"
    "HOSTCC=cc"
    "CFLAGS='-I${linux-headers}/include -O2'"
    "KCONFIG_NOTIMESTAMP=y"
  ];

  configurePhase = ''
    export PATH="$(pwd)/aliases:$PATH"
    make ${builtins.toString extraBuildFlags} defconfig
    sed -i 's|CONFIG_INSTALL_NO_USR=y|CONFIG_INSTALL_NO_USR=n|' .config
    sed -i 's|FEATURE_COMPRESS_USAGE=y|FEATURE_COMPRESS_USAGE=n|' .config
    DHCP_SCRIPT=CONFIG_UDHCPC_DEFAULT_SCRIPT
    sed -i "s|#!/bin/sh|#!$out/bin/ash\nPATH=\"\$PATH:$out/bin\"|" \
      examples/udhcp/simple.script
    sed -i "s|$DHCP_SCRIPT=.*|$DHCP_SCRIPT=\"$out/udhcpc.script\"|" .config
  '';

  buildPhase = ''
    make -j $NPROC ${builtins.toString extraBuildFlags} busybox.links busybox
  '';

  installPhase = ''
    sed -i -e 's|^/usr/s\?bin/|/bin/|' -e 's|^/sbin/|/bin/|' busybox.links
    make ${builtins.toString extraBuildFlags} install CONFIG_PREFIX=$out
    cp examples/udhcp/simple.script $out/udhcpc.script
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
