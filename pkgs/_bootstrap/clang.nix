{ name ? "clang", fetchurl, mkDerivation
, toolchain, busybox, musl, gnumake, linux-headers, cmake, python }:

let
  source-tarball-llvm = fetchurl {
    # local = /downloads/llvm-project-13.0.0.src.tar.xz;
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/llvm-project-13.0.0.src.tar.xz";
    sha256 = "6075ad30f1ac0e15f07c1bf062c1e1268c241d674f11bd32cdf0e040c71f2bf3";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ busybox toolchain cmake gnumake python ];
    script = ''
        export SHELL=${busybox}/bin/ash
        # llvm cmake configuration should pick up ccache automatically from PATH
        export PATH="$PATH:/ccache/bin"
        command -v ccache && USE_CCACHE=YES || USE_CCACHE=NO
      # prepare future sysroot:
        SYSROOT=$out/sysroot
        mkdir -p $SYSROOT/lib $SYSROOT/include
        ln -s ${musl}/lib/* $SYSROOT/lib/
        ln -s ${musl}/include/* $SYSROOT/include/
      # unpack:
        unpack ${source-tarball-llvm}
      # fixup:
        sed -i "s|COMMAND sh|COMMAND ${busybox}/bin/ash|" \
          llvm/cmake/modules/GetHostTriple.cmake clang/CMakeLists.txt
        echo 'echo x86_64-unknown-linux-musl' > llvm/cmake/config.guess
        LOADER=${musl}/lib/libc.so
        sed -i "s|/lib/ld-musl-\" + ArchName + \".so.1|$LOADER|" \
          clang/lib/Driver/ToolChains/Linux.cpp
        BEGINEND='const bool HasCRTBeginEndFiles'
        sed -i "s|$BEGINEND =|$BEGINEND = false; ''${BEGINEND}_unused =|" \
          clang/lib/Driver/ToolChains/Gnu.cpp
        REL_ORIGIN='_install_rpath \"\$ORIGIN/../lib''${LLVM_LIBDIR_SUFFIX}\"'
        sed -i "s|_install_rpath \"\\\\\$ORIGIN/..|_install_rpath \"$out|" \
          llvm/cmake/modules/AddLLVM.cmake
        sed -i 's|intrinsics_gen|intrinsics_gen\n  ClangDriverOptions|' \
          clang/lib/Interpreter/CMakeLists.txt
      # figure out includes:
          C_INCLUDES="$SYSROOT/include"
          C_INCLUDES="$C_INCLUDES:${linux-headers}/include"
          EXTRA_INCL="$(pwd)/extra_includes"
          mkdir -p $EXTRA_INCL
          cp clang/lib/Headers/*mmintrin.h $EXTRA_INCL/
          cp clang/lib/Headers/mm_malloc.h $EXTRA_INCL/
      # configure:
          export LD_LIBRARY_PATH=${toolchain}/sysroot/lib
          export LD_LIBRARY_PATH=${python}/lib:$LD_LIBRARY_PATH
          BOTH_STAGES_OPTS=""
          add_opt() {
            BOTH_STAGES_OPTS="$BOTH_STAGES_OPTS -D$1 -DBOOTSTRAP_$1"
          }
          add_opt CMAKE_BUILD_TYPE=MinSizeRel
          add_opt LLVM_OPTIMIZED_TABLEGEN=YES
          add_opt LLVM_CCACHE_BUILD=$USE_CCACHE
          add_opt DEFAULT_SYSROOT=$SYSROOT
          add_opt C_INCLUDE_DIRS=$C_INCLUDES
          add_opt CMAKE_INSTALL_PREFIX=$out
          add_opt LLVM_INSTALL_BINUTILS_SYMLINKS=YES
          add_opt LLVM_INSTALL_CCTOOLS_SYMLINKS=YES
          add_opt CMAKE_INSTALL_DO_STRIP=YES
          add_opt LLVM_TARGET_ARCH=X86
          add_opt LLVM_TARGETS_TO_BUILD=Native
          add_opt LLVM_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl
          add_opt LLVM_HOST_TRIPLE=x86_64-unknown-linux-musl
          add_opt COMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl
          add_opt LLVM_APPEND_VC_REV=NO
          add_opt LLVM_INCLUDE_TESTS=NO
          add_opt LLVM_INCLUDE_EXAMPLES=NO
          add_opt LLVM_INCLUDE_BENCHMARKS=NO
          add_opt LLVM_ENABLE_BACKTRACES=NO
          add_opt CLANG_ENABLE_ARCMT=NO
          add_opt CLANG_ENABLE_STATIC_ANALYZER=NO
          add_opt COMPILER_RT_BUILD_SANITIZERS=NO
          add_opt COMPILER_RT_BUILD_XRAY=NO
          add_opt COMPILER_RT_BUILD_LIBFUZZER=NO
          add_opt COMPILER_RT_BUILD_PROFILE=NO
          add_opt COMPILER_RT_BUILD_MEMPROF=NO
          add_opt COMPILER_RT_BUILD_ORC=NO
          add_opt COMPILER_RT_USE_BUILTINS_LIBRARY=YES
          add_opt CLANG_DEFAULT_CXX_STDLIB=libc++
          add_opt CLANG_DEFAULT_LINKER=lld
          add_opt CLANG_DEFAULT_RTLIB=compiler-rt
          add_opt LIBCXX_HAS_MUSL_LIBC=YES
          add_opt LIBCXX_USE_COMPILER_RT=YES
          add_opt LIBCXXABI_USE_COMPILER_RT=YES
          add_opt LIBCXXABI_USE_LLVM_UNWINDER=YES
          add_opt LLVM_INSTALL_TOOLCHAIN_ONLY=YES
          add_opt LIBUNWIND_USE_COMPILER_RT=YES
          add_opt CMAKE_CXX_FLAGS=-I$EXTRA_INCL
        cmake -S llvm -B build -G 'Unix Makefiles' \
          -DLLVM_ENABLE_PROJECTS='clang;lld' \
          -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
          -DCLANG_ENABLE_BOOTSTRAP=YES $BOTH_STAGES_OPTS
      # build:
        make SHELL=$SHELL -C build -j $NPROC clang  # runs OK in parallel
        make SHELL=$SHELL -C build runtimes-configure  # sometimes explodes,
                                                       # serialize =(
        make SHELL=$SHELL -C build -j $NPROC runtimes  # continue in parallel
        NEW_LIB_DIR="$(pwd)/build/lib/x86_64-unknown-linux-musl"
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$NEW_LIB_DIR"
        make SHELL=$SHELL -C build clang-bootstrap-deps
        make SHELL=$SHELL -C build -j $NPROC stage2
      # install:
        make SHELL=$SHELL -C build stage2-install  # again, serial because flaky
        ln -s $out/lib/x86_64-unknown-linux-musl/* $out/lib/
        ln -s $out/bin/clang $out/bin/cc
        ln -s $out/bin/clang++ $out/bin/c++
        ln -s $out/bin/clang-cpp $out/bin/cpp
        ln -s $out/bin/lld $out/bin/ld
        # mixing new stuff into sysroot
        ln -s $out/lib/* $out/sysroot/lib/
    '';
  }
