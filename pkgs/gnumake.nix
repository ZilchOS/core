{ name ? "gnumake", stdenv, fetchurl, gnumake }:
# gnumake being the previous one

stdenv.mkDerivation {
  pname = name;
  version = "4.3";

  src = fetchurl {
    # local = /downloads/make-4.3.tar.gz;
    url = "http://ftp.gnu.org/gnu/make/make-4.3.tar.gz";
    sha256 = "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure src/job.c build-aux/install-sh po/Makefile.in.in
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
