{ name ? "linux-headers", fetchurl, mkDerivation, toolchain, busybox, gnumake }:

let
  source-tarball-linux = fetchurl {
    # local = /downloads/linux-6.4.12.tar.xz;
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.4.12.tar.xz";
    sha256 = "cca91be956fe081f8f6da72034cded96fe35a50be4bfb7e103e354aa2159a674";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ toolchain busybox gnumake ];
    script = ''
      # unpack:
        unpack ${source-tarball-linux} \
          linux-6.4.12/Makefile \
          linux-6.4.12/arch/x86 \
          linux-6.4.12/include \
          linux-6.4.12/scripts \
          linux-6.4.12/tools
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
