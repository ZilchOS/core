{ name ? "python", fetchurl, mkDerivation, toolchain, busybox, gnumake }:

let
  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/Python-3.11.5.tar.xz;
    url = "https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tar.xz";
    sha256 = "85cd12e9cf1d6d5a45f17f7afe1cebe7ee628d3282281c492e86adf636defa3f";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ busybox toolchain gnumake ];
    script = ''
        mkdir build-dir; cd build-dir
        export SHELL=${busybox}/bin/ash
      # alias ash to sh:
        mkdir aliases; ln -s ${busybox}/bin/ash aliases/sh
        export PATH="$(pwd)/aliases:$PATH"
      # unpack:
        unpack ${src}
      # fixup:
        sed -i 's|/bin/sh|${busybox}/bin/ash|' configure
        # the precompiled pyc files aren't reproducible,
        # but it's not like I need to waste time on them anyway.
        # break their generation
        mv Lib/compileall.py Lib/compileall.py.bak
        echo 'import sys; sys.exit(0)' > Lib/compileall.py
        chmod +x Lib/compileall.py
        sed -i 's|__FILE__|__FILE_NAME__|' \
          Python/errors.c \
          Include/pyerrors.h \
          Include/cpython/object.h \
          Modules/pyexpat.c
        sed -i 's|TIME __TIME__|TIME "xx:xx:xx"|' Modules/getbuildinfo.c
        sed -i 's|DATE __DATE__|DATE "xx/xx/xx"|' Modules/getbuildinfo.c
        # different build path length leads to different wrapping. avoid
        sed -i 's|vars, stream=f|vars, stream=f, width=2**24|' Lib/sysconfig.py
      # configure:
        ash configure \
          ac_cv_broken_sem_getvalue=yes \
          ac_cv_posix_semaphores_enabled=no \
          OPT='-DNDEBUG -fwrapv -O3 -Wall' \
          --without-static-libpython \
          --build x86_64-linux-musl \
          --prefix=$out \
          --enable-shared \
          --with-ensurepip=no
        # ensure reproducibility in case of no /dev/shm
        grep 'define POSIX_SEMAPHORES_NOT_ENABLED 1' pyconfig.h
        grep 'define HAVE_BROKEN_SEM_GETVALUE 1' pyconfig.h
      # build:
        make SHELL=$SHELL -j $NPROC CFLAGS="-ffile-prefix-map=$(pwd)=/builddir/"
      # install:
        make SHELL=$SHELL -j $NPROC install
        # restore compileall just in case
        cat Lib/compileall.py.bak > $out/lib/python3.11/compileall.py
      # strip builddir mentions:
        sed -i "s|$(pwd)|...|g" \
          $out/lib/python3.*/_sysconfigdata__*.py \
          $out/lib/python3.*/config-3.*-x86_64-linux-musl/Makefile
      # check for build path leaks:
        ( ! grep -rF $(pwd) $out )
    '';
  }
