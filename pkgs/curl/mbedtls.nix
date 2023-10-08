{ name ? "mbedtls", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "3.4.1";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/mbedtls-3.4.1.tar.gz;
    url = "https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v3.4.1.tar.gz";
    sha256 = "a420fcf7103e54e775c383e3751729b8fb2dcd087f6165befd13f28315f754f5";
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
    cp -rv include/psa $out/include/
    cp -dv library/*.so* $out/lib/
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
