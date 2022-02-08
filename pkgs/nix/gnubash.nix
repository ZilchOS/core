{ name ? "gnubash", stdenv, fetchurl, gnumake }:

#> FETCH 0cfb5c9bb1a29f800a97bd242d19511c997a1013815b805e0fdd32214113d6be
#>  FROM https://ftp.gnu.org/gnu/bash/bash-5.1.8.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "5.1.8";

  src = fetchurl {
    # local = /downloads/bash-5.1.8.tar.gz;
    url = "https://ftp.gnu.org/gnu/bash/bash-5.1.8.tar.gz";
    sha256 = "0cfb5c9bb1a29f800a97bd242d19511c997a1013815b805e0fdd32214113d6be";
  };

  buildInputs = [ gnumake ];

  postPatch = "sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure";
  extraConfigureFlags = [ "--without-bash-malloc" ];

  # TODO: why so many
  allowedRequisites = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox];
  allowedReferences = [ "out" stdenv.clang.sysroot stdenv.musl stdenv.busybox];
}
