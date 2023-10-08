{ name ? "limine", stdenv, fetchurl, gnumake, nasm, gnubinutils, gnumtools }:

stdenv.mkDerivation {
  pname = name;
  version = "5.20230830.0";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/limine-5.20230830.0.tar.xz;
    url = "https://github.com/limine-bootloader/limine/releases/download/v5.20230830.0/limine-5.20230830.0.tar.xz";
    sha256 = "ddd417f9caab3ef0f3031b938815a5c33367c3a50c09830138d208bd3126c98f";
  };

  patches = [ ./limine.patch ];

  buildInputs = [ gnumake nasm gnubinutils gnumtools ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure libgcc-binaries/make_toolchain.sh common/gensyms.sh \
      host/hgen.sh build-aux/install-sh freestanding-toolchain
    sed -i 's|-F dwarf -g||' common/GNUmakefile
    sed -i '/^    -g \\$/d' common/GNUmakefile
    sed -i 's|-g -O2 -pipe|-O2 -pipe|' host/Makefile
  '';

  extraConfigureFlags = [
    "CC_FOR_TARGET=cc"
    "LD_FOR_TARGET=ld"
    "CFLAGS='-O2 -pipe'"
    "CFLAGS_FOR_TARGET='-O2 -pipe'"
    "--enable-bios"
    "--enable-bios-cd"
    "--enable-uefi-cd"
  ];

  extraBuildFlags = [
    "CCACHE_DISABLE=1"  # -MMD outputs don't match otherwise
    "SOURCE_DATE_EPOCH=0"
  ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
