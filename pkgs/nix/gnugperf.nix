{ name ? "gnugperf", stdenv, fetchurl, gnumake }:

#> FETCH 588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2
#>  FROM http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "3.1";

  src = fetchurl {
    # local = /downloads/gperf-3.1.tar.gz;
    url = "http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz";
    sha256 = "588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure lib/configure src/configure tests/configure doc/configure \
      Makefile.in src/Makefile.in doc/Makefile.in
  '';

  extraConfigureFlags = [ "CXXFLAGS=-Wno-register" ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
