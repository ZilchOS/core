{ name ? "gnuxorriso", stdenv, fetchurl, gnumake, linux-headers }:

#> FETCH 0wi92lxpm3dcjglmmfbh4z37w8jmbx0qmhh98gvzbjwx98ykkiry
#>  FROM https://www.gnu.org/software/xorriso/xorriso-1.5.4.pl02.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.5.4";

  src = fetchurl {
    # local = /downloads/xorriso-1.5.4.pl02.tar.gz;
    url = "https://www.gnu.org/software/xorriso/xorriso-1.5.4.pl02.tar.gz";
    sha256 = "0wi92lxpm3dcjglmmfbh4z37w8jmbx0qmhh98gvzbjwx98ykkiry";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure install-sh
  '';

  extraBuildFlags = [ "CFLAGS='-I${linux-headers}/include'" ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
