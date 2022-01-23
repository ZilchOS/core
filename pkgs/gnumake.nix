{ name ? "gnumake", stdenv, fetchurl, gnumake }:
# gnumake being the previous one

let
  source-tarball-gnumake = fetchurl {
    # local = /downloads/make-4.3.tar.gz;
    url = "http://ftp.gnu.org/gnu/make/make-4.3.tar.gz";
    sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19";
  };
in
  stdenv.mkDerivation {
    pname = name;
    version = "4.3";
    script = ''
      # unpack:
        unpack ${source-tarball-gnumake}
      # fixup:
        sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
                src/job.c build-aux/install-sh po/Makefile.in.in
      # reconfigure:
        ash ./configure \
                --build x86_64-linux \
                --disable-dependency-tracking \
                --prefix=$out \
                CONFIG_SHELL='${stdenv.busybox}/bin/ash' \
                SHELL='${stdenv.busybox}/bin/ash'
      # test:
        ${gnumake}/bin/make -j $NPROC
      # install:
        ${gnumake}/bin/make -j $NPROC install
      # wrap:
        # FIXME: patch make to use getenv?
        mv $out/bin/make $out/bin/.make.unwrapped
        echo '#!${stdenv.busybox}/bin/ash' > $out/bin/make
        echo -n 'exec $out/bin/.make.unwrapped ' > $out/bin/make
        echo 'SHELL=${stdenv.busybox}/bin/ash \"\$@\"' \
          >> $out/bin/make
        chmod +x $out/bin/make
    '';
    extra.allowedRequisites = [ "out" stdenv.musl stdenv.busybox ];
    extra.allowedReferences = [ "out" stdenv.musl stdenv.busybox ];
  }
