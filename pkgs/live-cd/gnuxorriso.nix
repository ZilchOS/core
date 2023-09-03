{ name ? "gnuxorriso", stdenv, fetchurl, gnumake, linux-headers }:

#> FETCH 786f9f5df9865cc5b0c1fecee3d2c0f5e04cab8c9a859bd1c9c7ccd4964fdae1
#>  FROM https://www.gnu.org/software/xorriso/xorriso-1.5.6.pl02.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.5.6";

  src = fetchurl {
    # local = /downloads/xorriso-1.5.6.pl02.tar.gz;
    url = "https://www.gnu.org/software/xorriso/xorriso-1.5.6.pl02.tar.gz";
    sha256 = "786f9f5df9865cc5b0c1fecee3d2c0f5e04cab8c9a859bd1c9c7ccd4964fdae1";
  };

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure install-sh
  '';

  extraBuildFlags = [ "CFLAGS='-I${linux-headers}/include'" ];

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
