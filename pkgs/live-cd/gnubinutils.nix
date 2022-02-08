{ name ? "gnubinutils", stdenv, fetchurl, gnumake }:

#> FETCH 820d9724f020a3e69cb337893a0b63c2db161dadcb0e06fc11dc29eb1e84a32c
#>  FROM https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "2.37";

  src = fetchurl {
    # local = /downloads/binutils-2.37.tar.xz;
    url = "https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.xz";
    sha256 = "820d9724f020a3e69cb337893a0b63c2db161dadcb0e06fc11dc29eb1e84a32c";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
            configure missing install-sh mkinstalldirs
    # see libtool's 74c8993c178a1386ea5e2363a01d919738402f30
    sed -i 's/| \$NL2SP/| sort | $NL2SP/' ltmain.sh
  '';

  extraConfigureFlags = [
    "--disable-nls"
    "--enable-targets=x86_64-elf,x86_64-pe"
    "--enable-deterministic-archives"
  ];

  allowedRequisites = [ "out" stdenv.musl stdenv.clang.sysroot ];
  allowedReferences = [ "out" stdenv.musl stdenv.clang.sysroot ];
}
