{ name ? "sqlite", stdenv, fetchurl, gnumake }:

#> FETCH bd90c3eb96bee996206b83be7065c9ce19aef38c3f4fb53073ada0d0b69bbce3
#>  FROM https://www.sqlite.org/2021/sqlite-autoconf-3360000.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "3360000";

  src = fetchurl {
    # local = /downloads/sqlite-autoconf-3360000.tar.gz;
    url = "https://www.sqlite.org/2021/sqlite-autoconf-3360000.tar.gz";
    sha256 = "bd90c3eb96bee996206b83be7065c9ce19aef38c3f4fb53073ada0d0b69bbce3";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
