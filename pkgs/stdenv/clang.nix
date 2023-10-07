{ pname ? "clang", fetchurl, stdenv, gnumake, linux-headers, cmake, python}:

let
  src = fetchurl {  # parsed by other tooling, must be of fixed format
    # local = /downloads/llvm-project-17.0.1.src.tar.xz;
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.1/llvm-project-17.0.1.src.tar.xz";
    sha256 = "b0e42aafc01ece2ca2b42e3526f54bebc4b1f1dc8de6e34f46a0446a13e882b9";
  };
in

stdenv.mkDerivation {
  inherit pname src;
  version = "17.0.1";

  buildInputs = [ stdenv.busybox gnumake cmake python ];
                # stdenv.clang not added to PATH on purpose to avoid confusion

  postPatch = ''
    sed -i "s|COMMAND sh|COMMAND ${stdenv.busybox}/bin/ash|" \
      llvm/cmake/modules/GetHostTriple.cmake clang/CMakeLists.txt
    echo 'echo x86_64-unknown-linux-musl' > llvm/cmake/config.guess
    LOADER=${stdenv.musl}/lib/libc.so
    sed -i "s|/lib/ld-musl-\" + ArchName + \".so.1|$LOADER|" \
      clang/lib/Driver/ToolChains/Linux.cpp
    BEGINEND='const bool HasCRTBeginEndFiles'
    sed -i "s|$BEGINEND =|$BEGINEND = false; ''${BEGINEND}_unused =|" \
      clang/lib/Driver/ToolChains/Gnu.cpp
    REL_ORIGIN='_install_rpath \"\$ORIGIN/../lib''${LLVM_LIBDIR_SUFFIX}\"'
    sed -i "s|_install_rpath \"\\\\\$ORIGIN/..|_install_rpath \"$toolchain|" \
      llvm/cmake/modules/AddLLVM.cmake
    sed -i 's|numShards = 32;|numShards = 1;|' lld/*/SyntheticSections.*
    sed -i 's|numShards = 256;|numShards = 1;|' lld/*/ICF.cpp
    sed -i 's|__FILE__|__FILE_NAME__|' \
      libcxx/src/verbose_abort.cpp \
      libcxxabi/src/abort_message.cpp \
      compiler-rt/lib/builtins/int_util.h
  '';

  preConfigure = ''
    EXTRA_INCL="$(pwd)/extra_includes"
    mkdir -p $EXTRA_INCL
    cp clang/lib/Headers/*intrin*.h $EXTRA_INCL/
    cp clang/lib/Headers/mm_malloc.h $EXTRA_INCL/
    [ -e $EXTRA_INCL/immintrin.h ]
  '';

  configurePhase = ''
    # Shared libs are not relinked on install. Instead, their rpath
    # is erased with RPATH_SET: `Set runtime path of
    # "/nix/store/.../lib/x86_64-unknown-linux-musl/libc++.so.1.0" to ""`
    # One (hacky) workaround to that is using a constant-len build-dir.
    build_dir=build; expr "$(pwd)/$build_dir)" '<=' 134
    while ! echo "$(pwd)/$build_dir" | wc -c | grep -Fqx 134; do
      build_dir="$build_dir."
    done; mkdir $build_dir; expr "$(echo $(pwd)/build* | wc -c)" '==' 134

    export SHELL=${stdenv.busybox}/bin/ash
    LOADER=${stdenv.musl}/lib/libc.so

    # prepare build-time sysroot:
    mkdir -p $sysroot
    ln -s $sysroot sysroot  # ccache trickery as out hash is unstable
    mkdir -p sysroot/lib sysroot/include
    ln -s ${stdenv.musl}/lib/* sysroot/lib/
    ln -s ${stdenv.musl}/include/* sysroot/include/

    # figure out includes:
    KHDR=${linux-headers}/include
    EXTRA_INCL=$(pwd)/extra_includes

    # llvm cmake configuration should pick up ccache automatically from PATH
    command -v ccache && USE_CCACHE=YES || USE_CCACHE=NO

    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/$build_dir/lib" # libLLVM

    REWRITE="-ffile-prefix-map=$(pwd)=/builddir/"
    CFLAGS="--sysroot=$(pwd)/sysroot -isystem $EXTRA_INCL $REWRITE"
    LDFLAGS="-Wl,--dynamic-linker=$LOADER"
    cmake -S llvm -B build* -G 'Unix Makefiles' \
      -DCMAKE_ASM_COMPILER=${stdenv.clang}/bin/clang \
      -DCMAKE_C_COMPILER=${stdenv.clang}/bin/clang \
      -DCMAKE_CXX_COMPILER=${stdenv.clang}/bin/clang++ \
      -DLLVM_ENABLE_PROJECTS='clang;lld' \
      -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
      -DCMAKE_C_FLAGS="$CFLAGS" \
      -DCMAKE_CXX_FLAGS="$CFLAGS" \
      -DCMAKE_C_LINK_FLAGS="$LDFLAGS" \
      -DCMAKE_CXX_LINK_FLAGS="$LDFLAGS" \
      -DLLVM_BUILD_LLVM_DYLIB=YES \
      -DLLVM_LINK_LLVM_DYLIB=YES \
      -DCLANG_LINK_LLVM_DYLIB=YES \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_OPTIMIZED_TABLEGEN=YES \
      -DLLVM_CCACHE_BUILD=$USE_CCACHE \
      -DDEFAULT_SYSROOT=$sysroot \
      -DCMAKE_INSTALL_PREFIX=$toolchain \
      -DLLVM_INSTALL_BINUTILS_SYMLINKS=YES \
      -DLLVM_INSTALL_CCTOOLS_SYMLINKS=YES \
      -DCMAKE_INSTALL_DO_STRIP=YES \
      -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=YES \
      -DLLVM_TARGET_ARCH=X86 \
      -DLLVM_TARGETS_TO_BUILD=Native \
      -DLLVM_BUILTIN_TARGETS=x86_64-unknown-linux-musl \
      -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
      -DLLVM_HOST_TRIPLE=x86_64-unknown-linux-musl \
      -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
      -DLLVM_APPEND_VC_REV=NO \
      -DLLVM_INCLUDE_TESTS=NO \
      -DLLVM_INCLUDE_EXAMPLES=NO \
      -DLLVM_INCLUDE_BENCHMARKS=NO \
      -DLLVM_ENABLE_BACKTRACES=YES \
      -DLLVM_ENABLE_EH=YES \
      -DLLVM_ENABLE_RTTI=YES \
      -DCLANG_ENABLE_ARCMT=NO \
      -DCLANG_ENABLE_STATIC_ANALYZER=NO \
      -DCOMPILER_RT_BUILD_SANITIZERS=NO \
      -DCOMPILER_RT_BUILD_XRAY=NO \
      -DCOMPILER_RT_BUILD_LIBFUZZER=NO \
      -DCOMPILER_RT_BUILD_PROFILE=NO \
      -DCOMPILER_RT_BUILD_MEMPROF=NO \
      -DCOMPILER_RT_BUILD_ORC=NO \
      -DCOMPILER_RT_USE_BUILTINS_LIBRARY=YES \
      -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
      -DCLANG_DEFAULT_LINKER=lld \
      -DCLANG_DEFAULT_RTLIB=compiler-rt \
      -DLIBCXX_HAS_MUSL_LIBC=YES \
      -DLIBCXX_USE_COMPILER_RT=YES \
      -DLIBCXX_INCLUDE_BENCHMARKS=NO \
      -DLIBCXX_CXX_ABI=libcxxabi \
      -DLIBCXX_ADDITIONAL_COMPILE_FLAGS=-I$KHDR \
      -DLIBCXXABI_USE_COMPILER_RT=YES \
      -DLIBCXXABI_USE_LLVM_UNWINDER=YES \
      -DLLVM_INSTALL_TOOLCHAIN_ONLY=YES \
      -DLIBUNWIND_USE_COMPILER_RT=YES \
      -DLLVM_ENABLE_THREADS=NO
  '';

  buildPhase = ''
    build_dir=$(echo build*)
    export SHELL=${stdenv.busybox}/bin/ash
    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/$build_dir/lib" # libLLVM

    # llvm cmake configuration should pick up ccache automatically from PATH
    make -C build* -j $NPROC
  '';

  installPhase = ''
    build_dir=$(echo build*)
    export SHELL=${stdenv.busybox}/bin/ash
    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/$build_dir/lib" # libLLVM
    make -C build* -j $NPROC install/strip
  '';

  postInstall = ''
    ln -s $toolchain/lib/x86_64-unknown-linux-musl/* $toolchain/lib/
    mkdir -p $toolchain/bin
    ln -s clang $toolchain/bin/cc
    ln -s clang++ $toolchain/bin/c++
    ln -s clang-cpp $toolchain/bin/cpp
    ln -s lld $toolchain/bin/ld
    ln -s libclang_rt.builtins.a \
          $toolchain/lib/clang/17/lib/x86_64-unknown-linux-musl/libclang_rt.builtins-x86_64.a
    ln -s x86_64-unknown-linux-musl \
          $toolchain/lib/clang/17/lib/linux
    cp -r $toolchain/lib/x86_64-unknown-linux-musl/* $sysroot/lib/
    cp -r $toolchain/lib/clang $sysroot/lib/
    cp -r $toolchain/include/x86_64-unknown-linux-musl $sysroot/include/
  '';

  fixupPhase = "";

  outputs = [ "toolchain" "sysroot" ];

  allowedRequisites = [ "toolchain" "sysroot" stdenv.musl ];
  allowedReferences = [ "toolchain" "sysroot" stdenv.musl ];
  # IDK how to express "sysroot must not reference toolchain" though
}
