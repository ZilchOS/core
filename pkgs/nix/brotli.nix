{ name ? "brotli", stdenv, fetchurl, gnumake }:

#> FETCH f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
#>  FROM https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz
#>    AS brotli-1.0.9.tar.gz

stdenv.mkDerivation {
  pname = name;
  version = "1.0.9";

  src = fetchurl {
    # local = /downloads/brotli-1.0.9.tar.gz;
    url = "https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz";
    sha256 = "f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46";
  };

  buildInputs = [ gnumake ];

  configurePhase = "";
  extraBuildFlags = [
    "lib"
    "CFLAGS='${toString [
      "-O2" "-fPIC"
      "-DBROTLICOMMON_SHARED_COMPILATION" "-DBROTLI_SHARED_COMPILATION"
    ]}'"
  ];
  postBuild = ''
    clang -shared bin/obj/c/common/*.o -o libbrotlicommon.so
    clang -shared bin/obj/c/enc/*.o libbrotlicommon.so -o libbrotlienc.so
    clang -shared bin/obj/c/dec/*.o libbrotlicommon.so -o libbrotlidec.so
  '';
  installPhase = ''
    mkdir -p $out/lib $out/include
    cp libbrotlicommon.so libbrotlienc.so libbrotlidec.so $out/lib/
    cp -r c/include/brotli $out/include/
    mkdir -p $out/lib/pkgconfig
    for l in common enc dec; do
	    sed < scripts/libbrotli''${l}.pc.in \
		    -e 's|@PACKAGE_VERSION@|1.0.9|g' \
		    -e "s|@prefix@|$out|g" \
		    -e "s|@exec_prefix@|$out/bin|g" \
		    -e "s|@includedir@|$out/include|g" \
		    -e "s|@libdir@|$out/lib|g" \
		    -e 's|-R|-Wl,-rpath=|g' \
		    > $out/lib/pkgconfig/libbrotli''${l}.pc
    done
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
