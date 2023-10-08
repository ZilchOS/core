{ name ? "boost", stdenv, fetchurl, gnumake, linux-headers }:

stdenv.mkDerivation {
  pname = name;
  version = "1.83.0";

  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/boost_1_83_0.tar.bz2;
    url = "https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/boost_1_83_0.tar.bz2";
    sha256 = "6478edfe2f3305127cffe8caf73ea0176c53769f4bf1585be237eb30798c3b8e";
  };

  buildInputs = [ gnumake ];

  outputs = [ "all" "headers" "nixRuntimeMini" ];

  postPatch = ''
    sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' \
      bootstrap.sh
    sed -i 's|/usr/bin/env sh|${stdenv.busybox}/bin/ash|' \
      tools/build/src/engine/build.sh
    sed -i 's|/bin/sh|sh|' \
      tools/build/src/engine/execunix.cpp \
      boost/process/detail/posix/shell_path.hpp
    # https://github.com/boostorg/serialization/issues/221
    rm 'boost/serialization/collection_size_type copy.hpp'
  '';
  configurePhase = "./bootstrap.sh";
  buildPhase = ''
    mkdir -p extra-includes
    cp ${stdenv.clang.sysroot}/lib/clang/17/include/*intrin*.h extra-includes/
    cp ${stdenv.clang.sysroot}/lib/clang/17/include/mm_malloc.h extra-includes/
    cp ${stdenv.clang.sysroot}/lib/clang/17/include/unwind.h extra-includes/
    export LD_LIBRARY_PATH="${stdenv.clang.sysroot}/lib"
    ./b2 -j $NPROC \
      include=${linux-headers}/include \
      include=${stdenv.clang.sysroot}/include/x86_64-unknown-linux-musl/c++/v1 \
      include=extra-includes \
      --with-context --with-thread --with-system
  '';
  installPhase = ''
    export LD_LIBRARY_PATH="${stdenv.clang.sysroot}/lib"
    ./b2 install --prefix=$all --with-context --with-thread --with-system
    # Make boost header paths relative so that they are not runtime dependencies
    cd $all/include
    find . -type f -exec sh -c \
      'echo {}; echo "#line 1 \"{}\"" >tmp; cat {} >>tmp; cat tmp > {}; rm tmp' ';'
    cd -
    mkdir -p $nixRuntimeMini/lib
    cp -r $all/lib/libboost_context*.so* $nixRuntimeMini/lib/
    cp -r $all/lib/libboost_thread*.so* $nixRuntimeMini/lib/
    cp -r $all/lib/libboost_system*.so* $nixRuntimeMini/lib/
    mkdir -p $headers
    cp -r $all/include $headers/
  '';

  allowedRequisites = [ "all" stdenv.musl ];
  allowedReferences = [ "all" stdenv.musl ];
}
