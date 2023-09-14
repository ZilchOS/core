{ name ? "nix", stdenv, fetchurl, pkg-config, gnumake, editline, boost
, curl, libarchive, sqlite, libsodium, brotli, seccomp, lowdown, nlohmann_json
, linux-headers }:

#> FETCH f3f8016621cf3971e0768404f05b89d4a7fc1911dddae5a9a7ed4bf62519302c
#>  FROM https://github.com/ZilchOS/nix/releases/download/nix-2.17.0-zilched/nix-2.17.0-zilched.tar.xz

#> FETCH 3659cd137c320991a78413dd370a92fd18e0a8bc36d017d554f08677a37d7d5a
#>  FROM https://raw.githubusercontent.com/somasis/musl-compat/c12ea3af4e6ee53158a175d992049c2148db5ff6/include/sys/queue.h

let
  queue-h = fetchurl {
    # local = /downloads/queue.h;
    url = "https://raw.githubusercontent.com/somasis/musl-compat/c12ea3af4e6ee53158a175d992049c2148db5ff6/include/sys/queue.h";
    sha256 = "3659cd137c320991a78413dd370a92fd18e0a8bc36d017d554f08677a37d7d5a";
  };
in
  stdenv.mkDerivation {
    pname = name;
    version = "2.17.0-zilched";

    src = fetchurl {
      # local = /downloads/nix-2.17.0-zilched.tar.xz;
      url = "https://github.com/ZilchOS/nix/releases/download/nix-2.17.0-zilched/nix-2.17.0-zilched.tar.xz";
      sha256 = "f3f8016621cf3971e0768404f05b89d4a7fc1911dddae5a9a7ed4bf62519302c";
    };

    buildInputs = [
      pkg-config gnumake editline boost curl libarchive sqlite libsodium
      brotli seccomp lowdown nlohmann_json
    ];

    postPatch = ''
      sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure
      # avoid an expression confusing ash
      nl configure | grep 7217 | tee configure-problematic-line
      grep -F "'X\(//\)$'" configure-problematic-line
      sed -i '7217d' configure
      nl configure | grep 7217 | tee configure-problematic-line
      ! grep -F "'X\(//\)$'" configure-problematic-line
      # replace the declare confusing ash
      sed -i 's|declare \$name=.*|:|' configure
    '';

    configurePhase = ''
      mkdir stubs; export PATH="$(pwd)/stubs:$PATH"
      mkdir -p extra-includes/sys; cp ${queue-h} extra-includes/sys/queue.h
      ln -s ${stdenv.busybox}/bin/true stubs/jq
      ln -s ${stdenv.busybox}/bin/true stubs/expr
      ln -s ${stdenv.busybox}/bin/ash stubs/bash
      BROTLI_CFLAGS="$(pkg-config --cflags libbrotlidec)"
      NLOHMANN_CFLAGS="$(pkg-config --cflags nlohmann_json)"
      LINUX_CFLAGS="-I${linux-headers}/include"
      EXTRA_CFLAGS="$BROTLI_CFLAGS $NLOHMANN_CFLAGS $LINUX_CFLAGS"
      EXTRA_CFLAGS="$EXTRA_CFLAGS -Iextra-includes"
      # get rid of unneeded runtime dependency as described in [1]
      invalid=$(echo "${nlohmann_json}" | \
                sed -E "s|/[0-9a-z]{32}-|/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|")
      EXTRA_CFLAGS="$EXTRA_CFLAGS -fmacro-prefix-map=${nlohmann_json}=$invalid"
      ash ./configure \
        CFLAGS="$EXTRA_CFLAGS" \
        CXXFLAGS="$EXTRA_CFLAGS" \
        LDFLAGS="-L${boost.nixRuntimeMini}/lib -L${lowdown}/lib" \
        --prefix=$out \
        --sysconfdir=/etc \
        --with-boost=${boost.headers} \
        --disable-doc-gen \
        --disable-gc \
        --disable-cpuid \
        --disable-gtest \
        --with-sandbox-shell=${stdenv.busybox}/bin/busybox
      sed -i "s|\''${prefix}|$out|g" config.status
      sed -i "s|\''${exec_prefix}|$out|g" config.status
    '';

    installPhase = "make -j $NPROC install sysconfdir=$out/etc";

    postFixup = ''
      for p in \
          ${stdenv.clang.sysroot} \
          ${brotli} \
          ${lowdown} \
          ${editline} \
          ${libsodium} \
          ${libarchive} \
          ${sqlite} \
          ${boost.nixRuntimeMini} \
          ${curl} \
          ${seccomp} \
          ; do
        ${stdenv.patchelf}/bin/patchelf --add-rpath $p/lib $out/bin/nix
      done
    '';

    allowedRequisites = [
      "out" stdenv.clang.sysroot stdenv.musl
      stdenv.busybox brotli lowdown editline libsodium libarchive sqlite
      boost.nixRuntimeMini curl curl.mbedtls curl.ca-bundle seccomp
    ];
  }

# [1] https://trofi.github.io/posts/298-unexpected-runtime-dependencies-in-nixpkgs.html
