{ name ? "lowdown", stdenv, fetchurl, gnumake }:

#> FETCH 1b1896b334861db1c588adc6b72ecd88b9e143a397f04d96a6fdeb633f915208
#>  FROM https://github.com/kristapsdz/lowdown/archive/refs/tags/VERSION_0_10_0.tar.gz
#>    AS lowdown-0.10.0.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.10.0";

  src = fetchurl {
    # local = /downloads/lowdown-0.10.0.tar.gz;
    url = "https://github.com/kristapsdz/lowdown/archive/refs/tags/VERSION_0_10_0.tar.gz";
    sha256 = "1b1896b334861db1c588adc6b72ecd88b9e143a397f04d96a6fdeb633f915208";
  };

  buildInputs = [ gnumake ];

  patches = [ ./lowdown-shared.patch ];

  postPatch = "sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure";
  configurePhase = "./configure PREFIX=$out";

  #fixupPhase = "";

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
