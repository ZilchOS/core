{ name ? "gnumtools", stdenv, fetchurl, gnumake }:

#> FETCH 541e179665dc4e272b9602f2074243591a157da89cc47064da8c5829dbd2b339
#>  FROM http://ftp.gnu.org/gnu/mtools/mtools-4.0.47.tar.bz2

stdenv.mkDerivation {
  pname = name;
  version = "4.0.43";

  src = fetchurl {
    # local = /downloads/mtools-4.0.43.tar.bz2;
    url = "http://ftp.gnu.org/gnu/mtools/mtools-4.0.43.tar.bz2";
    sha256 = "541e179665dc4e272b9602f2074243591a157da89cc47064da8c5829dbd2b339";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure mkinstalldirs
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
