{ name ? "lowdown", stdenv, fetchurl, gnumake }:

stdenv.mkDerivation {
  pname = name;
  version = "1.0.2";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/lowdown-1.0.2.tar.gz;
    url = "https://github.com/kristapsdz/lowdown/archive/refs/tags/VERSION_1_0_2.tar.gz";
    sha256 = "049b7883874f8a8e528dc7c4ed7b27cf7ceeb9ecf8fe71c3a8d51d574fddf84b";
  };

  buildInputs = [ gnumake ];

  postPatch = "sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure";
  configurePhase = "./configure PREFIX=$out";

  #fixupPhase = "";

  installPhase = "make install_shared";

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
