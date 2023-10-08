{ name ? "nasm", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "2.16.01";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/nasm-2.16.01.tar.xz;
    url = "https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/nasm-2.16.01.tar.xz";
    sha256 = "c77745f4802375efeee2ec5c0ad6b7f037ea9c87c92b149a9637ff099f162558";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      configure autoconf/helpers/install-sh
    mv nasmlib/ver.c nasmlib/ver.c.ref
    sed 's|__DATE__|"Jan  1 1970"|' < nasmlib/ver.c.ref > nasmlib/ver.c
    touch -r nasmlib/ver.c.ref nasmlib/ver.c
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
