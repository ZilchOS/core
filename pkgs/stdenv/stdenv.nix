{ mkCaDerivation, musl, clang, busybox }:

let
  _prelude = ''
    if [ -n "$NIX_BUILD_CORES" ] && [ "$NIX_BUILD_CORES" != 0 ]; then
        NPROC=$NIX_BUILD_CORES
    elif [ "$NIX_BUILD_CORES" == 0 ] && [ -r /proc/cpuinfo ]; then
        NPROC=$(${busybox}/bin/grep -c processor /proc/cpuinfo)
    else
        NPROC=1
    fi

    unpack() (${busybox}/bin/tar --strip-components=1 -xf "$@")
  '';

  writeFile = { name, contents }: mkCaDerivation {
    inherit name contents;
    passAsFile = [ "contents" ];
    builder = "${busybox}/bin/ash";
    args = [ "-c" "${busybox}/bin/cat $contentsPath >$out" ];
  };

  _preludeFile = writeFile { name = "stdenv-prelude"; contents = _prelude; };

  _mkMkDerivation = bakedInBuiltInputs:
    { pname, version
    , builder ? "${busybox}/bin/ash", args ? false, script ? ""
    , buildInputs ? [], extra ? {}, passthru ? {}}:
    (mkCaDerivation {
      name = "${pname}-${version}";
      inherit builder;
      args = if args then args else [ "-uexc" (
        ''
          . ${_preludeFile}

          # for building as part of bootstrap-from-tcc with USE_CCACHE=1
          if [ -e /ccache/setup ]; then
            . /ccache/setup ZilchOS/Core/${pname}
          fi

          export PATH=${builtins.concatStringsSep ":" (
            map (x: "${x}/bin") (buildInputs ++ bakedInBuiltInputs)
          )}
        '' + script
      ) ];
    } // extra ) // passthru;

    stdenvBase = writeFile { name = "stdenv"; contents = ""; };
in
  stdenvBase // {
    inherit writeFile musl clang busybox;
    mkDerivation = _mkMkDerivation [ busybox clang ];
    mkDerivationNoCC = _mkMkDerivation [ busybox ];
  }
