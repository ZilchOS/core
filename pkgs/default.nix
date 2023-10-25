{ bootstrap-musl, bootstrap-busybox, bootstrap-toolchain
, use-ccache ? false }:

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

          unpack() (tar --strip-components=1 -xf "$@")

          if [ -n "$NIX_BUILD_CORES" ] && [ "$NIX_BUILD_CORES" != 0 ]; then
              NPROC=$NIX_BUILD_CORES
          elif [ "$NIX_BUILD_CORES" == 0 ] && [ -r /proc/cpuinfo ]; then
              NPROC=$(grep -c processor /proc/cpuinfo)
          else
              NPROC=1
          fi
        '' + (if ! use-ccache then "" else ''
          . /ccache/setup ZilchOS/core/${name}
        '') + script
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
  # so they have to be built with a modular builder

  stdenv = (import ./stdenv) {
    inherit (lib) fetchurl mkCaDerivation makeOverridable;
    inherit bootstrap-busybox;  # a bit of a layering violation
    inherit (_bootstrap) early-clang early-gnumake;
    inherit (_bootstrap) early-linux-headers early-cmake early-python;
    inherit use-ccache;
  };  # -> .musl .clang .busybox

  # rest of the packages

  callPackage = path:
    lib.makeOverridable ((lib.mkCallPackage (pkgs // _lib)) path);

  pkgs = {
    inherit bootstrap-musl bootstrap-toolchain bootstrap-busybox;
    inherit (_bootstrap) early-gnumake early-linux-headers;
    inherit (_bootstrap) early-cmake early-python early-clang;
    inherit stdenv;
    inherit (stdenv) musl clang busybox;

    gnumake = callPackage ./gnumake.nix {
      gnumake = _bootstrap.early-gnumake;  # a bit of a layering violation
    };
    pkg-config = callPackage ./pkg-config.nix {};
    zstd = callPackage ./zstd.nix {};

    linux = callPackage ./linux/linux.nix {};
    gnum4 = callPackage ./linux/gnum4.nix {};
    flex = callPackage ./linux/flex.nix {};
    gnubison = callPackage ./linux/gnubison.nix {};

    curl = callPackage ./curl/curl.nix {};
    mbedtls = callPackage ./curl/mbedtls.nix {};
    ca-bundle = callPackage ./curl/ca-bundle.nix {};

    nix = callPackage ./nix/nix.nix {
      linux-headers = _bootstrap.early-linux-headers;
    };
    boost = callPackage ./nix/boost.nix {
      linux-headers = _bootstrap.early-linux-headers;
    };
    brotli = callPackage ./nix/brotli.nix {};
    sqlite = callPackage ./nix/sqlite.nix {};
    seccomp = callPackage ./nix/seccomp.nix {
      linux-headers = _bootstrap.early-linux-headers;
    };
    lowdown = callPackage ./nix/lowdown.nix {};
    nlohmann_json = callPackage ./nix/nlohmann_json.nix {};
    gnugperf = callPackage ./nix/gnugperf.nix {};
    editline = callPackage ./nix/editline.nix {};
    libsodium = callPackage ./nix/libsodium.nix {};
    libarchive = callPackage ./nix/libarchive.nix {};

    live-cd = callPackage ./live-cd/live-cd.nix {};
    nasm = callPackage ./live-cd/nasm.nix {};
    gnubinutils = callPackage ./live-cd/gnubinutils.nix {};
    gnumtools = callPackage ./live-cd/gnumtools.nix {};
    limine = callPackage ./live-cd/limine.nix {};
    gnuxorriso = callPackage ./live-cd/gnuxorriso.nix {
      linux-headers = _bootstrap.early-linux-headers;
    };
    dmidecode = callPackage ./live-cd/dmidecode.nix {};
  };

in pkgs
