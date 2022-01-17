{ name ? "gnumake", fetchurl, mkDerivation, musl, toolchain, gnumake, busybox }:

let
  source-tarball-gnumake = fetchurl {
    # local = /downloads/make-4.3.tar.gz;
    url = "http://ftp.gnu.org/gnu/make/make-4.3.tar.gz";
    sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ busybox toolchain gnumake ];
    builder = "${busybox}/bin/ash";
    script = ''
      # unpack:
        unpack ${source-tarball-gnumake}
      # fixup:
        sed -i 's|/bin/sh|${busybox}/bin/ash|' \
                src/job.c build-aux/install-sh po/Makefile.in.in
      # reconfigure:
        ash ./configure \
                --build x86_64-linux \
                --disable-dependency-tracking \
                --prefix=$out \
                CONFIG_SHELL='${busybox}/bin/ash' \
                SHELL='${busybox}/bin/ash'
      # test:
        make -j $NPROC
      # install:
        make -j $NPROC install
      # wrap:
        # FIXME: patch make to use getenv?
        mv $out/bin/make $out/bin/.make.unwrapped
        echo "#!${busybox}/bin/ash" > $out/bin/make
        echo "exec $out/bin/.make.unwrapped SHELL=${busybox}/bin/ash \"\$@\"" \
          >> $out/bin/make
        chmod +x $out/bin/make
    '';
    extra.allowedRequisites = [ "out" musl busybox ];
    extra.allowedReferences = [ "out" musl busybox ];
  }
