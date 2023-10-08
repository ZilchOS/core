{ name ? "gnubinutils", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "2.39";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/binutils-2.39.tar.xz;
    url = "https://ftp.gnu.org/gnu/binutils/binutils-2.39.tar.xz";
    sha256 = "645c25f563b8adc0a81dbd6a41cffbf4d37083a382e02d5d3df4f65c09516d00";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
            configure missing install-sh mkinstalldirs
    # see libtool's 74c8993c178a1386ea5e2363a01d919738402f30
    sed -i 's/| \$NL2SP/| sort | $NL2SP/' ltmain.sh
    # prefix gets into sources, source file MD5 gets into linker
    # sed -i 's|"\$prefix"|""|' ld/emultempl/elf.em
  '';

  configurePhase = ''
    mkdir aliases
    echo -e "#!${stdenv.busybox}/bin/ash\nexec ${stdenv.busybox}/bin/true" \
      > aliases/makeinfo
    chmod +x aliases/makeinfo
    export PATH=$(pwd)/aliases:$PATH
    ./configure \
      --prefix=$out \
      --disable-nls \
      --disable-gprofng \
      --enable-targets=x86_64-elf,x86_64-pe \
      --enable-deterministic-archives
  '';

  buildPhase = ''
    export PATH=$(pwd)/aliases:$PATH
    make -j $NPROC all
  '';

  installPhase = ''
    export PATH=$(pwd)/aliases:$PATH
    make install-strip
    rm $out/lib/*.la  # reference builddir
  '';  # stripping sidesteps the MD5 -> binaries problem

  allowedRequisites = [ "out" stdenv.musl stdenv.clang.sysroot ];
  allowedReferences = [ "out" stdenv.musl stdenv.clang.sysroot ];
}
