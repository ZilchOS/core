{ mkEarlyDerivation, bootstrap-musl, bootstrap-busybox, bootstrap-toolchain }:

rec {
  early-gnumake = (import ./gnumake.nix) {
    name = "early-gnumake";
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
  };

  early-linux-headers = (import ./linux-headers.nix) {
    name = "early-linux-headers";
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  early-cmake = (import ./cmake.nix) {
    name = "early-cmake";
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
  };

  early-python = (import ./python.nix) {
    name = "early-python";
    mkDerivation = mkEarlyDerivation;
    toolchain = bootstrap-toolchain;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  early-clang = (import ./clang.nix) {
    name = "early-clang";
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
