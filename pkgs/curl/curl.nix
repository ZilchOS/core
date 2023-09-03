{ name ? "curl", stdenv, fetchurl, gnumake, mbedtls, ca-bundle }:

#> FETCH dd322f6bd0a20e6cebdfd388f69e98c3d183bed792cf4713c8a7ef498cba4894
#>  FROM https://curl.se/download/curl-8.2.1.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "8.2.1";

  src = fetchurl {
    # local = /downloads/curl-8.2.1.tar.xz;
    url = "https://curl.se/download/curl-8.2.1.tar.xz";
    sha256 = "dd322f6bd0a20e6cebdfd388f69e98c3d183bed792cf4713c8a7ef498cba4894";
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
