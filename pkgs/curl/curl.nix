{ name ? "curl", stdenv, fetchurl, gnumake, mbedtls, ca-bundle }:

#> FETCH a067b688d1645183febc31309ec1f3cdce9213d02136b6a6de3d50f69c95a7d3
#>  FROM https://curl.se/download/curl-7.81.0.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "7.81.0";

  src = fetchurl {
    # local = /downloads/curl-7.81.0.tar.xz;
    url = "https://curl.se/download/curl-7.81.0.tar.xz";
    sha256 = "a067b688d1645183febc31309ec1f3cdce9213d02136b6a6de3d50f69c95a7d3";
  };

  buildInputs = [ gnumake mbedtls ca-bundle ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure install-sh
  '';

  extraConfigureFlags = [
    "--with-mbedtls=${mbedtls}"
    "--with-ca-bundle=${ca-bundle}"
    "LDFLAGS='-L${mbedtls}/lib -Wl,-R${mbedtls}/lib'"
  ];

  passthru = { inherit ca-bundle mbedtls; };

  allowedRequisites = [ "out" stdenv.musl mbedtls ca-bundle ];
  allowedReferences = [ "out" stdenv.musl mbedtls ca-bundle ];
}
