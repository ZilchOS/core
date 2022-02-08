{ name ? "nix", stdenv, fetchurl, pkg-config, gnumake, gnubash, editline, boost
, curl, libarchive, sqlite, libsodium, brotli, seccomp, lowdown
, linux-headers }:

let
  queue-h = fetchurl {
    # local = /downloads/queue.h;
    url = "https://raw.githubusercontent.com/somasis/musl-compat/c12ea3af4e6ee53158a175d992049c2148db5ff6/include/sys/queue.h";
    sha256 = "3659cd137c320991a78413dd370a92fd18e0a8bc36d017d554f08677a37d7d5a";
  };
in
  stdenv.mkDerivation {
    pname = name;
    version = "2.5.1-zilched";

    src = fetchurl {
      # local = /downloads/nix-2.5.1-zilched.tar.xz;
      url = "https://github.com/ZilchOS/nix/releases/download/nix-2.5.1-zilched/nix-2.5.1-zilched.tar.xz";
      sha256 = "bb2e48c487e736916583233ab63fde898117161c0107a2aa3008387a53b40101";
    };

    buildInputs = [
      pkg-config gnumake gnubash editline boost curl libarchive sqlite libsodium
      brotli seccomp lowdown
    ];

    postPatch = "sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' configure";

    configurePhase = ''
      mkdir stubs; export PATH="$PATH:$(pwd)/stubs"
      mkdir -p extra-includes/sys; cp ${queue-h} extra-includes/sys/queue.h
      ln -s ${stdenv.busybox}/bin/true stubs/jq
      BROTLI_CFLAGS="$(pkg-config --cflags libbrotlidec)"
      LINUX_CFLAGS="-I${linux-headers}/include"
      EXTRA_CFLAGS="$BROTLI_CFLAGS $LINUX_CFLAGS -Iextra-includes"
      sed -i "s|^CFLAGS=$|CFLAGS='$EXTRA_CFLAGS'|" configure
      sed -i "s|^CXXFLAGS=$|CXXFLAGS='$EXTRA_CFLAGS'|" configure
      ${gnubash}/bin/bash ./configure \
        LDFLAGS="-L${boost.nixRuntimeMini}/lib -L${lowdown}/lib" \
        --prefix=$out \
        --with-boost=${boost.headers} \
        --disable-doc-gen \
        --disable-gc \
        --disable-cpuid \
        --disable-gtest \
        --with-sandbox-shell=${stdenv.busybox}/bin/busybox
    '';

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
