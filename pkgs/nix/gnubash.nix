{ name ? "gnubash", stdenv, fetchurl, gnumake }:

#> FETCH 13720965b5f4fc3a0d4b61dd37e7565c741da9a5be24edc2ae00182fc1b3588c
#>  FROM https://ftp.gnu.org/gnu/bash/bash-5.2.15.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "5.2.15";

  src = fetchurl {
    # local = /downloads/bash-5.2.15.tar.gz;
    url = "https://ftp.gnu.org/gnu/bash/bash-5.2.15.tar.gz";
    sha256 = "13720965b5f4fc3a0d4b61dd37e7565c741da9a5be24edc2ae00182fc1b3588c";
  };

  buildInputs = [ gnumake ];

  postPatch = "sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure";
  extraConfigureFlags = [
    "--without-bash-malloc"
    "CFLAGS=-Wno-implicit-function-declaration"
  ];

  # TODO: why so many
  allowedRequisites = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox];
  allowedReferences = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox];
}
