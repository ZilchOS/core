# ZilchOS Core

## Try

Download an image from releases,
`qemu-system-x86_64 -cdrom ZilchOS-core-*.iso`.

`-nographic` can be specified
to pop up no windows and use a serial port instead,
press `Control-a` followed by an `x` to quit.

The coolest thing to do from there is, probably,
`nix build -j1 github:ZilchOS/core`. \
That requires a ton of space and CPU though,
`qemu-system-x86_64 -machine q35,accel=kvm -cpu host -smp 16 -m 16G -cdrom ZilchOS-core-*.iso`, maybe?

## What

An minimal viable **Linux** distribution based on **Nix**,
**musl**, **clang** and **busybox**.
(well, not yet, but give it a bit of time).

[Bootstrapped from a single TinyCC binary.](https://github.com/t184256/bootstrap-from-tcc)

## Why

Ever wanted to see how to put Nix derivations together into something bootable?
Or get rid of `/bin/sh` or `/etc`,
or break up nixpkgs into a gazillion flakes,
but found one of the largest Linux distros
a bit too large for such experimenting?

Yeah, maybe not, but here's a toy Nix-based OS to play with anyway.

## Goals

* offer just **musl**, **clang**, **busybox**, **Nix** and **Linux**
* target only one platform: x86_64 QEMU
* be lean enough to experiment on
* avoid GNU software where possible
  (build-time dependencies of the 5 key packages are allowed,
   but not as runtime dependencies;
   the current situation is particularly bad in the bootloader area)
* force t184256 to learn more Nix-lang and nixpkgs idioms
* give content-addressed Nix a spin
* have [a decent bootstrap seed/path](https://github.com/t184256/bootstrap-from-tcc)
* have fun

## Non-goals (Core)

* competing with NixOS
* going beyond a Live CD
* systemd
* any software, basically
* flexibility (other than just being small)
* portability
* configurability
* stability
* usability
* practicality

## Stretch goals

* become something like Nix pills, but for building an OS
* become a stepping stone to a tad richer distro
  (like, one with systemd or *gasp* git)

## Misc

### Execute a custom script inside a VM

To spin up a VM, execute `/path/to/bootscript` and spin it back down, you can do `qemu-system-x86_64 -cdrom ZilchOS*.iso -nographic -device e1000,netdev=u -netdev user,id=u,tftp=/path/to -smbios type=11,value=zilchos:b=tftp://10.0.2.2:69/bootscript`, or just `.maint/tools/exec-in-vm $QEMU_OPTS /path/to/bootscript`.

## Reproducibility

Reproducibility is deeply cared about,
but it's a constant struggle and one cannot foresee everything.

Derivations are checked to built to the same hashes
when built in three different ways:

* `nix=nixos` are just builds using Nix from a relatively recent NixOS unstable.
  Verification is done with `.maint/tools/hashes`.
* `nix=bootstrap` are builds make with Nix built during bootstrap-from-tcc's
  stage3. They don't use sandboxing and run in a peculiar environment.
  See `helpers/maint/build-custom-stage5` in bootstrap-from-tcc.
  The used commit of bootstrap-from-tcc is the one from `flake.lock`.
* `nix=zilchos` are builds done inside a ZilchOS Core VM using its own Nix.
  Verification is also done with `.maint/tools/hashes`.

I try to build on different machines and note down the results in `git notes`.
Commits require a specific (but adjustable) amount of successful
`nix`, `bootstrap` and `zilchos` builds before getting into the main branch.
