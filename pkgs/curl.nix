{ name ? "curl", stdenv, fetchurl, gnumake, mbedtls, pkg-config }:

#> FETCH a132bd93188b938771135ac7c1f3ac1d3ce507c1fcbef8c471397639214ae2ab
#>  FROM https://curl.se/download/curl-7.80.0.tar.xz

let
  curl-src = fetchurl {
    # local = /downloads/curl-7.80.0.tar.xz;
    url = "https://curl.se/download/curl-7.80.0.tar.xz";
    sha256 = "a132bd93188b938771135ac7c1f3ac1d3ce507c1fcbef8c471397639214ae2ab";
  };
  ca-certificates = fetchurl {
    # local = /downloads/cacert-2021-10-26.pem";
    url = "https://curl.se/ca/cacert-2021-10-26.pem";
    sha256 = "ae31ecb3c6e9ff3154cb7a55f017090448f88482f0e94ac927c0c67a1f33b9cf";
  };
in
  stdenv.mkDerivation {
    pname = name;
    version = "7.80.0";

    src = curl-src;

    buildInputs = [ gnumake mbedtls pkg-config ];

    prePatch = ''
      sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
        configure install-sh
    '';

    extraConfigureFlags = [
      "--with-mbedtls=${mbedtls}"
      "--with-ca-bundle=${ca-certificates}"
      "LDFLAGS='-L${mbedtls}/lib -Wl,-R${mbedtls}/lib'"
    ];

    passthru = {ca-certificates = ca-certificates;};

    allowedRequisites = [ "out" stdenv.musl mbedtls ];
    allowedReferences = [ "out" stdenv.musl mbedtls ];
  }
