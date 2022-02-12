{ name ? "limine", stdenv, fetchurl, gnumake, nasm, gnubinutils, gnumtools }:

#> FETCH 256091d39bcce88de5cf9fd15c3be50f4270e9b78ed81916104b5573f0645406
#>  FROM https://github.com/limine-bootloader/limine/releases/download/v2.84.2/limine-2.84.2.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "2.84.2";

  src = fetchurl {
    # local = /downloads/limine-2.84.2.tar.gz;
    url = "https://github.com/limine-bootloader/limine/releases/download/v2.84.2/limine-2.84.2.tar.xz";
    sha256 = "256091d39bcce88de5cf9fd15c3be50f4270e9b78ed81916104b5573f0645406";
  };

  buildInputs = [ gnumake nasm gnubinutils gnumtools ];

  patches = [ ./limine.patch ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure make_toolchain.sh common/gensyms.sh limine-install/hgen.sh
    #sed -i 's|Free Software Foundation||' configure
  '';

  buildPhase = ''
    export SOURCE_DATE_EPOCH=0
    make
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
