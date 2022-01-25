{ name ? "patchelf", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "0.13";

  src = fetchurl {
    # local = /downloads/patchelf-0.13.tar.bz2;
    url = "https://github.com/NixOS/patchelf/releases/download/0.13/patchelf-0.13.tar.bz2";
    sha256 = "4c7ed4bcfc1a114d6286e4a0d3c1a90db147a4c3adda1814ee0eee0f9ee917ed";
  };

  buildInputs = [ gnumake ];

  patchPhase = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
            configure build-aux/install-sh
  '';

  extraBuildFlags = [ "CXXFLAGS='-O2 -Wl,-rpath ${stdenv.clang.sysroot}/lib'" ];

  allowedRequisites = [ "out" stdenv.clang.sysroot stdenv.musl ];
  allowedReferences = [ "out" stdenv.clang.sysroot stdenv.musl ];
}
