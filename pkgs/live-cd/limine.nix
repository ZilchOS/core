{ name ? "limine", stdenv, fetchurl, gnumake, nasm, gnubinutils, gnumtools }:

#> FETCH a4ca6c2f5ab3c56231be026d4b0e42bdf82ee9c18183fd07c0bba71b386775c0
#>  FROM https://github.com/limine-bootloader/limine/releases/download/v2.83/limine-2.83.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "2.83";

  src = fetchurl {
    # local = /downloads/limine-2.83.tar.gz;
    url = "https://github.com/limine-bootloader/limine/releases/download/v2.83/limine-2.83.tar.xz";
    sha256 = "a4ca6c2f5ab3c56231be026d4b0e42bdf82ee9c18183fd07c0bba71b386775c0";
  };

  buildInputs = [ gnumake nasm gnubinutils gnumtools ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure make_toolchain.sh common/gensyms.sh
    #sed -i 's|Free Software Foundation||' configure
  '';

  patches = [ ./limine.patch ];

  buildPhase = ''
    export SOURCE_DATE_EPOCH=0
    make -j $NPROC
 '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
