{ pname ? "musl", fetchurl, stdenv, gnumake }:

stdenv.mkDerivation {
  inherit pname;
  version = "1.2.2";

  src = fetchurl {
    # local = /downloads/musl-1.2.2.tar.gz;
    url = "http://musl.libc.org/releases/musl-1.2.2.tar.gz";
    sha256 = "9b969322012d796dc23dda27a35866034fa67d8fb67e0e2c45c913c3d43219dd";
  };

  buildInputs = [ stdenv.clang stdenv.busybox gnumake ];

  prePatch = ''
      sed -i 's|/bin/sh|${stdenv.busybox}/bin/ash|' tools/*.sh configure
      # patch popen/system to search in PATH instead of hardcoding /bin/sh
      sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' \
              src/stdio/popen.c src/process/system.c
      sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|'\
              src/misc/wordexp.c
  '';

  extraConfigureFlags = [ "CFLAGS='-O0 -g'" ];
  extraBuildFlags = [ "CFLAGS='-O0 -g'" ];

  postInstall = ''
      mkdir -p $out/bin
      ln -s $out/lib/libc.so $out/bin/ldd
  '';

  allowedRequisites = [ "out" ];
  allowedReferences = [ "out" ];
}
