{ name ? "python", mkDerivation, toolchain, busybox, gnumake }:

let
  source-tarball-python = builtins.fetchurl {
    # local = /downloads/Python-3.10.0.tar.xz;
    url = "https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz";
    sha256 = "5a99f8e7a6a11a7b98b4e75e0d1303d3832cada5534068f69c7b6222a7b1b002";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ busybox toolchain gnumake ];
    script = ''
        export SHELL=${busybox}/bin/ash
      # alias ash to sh:
        mkdir aliases; ln -s ${busybox}/bin/ash aliases/sh
        export PATH="$(pwd)/aliases:$PATH"
      # unpack:
        unpack ${source-tarball-python}
      # fixup:
        sed -i 's|/bin/sh|${busybox}/bin/ash|' configure
        # the precompiled pyc files aren't reproducible,
        # but it's not like I need to waste time on them anyway.
        # break their generation
        mv Lib/compileall.py Lib/compileall.py.bak
        echo 'import sys; sys.exit(0)' > Lib/compileall.py
        chmod +x Lib/compileall.py
      # configure:
        ash configure \
          --without-static-libpython \
          --build x86_64-linux-musl \
          --prefix=$out \
          --enable-shared \
          --with-ensurepip=no
      # build:
        make SHELL=$SHELL -j $NPROC
      # install:
        make SHELL=$SHELL -j $NPROC install
        # restore compileall just in case
        cat Lib/compileall.py.bak > $out/lib/python3.10/compileall.py
    '';
  }
