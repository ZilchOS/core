{ name ? "libsodium", stdenv, fetchurl, gnumake }:

#> FETCH 6f504490b342a4f8a4c4a02fc9b866cbef8622d5df4e5452b46be121e46636c1
#>  FROM https://github.com/jedisct1/libsodium/releases/download/1.0.18-RELEASE/libsodium-1.0.18.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.0.18";

  src = fetchurl {
    # local = /downloads/libsodium-1.0.18.tar.gz;
    url = "https://github.com/jedisct1/libsodium/releases/download/1.0.18-RELEASE/libsodium-1.0.18.tar.gz";
    sha256 = "6f504490b342a4f8a4c4a02fc9b866cbef8622d5df4e5452b46be121e46636c1";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure build-aux/install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
