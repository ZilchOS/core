{ name ? "editline", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "1.17.1";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/editline-1.17.1.tar.xz;
    url = "https://github.com/troglobit/editline/releases/download/1.17.1/editline-1.17.1.tar.xz";
    sha256 = "df223b3333a545fddbc67b49ded3d242c66fadf7a04beb3ada20957fcd1ffc0e";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure aux/install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
