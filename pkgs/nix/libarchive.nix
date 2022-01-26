{ name ? "libarchive", stdenv, fetchurl, gnumake }:

#> FETCH f0b19ff39c3c9a5898a219497ababbadab99d8178acc980155c7e1271089b5a0
#>  FROM https://libarchive.org/downloads/libarchive-3.5.2.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "3.5.2";

  src = fetchurl {
    # local = /downloads/libarchive-3.5.2.tar.xz;
    url = "https://libarchive.org/downloads/libarchive-3.5.2.tar.xz";
    sha256 = "f0b19ff39c3c9a5898a219497ababbadab99d8178acc980155c7e1271089b5a0";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
	configure build/autoconf/install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
