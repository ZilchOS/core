# TODO: try heirloom
{ name ? "gnubison", stdenv, fetchurl, gnumake, gnum4 }:

#> FETCH 9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2
#>  FROM https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "3.8.2";

  src = fetchurl {
    # local = /downloads/bison-3.8.2.tar.xz;
    url = "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz";
    sha256 = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2";
  };

  buildInputs = [ gnumake gnum4 ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure build-aux/install-sh build-aux/move-if-change
  '';
  extraConfigureFlags = [ "--disable-dependency-tracking" ];

  allowedRequisites = [ "out" stdenv.musl stdenv.busybox gnum4 ];
  allowedReferences = [ "out" stdenv.musl stdenv.busybox gnum4 ];
}
