{ pname ? "busybox", fetchurl, stdenv, gnumake, linux-headers }:

stdenv.mkDerivation rec {
  inherit pname;
  version = "1.34.1";

  src = fetchurl {
    # local = /downloads/busybox-1.34.1.tar.bz2;
    url = "https://busybox.net/downloads/busybox-1.34.1.tar.bz2";
    sha256 = "415fbd89e5344c96acf449d94a6f956dbed62e18e835fc83e064db33a34bd549";
  };

  buildInputs = [ stdenv.clang stdenv.busybox gnumake ];

  prePatch = ''
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
    "CFLAGS=-I${linux-headers}/include"
    # FIXME: -O2 crashes busybox on initialization,
    # hasn't manifested itself before before we shadowed -O2
    "KCONFIG_NOTIMESTAMP=y"
  ];

  configurePhase = ''
    export PATH="$(pwd)/aliases:$PATH"
    make ${builtins.toString extraBuildFlags} defconfig
    sed -i 's|CONFIG_INSTALL_NO_USR=y|CONFIG_INSTALL_NO_USR=n|' .config
  '';

  buildPhase = ''
    make -j $NPROC ${builtins.toString extraBuildFlags} busybox.links busybox
  '';

  installPhase = ''
    sed -i -e 's|^/usr/s\?bin/|/bin/|' -e 's|^/sbin/|/bin/|' busybox.links
    make ${builtins.toString extraBuildFlags} install CONFIG_PREFIX=$out
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
