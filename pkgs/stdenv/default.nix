{ fetchurl, mkEarlyDerivation
, bootstrap-busybox
, early-clang, early-gnumake, early-linux-headers, early-cmake, early-python }:

rec {
  musl = (import ./musl.nix) {
    name = "musl";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = early-clang;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  clang = (import ./clang.nix) {
    name = "clang";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    early-clang = early-clang;
    busybox = bootstrap-busybox;
    musl = musl;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
    cmake = early-cmake;
    python = early-python;
  };

  busybox = (import ./busybox.nix) {
    name = "busybox";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    musl = musl;
    toolchain = clang;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
  };
}
