# https://nixos.org/guides/nix-pills/callpackage-design-pattern.html

set: path: overrides:
  let f = import path;
  in f ((builtins.intersectAttrs (builtins.functionArgs f) set) // overrides)
