{
  description = "ZilchOS Core";

  inputs.bootstrap-from-tcc.url = "github:ZilchOS/bootstrap-from-tcc";

  outputs = { self, bootstrap-from-tcc }: {
    packages.x86_64-linux = (import pkgs/default.nix) {
      bootstrap-musl = bootstrap-from-tcc.packages.x86_64-linux.libc;
      bootstrap-toolchain = bootstrap-from-tcc.packages.x86_64-linux.toolchain;
      bootstrap-busybox = bootstrap-from-tcc.packages.x86_64-linux.busybox;
    };
  };
}
