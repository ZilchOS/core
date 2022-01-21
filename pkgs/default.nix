{ bootstrap-musl, bootstrap-busybox, bootstrap-toolchain }:

let
  fetchurl = { url, sha256 }: derivation {
    builder = "builtin:fetchurl"; system = "builtin"; preferLocalBuild = true;
    outputHashMode = "flat"; outputHashAlgo = "sha256"; outputHash = sha256;

    name = builtins.baseNameOf url;
    inherit url; urls = [ url ];
    unpack = false;
  };

  mkCaDerivation = args: derivation (args // {
    system = "x86_64-linux";
    __contentAddressed = true;
    outputHashAlgo = "sha256"; outputHashMode = "recursive";
  });

  defaultBuilder = "${bootstrap-busybox}/bin/ash";
  mkEarlyDerivation =
    {name, script, buildInputs, builder ? defaultBuilder, extra ? {}}:
    mkCaDerivation {
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

  _bootstrap = (import ./_bootstrap) {
    inherit fetchurl mkEarlyDerivation;
    inherit bootstrap-musl bootstrap-busybox bootstrap-toolchain;
  };  # -> .early-{gnumake,linux-headers,cmake,python,clang}

  stdenv = (import ./stdenv) {
    inherit fetchurl mkCaDerivation mkEarlyDerivation;
    inherit bootstrap-busybox;  # a bit of a layering violation
    inherit (_bootstrap) early-clang early-gnumake;
    inherit (_bootstrap) early-linux-headers early-cmake early-python;
  };  # -> .musl .clang .busybox

  gnumake = (import ./gnumake.nix) {
    inherit stdenv fetchurl;
    early-gnumake = _bootstrap.early-gnumake;  # a bit of a layering violation
  };

in
  _bootstrap // {
    inherit stdenv;
    inherit (stdenv) musl clang busybox;
  } //{
    inherit gnumake;
  }
