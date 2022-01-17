{ name ? "linux-headers", fetchurl, mkDerivation, toolchain, busybox, gnumake }:

let
  source-tarball-linux = fetchurl {
    # local = /downloads/linux-5.15.tar.xz;
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.tar.xz";
    sha256 = "57b2cf6991910e3b67a1b3490022e8a0674b6965c74c12da1e99d138d1991ee8";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ toolchain busybox gnumake ];
    script = ''
      # unpack:
        unpack ${source-tarball-linux} \
          linux-5.15/Makefile \
          linux-5.15/arch/x86 \
          linux-5.15/include \
          linux-5.15/scripts \
          linux-5.15/tools
      # build:
        make -j $NPROC \
          CONFIG_SHELL=${busybox}/bin/ash \
          CC=cc HOSTCC=cc ARCH=x86_64 \
          headers
      # install:
        find usr/include -name '.*' | xargs rm
        mkdir -p $out
        cp -rv usr/include $out/
    '';
  }
