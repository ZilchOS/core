{ pname ? "clang", fetchurl, stdenv, gnumake, linux-headers, cmake, python}:

stdenv.mkDerivation {
  pname = pname;
  version = "13.0.0";

  src = fetchurl {
    # local = /downloads/llvm-project-13.0.0.src.tar.xz;
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/llvm-project-13.0.0.src.tar.xz";
    sha256 = "6075ad30f1ac0e15f07c1bf062c1e1268c241d674f11bd32cdf0e040c71f2bf3";
  };

  buildInputs = [ stdenv.busybox gnumake cmake python ];
                # stdenv.clang not added to PATH on purpose to avoid confusion

  prePatch = ''
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
    sed -i 's|intrinsics_gen|intrinsics_gen\n  ClangDriverOptions|' \
      clang/lib/Interpreter/CMakeLists.txt
  '';

  preConfigure = ''
    EXTRA_INCL="$(pwd)/extra_includes"
    mkdir -p $EXTRA_INCL
    cp clang/lib/Headers/*mmintrin.h $EXTRA_INCL/
    cp clang/lib/Headers/mm_malloc.h $EXTRA_INCL/
  '';

  configurePhase = ''
    export SHELL=${stdenv.busybox}/bin/ash
    LOADER=${stdenv.musl}/lib/libc.so

    # prepare build-time sysroot:
    mkdir -p $sysroot
    ln -s $sysroot sysroot  # ccache trickery as out hash is unstable
    mkdir -p sysroot/lib sysroot/include
    ln -s ${stdenv.musl}/lib/* sysroot/lib/
    ln -s ${stdenv.musl}/include/* sysroot/include/
    ln -s ${linux-headers}/include sysroot/phantom-linux-headers

    # figure out includes:
    KHDR=${linux-headers}/include
    EXTRA_INCL=$(pwd)/extra_includes

    # llvm cmake configuration should pick up ccache automatically from PATH
    command -v ccache && USE_CCACHE=YES || USE_CCACHE=NO

    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/build/lib" # libLLVM

    cmake -S llvm -B build -G 'Unix Makefiles' \
      -DCMAKE_ASM_COMPILER=${stdenv.clang}/bin/clang \
      -DCMAKE_C_COMPILER=${stdenv.clang}/bin/clang \
      -DCMAKE_CXX_COMPILER=${stdenv.clang}/bin/clang++ \
      -DLLVM_ENABLE_PROJECTS='clang;lld' \
      -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
      -DCMAKE_C_FLAGS="--sysroot=$(pwd)/sysroot" \
      -DCMAKE_CXX_FLAGS="--sysroot=$(pwd)/sysroot -I$KHDR -I$EXTRA_INCL" \
      -DCMAKE_C_LINK_FLAGS="-Wl,--dynamic-linker=$LOADER" \
      -DCMAKE_CXX_LINK_FLAGS="-Wl,--dynamic-linker=$LOADER" \
      -DLLVM_BUILD_LLVM_DYLIB=YES \
      -DLLVM_LINK_LLVM_DYLIB=YES \
      -DCLANG_LINK_LLVM_DYLIB=YES \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_OPTIMIZED_TABLEGEN=YES \
      -DLLVM_CCACHE_BUILD=$USE_CCACHE \
      -DDEFAULT_SYSROOT=$sysroot \
      -DC_INCLUDE_DIRS=$sysroot/include:$(pwd)/sysroot/phantom-linux-headers \
      -DCMAKE_INSTALL_PREFIX=$toolchain \
      -DLLVM_INSTALL_BINUTILS_SYMLINKS=YES \
      -DLLVM_INSTALL_CCTOOLS_SYMLINKS=YES \
      -DCMAKE_INSTALL_DO_STRIP=YES \
      -DLLVM_TARGET_ARCH=X86 \
      -DLLVM_TARGETS_TO_BUILD=Native \
      -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
      -DLLVM_HOST_TRIPLE=x86_64-unknown-linux-musl \
      -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
      -DLLVM_APPEND_VC_REV=NO \
      -DLLVM_INCLUDE_TESTS=NO \
      -DLLVM_INCLUDE_EXAMPLES=NO \
      -DLLVM_INCLUDE_BENCHMARKS=NO \
      -DLLVM_ENABLE_BACKTRACES=YES \
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
      -DLIBCXXABI_USE_COMPILER_RT=YES \
      -DLIBCXXABI_USE_LLVM_UNWINDER=YES \
      -DLLVM_INSTALL_TOOLCHAIN_ONLY=YES \
      -DLIBUNWIND_USE_COMPILER_RT=YES
  '';

  buildPhase = ''
    export SHELL=${stdenv.busybox}/bin/ash
    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/build/lib" # libLLVM

    # llvm cmake configuration should pick up ccache automatically from PATH
    make -C build -j $NPROC clang     # runs OK in parallel
    make -C build runtimes-configure  # sometimes explodes, serialize =(
    make -C build -j $NPROC           # continue in parallel
  '';

  installPhase = ''
    export LD_LIBRARY_PATH="${stdenv.musl}/lib:${stdenv.clang}/lib"
    export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/build/lib" # libLLVM
    export SHELL=${stdenv.busybox}/bin/ash
    make -C build install/strip  # again, serial because flaky
  '';

  postInstall = ''
    ln -s $toolchain/lib/x86_64-unknown-linux-musl/* $toolchain/lib/
    mkdir -p $toolchain/bin
    ln -s $toolchain/bin/clang $toolchain/bin/cc
    ln -s $toolchain/bin/clang++ $toolchain/bin/c++
    ln -s $toolchain/bin/clang-cpp $toolchain/bin/cpp
    ln -s $toolchain/bin/lld $toolchain/bin/ld
    cp -r $toolchain/lib/x86_64-unknown-linux-musl/* $sysroot/lib/
    cp -r $toolchain/lib/clang $sysroot/lib/
    ln -s $sysroot/lib/clang/13.0.0/include $sysroot/include/clang
    rm $sysroot/phantom-linux-headers
  '';

  fixupPhase = "";

  outputs = [ "toolchain" "sysroot" ];

  allowedRequisites = [ "toolchain" "sysroot" stdenv.musl ];
  allowedReferences = [ "toolchain" "sysroot" stdenv.musl ];
  # IDK how to express "sysroot must not reference toolchain" though
}
