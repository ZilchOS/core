{ name ? "seccomp", stdenv, fetchurl, gnumake, gnugperf, linux-headers }:

#> FETCH d82902400405cf0068574ef3dc1fe5f5926207543ba1ae6f8e7a1576351dcbdb
#>  FROM https://github.com/seccomp/libseccomp/releases/download/v2.5.4/libseccomp-2.5.4.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "2.5.4";

  src = fetchurl {
    # local = /downloads/libseccomp-2.5.4.tar.gz;
    url = "https://github.com/seccomp/libseccomp/releases/download/v2.5.4/libseccomp-2.5.4.tar.gz";
    sha256 = "d82902400405cf0068574ef3dc1fe5f5926207543ba1ae6f8e7a1576351dcbdb";
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
