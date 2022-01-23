{ bootstrap-musl, bootstrap-busybox, bootstrap-toolchain }:

let
  lib = (import ../lib);

  # more helper functions (of a less generic nature)

  defaultBuilder = "${bootstrap-busybox}/bin/ash";
  mkEarlyDerivation =
    {name, script, buildInputs, builder ? defaultBuilder, extra ? {}}:
    lib.mkCaDerivation {
      inherit name builder;
      args = [ "-uexc" (
        ''
          export PATH=${builtins.concatStringsSep ":" (
            map (x: "${x}/bin") buildInputs
          )}

          # for building as part of bootstrap-from-tcc with USE_CCACHE=1
          if [ -e /ccache/setup ]; then . /ccache/setup ZilchOS/Core/${name}; fi

          unpack() (tar --strip-components=1 -xf "$@")

          if [ -n "$NIX_BUILD_CORES" ] && [ "$NIX_BUILD_CORES" != 0 ]; then
              NPROC=$NIX_BUILD_CORES
          elif [ "$NIX_BUILD_CORES" == 0 ] && [ -r /proc/cpuinfo ]; then
              NPROC=$(grep -c processor /proc/cpuinfo)
          else
              NPROC=1
          fi
        '' + script
      ) ];
    } // extra;

  _lib = {  # funcs that'll be available in addition to pkgs when callPackage'd
    inherit (lib) fetchurl mkCaDerivation;
  };

  # early packages, not exposed to the users

  _bootstrap = (import ./_bootstrap) {
    inherit mkEarlyDerivation;
    inherit (lib) fetchurl;
    inherit bootstrap-musl bootstrap-busybox bootstrap-toolchain;
  };  # -> .early-{gnumake,linux-headers,cmake,python,clang}

  # stdenv packages, now this is public interface territory already

  stdenv = (import ./stdenv) {
    inherit mkEarlyDerivation;
    inherit (lib) fetchurl mkCaDerivation makeOverridable;
    inherit bootstrap-busybox;  # a bit of a layering violation
    inherit (_bootstrap) early-clang early-gnumake;
    inherit (_bootstrap) early-linux-headers early-cmake early-python;
  };  # -> .musl .clang .busybox

  # rest of the packages

  callPackage = path:
    lib.makeOverridable ((lib.mkCallPackage (pkgs // _lib)) path);

  pkgs = {
    inherit stdenv;
    inherit (stdenv) musl clang busybox;

    gnumake = callPackage ./gnumake.nix {
      gnumake = _bootstrap.early-gnumake;  # a bit of a layering violation
    };
  };

in pkgs
