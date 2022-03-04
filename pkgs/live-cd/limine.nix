{ name ? "limine", stdenv, fetchurl, gnumake, nasm, gnubinutils, gnumtools }:

#> FETCH 271451ff3659960f2f326b8b63e7d9eaa97e425a8e215cddf03ed02a78c68f22
#>  FROM https://github.com/limine-bootloader/limine/releases/download/v2.86/limine-2.86.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "2.86";

  src = fetchurl {
    # local = /downloads/limine-2.86.tar.xz;
    url = "https://github.com/limine-bootloader/limine/releases/download/v2.86/limine-2.86.tar.xz";
    sha256 = "271451ff3659960f2f326b8b63e7d9eaa97e425a8e215cddf03ed02a78c68f22";
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
