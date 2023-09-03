{ name ? "zstd", stdenv, fetchurl, gnumake }:

#> FETCH 9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
#>  FROM https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.5.5";

  src = fetchurl {
    # local = /downloads/zstd-1.5.5.tar.gz;
    url = "https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz";
    sha256 = "9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4";
  };

  buildInputs = [ gnumake ];

  configurePhase = "";

  extraBuildFlags = [
    "CFLAGS='-O3 -fPIC -isystem ${stdenv.clang.sysroot}/lib/clang/17/include'"
  ];
  installPhase = "make install PREFIX=$out";
  postInstall = ''
    sed -i "s|^prefix=.*|prefix=$out|" $out/lib/pkgconfig/libzstd.pc
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
