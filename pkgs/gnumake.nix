{ name ? "gnumake", stdenv, fetchurl, gnumake }:
# gnumake being the previous one

stdenv.mkDerivation {
  pname = name;
  version = "4.4.1";

  src = fetchurl {
    # local = /downloads/make-4.4.1.tar.gz;
    url = "http://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz";
    sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    # fixup:
      sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
        configure src/job.c build-aux/install-sh po/Makefile.in.in
    # embrace chaos:
      shuffle_comment='\/\* Handle shuffle mode argument.  \*\/'
      shuffle_default='if (!shuffle_mode) shuffle_mode = xstrdup(\"random\");'
      sed -i "s|$shuffle_comment|$shuffle_comment\n$shuffle_default|" \
             src/main.c
      grep -F 'if (!shuffle_mode) shuffle_mode = xstrdup("random");' \
              src/main.c
  '';

  extraConfigureFlags = [
    "--build x86_64-linux"
    "--disable-dependency-tracking"
  ];

  # FIXME: patch make to use getenv?
  postInstall = ''
    mv $out/bin/make $out/bin/.make.unwrapped
    echo '#!${stdenv.busybox}/bin/ash' > $out/bin/make
    echo -n "exec $out/bin/.make.unwrapped " >> $out/bin/make
    echo 'SHELL=${stdenv.busybox}/bin/ash "$@"' >> $out/bin/make
    chmod +x $out/bin/make
  '';

  allowedRequisites = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox ];
  allowedReferences = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox ];
}
