{ name ? "mbedtls", stdenv, fetchurl, gnumake }:

#> FETCH 6519579b836ed78cc549375c7c18b111df5717e86ca0eeff4cb64b2674f424cc
#>  FROM https://github.com/ARMmbed/mbedtls/archive/refs/tags/v2.28.0.tar.gz
#>    AS mbedtls-2.28.0.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "2.28.0";  # curl doesn't seem to be ready for 3.0/3.1 as of 7.81

  src = fetchurl {
    # local = /downloads/mbedtls-2.28.0.tar.gz;
    url = "https://github.com/ARMmbed/mbedtls/archive/refs/tags/v2.28.0.tar.gz";
    sha256 = "6519579b836ed78cc549375c7c18b111df5717e86ca0eeff4cb64b2674f424cc";
  };

  buildInputs = [ gnumake ];

  # mbedtls Makefile way already is barebones, but here we are outdoing it
  configurePhase = ''
    sed -i "s|^DESTDIR=.*|DESTDIR=$out|" Makefile
  '';
  extraBuildFlags = [ "SHARED=1" "-Clibrary" "libmbedtls.so" ];
  installPhase = ''
    mkdir -p $out/include $out/lib
    cp -rv include/mbedtls $out/include/
    cp -dv library/*.so* $out/lib/
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
