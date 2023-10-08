{ name ? "flex", stdenv, fetchurl, gnumake, gnum4 }:

stdenv.mkDerivation {
  pname = name;
  version = "2.6.4";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/flex-2.6.4.tar.gz;
    url = "https://github.com/westes/flex/files/981163/flex-2.6.4.tar.gz";
    sha256 = "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995";
  };

  buildInputs = [ gnumake gnum4 ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure build-aux/install-sh
  '';
  extraConfigureFlags = [ "--disable-bootstrap" "--disable-libfl" ];

  allowedRequisites = [ "out" stdenv.musl stdenv.busybox gnum4 ];
  allowedReferences = [ "out" stdenv.musl stdenv.busybox gnum4 ];
}
