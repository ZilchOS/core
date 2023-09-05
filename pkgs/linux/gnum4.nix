# TODO: try heirloom
{ name ? "gnum4", stdenv, fetchurl, gnumake }:

#> FETCH 63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96
#>  FROM https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "1.4.19";

  src = fetchurl {
    # local = /downloads/m4-1.4.19.tar.xz;
    url = "https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz";
    sha256 = "63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure build-aux/install-sh
  '';
  extraConfigureFlags = [
    "--disable-dependency-tracking"
    "--with-syscmd-shell=${stdenv.busybox}/bin/ash"
  ];

  allowedRequisites = [ "out" stdenv.musl stdenv.busybox ];
  allowedReferences = [ "out" stdenv.musl stdenv.busybox ];
}
