{ fetchurl, mkCaDerivation
, makeOverridable
, bootstrap-busybox
, early-clang, early-gnumake, early-linux-headers, early-cmake, early-python }:

let
  musl = (makeOverridable (import ./musl.nix)) {
    inherit fetchurl;
    stdenv = (import ./_modularBuilder.nix) {
      envname = "preenv1";
      inherit mkCaDerivation;
      musl = null;
      clang = early-clang;
      busybox = bootstrap-busybox;
      patchelf = null;
    };
    gnumake = early-gnumake;
  };

  clang = (makeOverridable (import ./clang.nix)) {
    inherit fetchurl;
    stdenv = (import ./_modularBuilder.nix) {
      envname = "preenv2";
      inherit mkCaDerivation;
      inherit musl;
      clang = early-clang;
      busybox = bootstrap-busybox;
      patchelf = null;
    };
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
    cmake = early-cmake;
    python = early-python;
  };

  busybox = (makeOverridable (import ./busybox.nix)) {
    inherit fetchurl;
    stdenv = (import ./_modularBuilder.nix) {
      envname = "preenv3";
      inherit mkCaDerivation;
      inherit musl clang;
      busybox = bootstrap-busybox;
      patchelf = null;
    };
    gnumake = early-gnumake;
    linux-headers = early-linux-headers;
  };

  patchelf = (makeOverridable (import ./patchelf.nix)) {
    inherit fetchurl;
    stdenv = (import ./_modularBuilder.nix) {
      envname = "preenv4";
      inherit mkCaDerivation;
      inherit musl clang busybox;
      patchelf = null;
    };
    gnumake = early-gnumake;
  };

in
  (makeOverridable (import ./_modularBuilder.nix)) {
    inherit mkCaDerivation musl clang busybox patchelf;
  }
