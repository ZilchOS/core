{ name ? "sqlite", stdenv, fetchurl, gnumake }:

#> FETCH 49008dbf3afc04d4edc8ecfc34e4ead196973034293c997adad2f63f01762ae1
#>  FROM https://sqlite.org/2023/sqlite-autoconf-3430000.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "3430000";

  src = fetchurl {
    # local = /downloads/sqlite-autoconf-3430000.tar.gz;
    url = "https://www.sqlite.org/2023/sqlite-autoconf-3430000.tar.gz";
    sha256 = "49008dbf3afc04d4edc8ecfc34e4ead196973034293c997adad2f63f01762ae1";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
