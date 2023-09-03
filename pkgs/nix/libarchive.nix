{ name ? "libarchive", stdenv, fetchurl, gnumake }:

#> FETCH b17403ce670ff18d8e06fea05a9ea9accf70678c88f1b9392a2e29b51127895f
#>  FROM http://libarchive.org/downloads/libarchive-3.7.1.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "3.7.1";

  src = fetchurl {
    # local = /downloads/libarchive-3.7.1.tar.xz;
    url = "https://libarchive.org/downloads/libarchive-3.7.1.tar.xz";
    sha256 = "b17403ce670ff18d8e06fea05a9ea9accf70678c88f1b9392a2e29b51127895f";
  };

  extraConfigureFlags = [ "--without-openssl" ];

  buildInputs = [ gnumake ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
	configure build/autoconf/install-sh
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
