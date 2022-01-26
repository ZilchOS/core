{ name ? "boost", stdenv, fetchurl, gnumake, linux-headers }:

#> FETCH fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854
#>  FROM https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2

stdenv.mkDerivation {
  pname = name;
  version = "1.77.0";

  src = fetchurl {
    # local = /downloads/boost_1_77_0.tar.bz2;
    url = "https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2";
    sha256 = "fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854";
  };

  buildInputs = [ gnumake ];

  prePatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      bootstrap.sh tools/build/src/engine/build.sh
    sed -i 's|/bin/sh|sh|' \
      tools/build/src/engine/execunix.cpp \
      boost/process/detail/posix/shell_path.hpp
  '';
  configurePhase = "./bootstrap.sh";
  buildPhase = ''
    mkdir -p extra-includes
    cp ${stdenv.clang.sysroot}/include/clang/*mmintrin.h extra-includes/
    cp ${stdenv.clang.sysroot}/include/clang/mm_malloc.h extra-includes/
    cp ${stdenv.clang.sysroot}/include/clang/unwind.h extra-includes/
    export LD_LIBRARY_PATH="${stdenv.clang.sysroot}/lib"
    ./b2 --without-python -j $NPROC \
      include=${linux-headers}/include \
      include=extra-includes
  '';
  installPhase = ''
    export LD_LIBRARY_PATH="${stdenv.clang.sysroot}/lib"
    ./b2 install --prefix=$out
  '';

  allowedRequisites = [ "out" stdenv.musl ];
  allowedReferences = [ "out" stdenv.musl ];
}
