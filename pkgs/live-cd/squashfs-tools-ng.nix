{ name ? "squashfs-tools-ng", stdenv, fetchurl, gnumake, pkg-config, zstd }:

#> FETCH abce0fcf9a8ae1c3352e4e5e87e1b077f54411da517332ea83b5e7ce948dd70d
#>  FROM https://infraroot.at/pub/squashfs/squashfs-tools-ng-1.1.3.tar.xz

stdenv.mkDerivation {
  pname = name;
  version = "1.1.3";

  src = fetchurl {
    # local = /downloads/squashfs-tools-ng-1.1.3.tar.gz;
    url = "https://infraroot.at/pub/squashfs/squashfs-tools-ng-1.1.3.tar.xz";
    sha256 = "abce0fcf9a8ae1c3352e4e5e87e1b077f54411da517332ea83b5e7ce948dd70d";
  };

  buildInputs = [ gnumake pkg-config zstd ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure install-sh
  '';

  extraConfigureFlags = [
    "--disable-dependency-tracking"
    "--with-zstd"
  ];

  postInstall = ''
    ${stdenv.patchelf}/bin/patchelf --add-rpath ${zstd}/lib $out/bin/*
  '';

  allowedRequisites = [ "out" stdenv.musl zstd ];
  allowedReferences = [ "out" stdenv.musl zstd ];
}
