{
  description = "ZilchOS Core";

  inputs.bootstrap-from-tcc.url = "github:ZilchOS/bootstrap-from-tcc";

  outputs = { self, bootstrap-from-tcc }:
    let
      bootstrapPkgs = bootstrap-from-tcc.packages.x86_64-linux;
      inputPkgs = {
        bootstrap-musl = bootstrapPkgs.libc;
        bootstrap-toolchain = bootstrapPkgs.toolchain;
        bootstrap-busybox = bootstrapPkgs.busybox;
      };
      corePkgs = (import pkgs/default.nix) inputPkgs;
    in
      {
        packages.x86_64-linux = corePkgs;

        lib = (import ./lib);  # a non-standard output

        hydraJobs = builtins.mapAttrs (_: drv: {x86_64-linux = drv;}) corePkgs;
      };
}
