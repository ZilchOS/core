{ name ? "gnumtools", stdenv, fetchurl, gnumake }:

#> FETCH 0hl3zbj0lyx2m0fyydv0wcgpmyqfg4khp098jqjn2yz44dz1k6vr
#>  FROM http://ftp.gnu.org/gnu/mtools/mtools-4.0.37.tar.bz2

stdenv.mkDerivation {
  pname = name;
  version = "4.0.37";

  src = fetchurl {
    # local = /downloads/mtools-4.0.37.tar.bz2;
    url = "http://ftp.gnu.org/gnu/mtools/mtools-4.0.37.tar.bz2";
    sha256 = "0hl3zbj0lyx2m0fyydv0wcgpmyqfg4khp098jqjn2yz44dz1k6vr";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure mkinstalldirs
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
