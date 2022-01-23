{ fetchurl, mkCaDerivation, mkEarlyDerivation
, makeOverridable
, bootstrap-busybox
, early-clang, early-gnumake, early-linux-headers, early-cmake, early-python }:

let
  musl = (makeOverridable (import ./musl.nix)) {
    name = "musl";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    toolchain = early-clang;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
  };

  clang = (makeOverridable (import ./clang.nix)) {
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

  busybox = (makeOverridable (import ./busybox.nix)) {
    name = "busybox";
    inherit fetchurl;
    mkDerivation = mkEarlyDerivation;
    musl = musl;
    toolchain = clang;
    busybox = bootstrap-busybox;
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
  };
in
  (makeOverridable (import ./stdenv.nix)) {
    inherit mkCaDerivation musl clang busybox;
  }
