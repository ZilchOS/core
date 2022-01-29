{ fetchurl, mkCaDerivation
, makeOverridable
, bootstrap-busybox
, early-clang, early-gnumake, early-linux-headers, early-cmake, early-python
, use-ccache }:

let
  modularBuilder = (import ./_modularBuilder.nix) use-ccache;

  musl = (makeOverridable (import ./musl.nix)) {
    inherit fetchurl;
    stdenv = modularBuilder {
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
    stdenv = modularBuilder {
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
    stdenv = modularBuilder {
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
    stdenv = modularBuilder {
      envname = "preenv4";
      inherit mkCaDerivation;
      inherit musl clang busybox;
      patchelf = null;
    };
    gnumake = early-gnumake;
  };

in
  (makeOverridable modularBuilder) {
    inherit mkCaDerivation musl clang busybox patchelf;
  }
