# Yes, there's builtin.fetchurl.
# No, it doesn't work in restricted eval mode, meaning it doesn't work in Hydra
# This does:

{ url, sha256 }:

derivation {
  builder = "builtin:fetchurl"; system = "builtin"; preferLocalBuild = true;
  outputHashMode = "flat"; outputHashAlgo = "sha256"; outputHash = sha256;

  name = builtins.baseNameOf url;
  inherit url; urls = [ url ];
  unpack = false;
}
