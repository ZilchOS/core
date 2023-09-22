{ name ? "gnumake", fetchurl, mkDerivation, toolchain, busybox }:

let
  source-tarball-gnumake = fetchurl {
    # local = /downloads/make-4.4.1.tar.gz;
    url = "http://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz";
    sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ busybox toolchain ];
    script = ''
        mkdir build-dir; cd build-dir
      # unpack:
        unpack ${source-tarball-gnumake}
      # fixup:
        sed -i 's|/bin/sh|${busybox}/bin/ash|' \
                src/job.c build-aux/install-sh po/Makefile.in.in
        # this is part of stdlib, no idea how it's supposed to not clash
        rm src/getopt.h
        for f in src/getopt.c src/getopt1.c lib/fnmatch.c; do :> $f; done
        for f in lib/glob.c lib/xmalloc.c lib/error.c; do :> $f; done
      # embrace chaos:
        shuffle_comment='\/\* Handle shuffle mode argument.  \*\/'
        shuffle_default='if (!shuffle_mode) shuffle_mode = xstrdup(\"random\");'
        sed -i "s|$shuffle_comment|$shuffle_comment\n$shuffle_default|" \
               src/main.c
        grep -F 'if (!shuffle_mode) shuffle_mode = xstrdup("random");' \
                src/main.c
      # configure:
        ash ./configure \
                --build x86_64-linux \
                --disable-dependency-tracking \
                --prefix=$out \
                CONFIG_SHELL='${busybox}/bin/ash' \
                SHELL='${busybox}/bin/ash'
      # bootstrap build:
        ash ./build.sh
      # test GNU Make by remaking it with itself:
        mv make make-intermediate
        ./make-intermediate -j $NPROC clean
        ./make-intermediate -j $NPROC
      # reconfigure:
        ash ./configure \
                --build x86_64-linux \
                --disable-dependency-tracking \
                --prefix=$out \
                CONFIG_SHELL='${busybox}/bin/ash' \
                SHELL='${busybox}/bin/ash'
      # rebuild:
        ash ./build.sh
      # test:
        mv make make-intermediate
        ./make-intermediate -j $NPROC clean
        ./make-intermediate -j $NPROC CFLAGS=-ffile-prefix-map=$(pwd)=/builddir/
      # install:
        ./make -j $NPROC install
      # wrap:
        # FIXME: patch make to use getenv?
        mv $out/bin/make $out/bin/.make.unwrapped
        echo "#!${busybox}/bin/ash" > $out/bin/make
        echo "exec $out/bin/.make.unwrapped SHELL=\$SHELL \"\$@\"" \
          >> $out/bin/make
        chmod +x $out/bin/make
      # check for build path leaks:
        ( ! grep -RF $(pwd) $out )
    '';
  }
