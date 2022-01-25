{ name ? "pkgconfig", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "0.29.2";

  src = fetchurl {
    # local = /downloads/pkg-config-0.29.2.tar.gz;
    url = "https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz";
    sha256 = "6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591";
  };

  buildInputs = [ gnumake ];

  patchPhase = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
            configure glib/configure install-sh glib/install-sh
  '';

  extraConfigureFlags = [ "--with-internal-glib" ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
