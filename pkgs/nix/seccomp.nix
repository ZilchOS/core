{ name ? "seccomp", stdenv, fetchurl, gnumake, gnugperf, linux-headers }:

#> FETCH 59065c8733364725e9721ba48c3a99bbc52af921daf48df4b1e012fbc7b10a76
#>  FROM https://github.com/seccomp/libseccomp/releases/download/v2.5.3/libseccomp-2.5.3.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "2.5.3";

  src = fetchurl {
    # local = /downloads/libseccomp-2.5.3.tar.gz;
    url = "https://github.com/seccomp/libseccomp/releases/download/v2.5.3/libseccomp-2.5.3.tar.gz";
    sha256 = "59065c8733364725e9721ba48c3a99bbc52af921daf48df4b1e012fbc7b10a76";
  };

  buildInputs = [ gnumake gnugperf ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure build-aux/install-sh
  '';

  extraConfigureFlags = [ "CFLAGS='-I${linux-headers}/include'" ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
