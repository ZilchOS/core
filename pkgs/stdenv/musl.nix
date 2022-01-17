{ name ? "musl", fetchurl, mkDerivation, toolchain, busybox, gnumake }:

let
  source-tarball-musl = fetchurl {
    # local = /downloads/musl-1.2.2.tar.gz;
    url = "http://musl.libc.org/releases/musl-1.2.2.tar.gz";
    sha256 = "9b969322012d796dc23dda27a35866034fa67d8fb67e0e2c45c913c3d43219dd";
  };
in
  mkDerivation {
    inherit name;
    buildInputs = [ toolchain busybox gnumake ];
    script = ''
      # unpack:
        unpack ${source-tarball-musl}
      # fixup:
        sed -i 's|/bin/sh|${busybox}/bin/ash|' tools/*.sh \
        # patch popen/system to search in PATH instead of hardcoding /bin/sh
        sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' \
                src/stdio/popen.c src/process/system.c
        sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|'\
                src/misc/wordexp.c
      # configure:
        ash ./configure --prefix=$out CFLAGS='-O2'
      # build:
        make -j $NPROC
      # install:
        make -j $NPROC install
        mkdir -p $out/bin
        ln -s $out/lib/libc.so $out/bin/ldd
    '';
    extra.allowedRequisites = [ "out" ];
    extra.allowedReferences = [ "out" ];
  }
