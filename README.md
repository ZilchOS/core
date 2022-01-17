# ZilchOS Core

## What

An intentionally minimal **Linux** distribution based on **Nix**,
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
   but not as runtime dependencies)
* force t184256 to learn more Nix-lang and nixpkgs idioms
* give content-addressed Nix a spin
* have [a decent bootstrap seed/path](https://github.com/t184256/bootstrap-from-tcc)
* have fun

## Non-goals (Core)

* competing with NixOS
* systemd
* bootloaders
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
