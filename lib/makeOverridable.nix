# https://nixos.org/guides/nix-pills/override-design-pattern.html

let
  makeOverridable = f: origArgs:
    f origArgs // {
      override = newArgs: makeOverridable f (origArgs // newArgs);
    };
in makeOverridable

