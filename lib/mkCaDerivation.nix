# derivation, but content-addressed by default
# and with our only supported system hardcoded in

args:

derivation ({
  system = "x86_64-linux";
  __contentAddressed = true;
  outputHashAlgo = "sha256"; outputHashMode = "recursive";
} // args)


