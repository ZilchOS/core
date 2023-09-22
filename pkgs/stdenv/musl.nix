{ pname ? "musl", fetchurl, stdenv, gnumake }:

stdenv.mkDerivation {
  inherit pname;
  version = "1.2.4";

  src = fetchurl {
    # local = /downloads/musl-1.2.4.tar.gz;
    url = "http://musl.libc.org/releases/musl-1.2.4.tar.gz";
    sha256 = "7a35eae33d5372a7c0da1188de798726f68825513b7ae3ebe97aaaa52114f039";
  };

  buildInputs = [ stdenv.clang stdenv.busybox gnumake ];

  postPatch = ''
      sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' tools/*.sh configure
      # patch popen/system to search in PATH instead of hardcoding /bin/sh
      sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' \
              src/stdio/popen.c src/process/system.c
      sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|'\
              src/misc/wordexp.c
      # avoid absolute path references
      sed -i 's/__FILE__/__FILE_NAME__/' include/assert.h
  '';

  extraConfigureFlags = [ "CFLAGS=-O2" ];
  extraBuildFlags = [ "CFLAGS=-O2" ];

  postInstall = ''
      mkdir -p $out/bin
      ln -s $out/lib/libc.so $out/bin/ldd
  '';

  allowedRequisites = [ "out" ];
  allowedReferences = [ "out" ];
}
