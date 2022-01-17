{ fetchurl, mkEarlyDerivation
, bootstrap-musl, bootstrap-busybox, bootstrap-toolchain }:

rec {
  early-gnumake = (import ./gnumake.nix) {
    name = "early-gnumake";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
  };

  early-linux-headers = (import ./linux-headers.nix) {
    name = "early-linux-headers";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  early-cmake = (import ./cmake.nix) {
    name = "early-cmake";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
  };

  early-python = (import ./python.nix) {
    name = "early-python";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  early-clang = (import ./clang.nix) {
    name = "early-clang";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    musl = bootstrap-musl;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
    cmake = early-cmake;
    python = early-python;
  };
}
