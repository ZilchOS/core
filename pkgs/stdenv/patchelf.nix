{ name ? "patchelf", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "0.18.0";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/patchelf-0.18.0.tar.bz2;
    url = "https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0.tar.bz2";
    sha256 = "1952b2a782ba576279c211ee942e341748fdb44997f704dd53def46cd055470b";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure build-aux/install-sh
  '';

  extraBuildFlags = [ "CXXFLAGS='-O2 -Wl,-rpath ${stdenv.clang.sysroot}/lib'" ];

  allowedRequisites = [ "out" stdenv.clang.sysroot stdenv.musl ];
  allowedReferences = [ "out" stdenv.clang.sysroot stdenv.musl ];
}
