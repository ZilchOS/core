{
  description = "ZilchOS Core";

  inputs.bootstrap-from-tcc.url = "github:ZilchOS/bootstrap-from-tcc";

  outputs = { self, bootstrap-from-tcc }:
    let
      bootstrapPkgs = bootstrap-from-tcc.packages.x86_64-linux;
      input = {
        bootstrap-musl = bootstrapPkgs.libc;
        bootstrap-toolchain = bootstrapPkgs.toolchain;
        bootstrap-busybox = bootstrapPkgs.busybox;
      };
      corePkgs = (import ./pkgs) input;
    in
      {
        packages.x86_64-linux = corePkgs;

        ccachedPackages =
          (import ./pkgs) (input // { use-ccache = true; });
        lib = (import ./lib);  # a non-standard output

        hydraJobs = builtins.mapAttrs (_: drv: {x86_64-linux = drv;}) corePkgs;
      };
}
