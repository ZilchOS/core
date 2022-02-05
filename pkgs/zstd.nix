{ name ? "zstd", stdenv, fetchurl, gnumake }:

#> FETCH 7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0
#>  FROM https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.5.2";

  src = fetchurl {
    # local = /downloads/zstd-1.5.2.tar.gz;
    url = "https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz";
    sha256 = "7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0";
  };

  buildInputs = [ gnumake ];

  configurePhase = "";

  extraBuildFlags = [
    "CFLAGS='-O3 -I${stdenv.clang.sysroot}/include/clang'"
  ];
  installPhase = "make install PREFIX=$out";
  postInstall = ''
    sed -i "s|^prefix=.*|prefix=$out|" $out/lib/pkgconfig/libzstd.pc
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
