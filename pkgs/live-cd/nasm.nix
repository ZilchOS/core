{ name ? "nasm", stdenv, fetchurl, gnumake }:

#> FETCH 3caf6729c1073bf96629b57cee31eeb54f4f8129b01902c73428836550b30a3f
#>  FROM https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "2.15.05";

  src = fetchurl {
    # local = /downloads/nasm-2.15.05.tar.xz;
    url = "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.xz";
    sha256 = "3caf6729c1073bf96629b57cee31eeb54f4f8129b01902c73428836550b30a3f";
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
