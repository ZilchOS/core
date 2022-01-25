{ name ? "mbedtls", stdenv, fetchurl, gnumake }:

#> FETCH 525bfde06e024c1218047dee1c8b4c89312df1a4b5658711009086cda5dfaa55
#>  FROM https://github.com/ARMmbed/mbedtls/archive/refs/tags/v3.0.0.tar.gz
#>    AS mbedtls-3.0.0.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "3.0.0";

  src = fetchurl {
    # local = /downloads/mbedtls-3.0.0.tar.gz;
    url = "https://github.com/ARMmbed/mbedtls/archive/refs/tags/v3.0.0.tar.gz";
    sha256 = "525bfde06e024c1218047dee1c8b4c89312df1a4b5658711009086cda5dfaa55";
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
