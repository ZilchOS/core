#!/usr/bin/env bash

: ${USE_CCACHE=0}

[ -e .gitignore ]
mkdir -p .tmp

if [[ "$USE_CCACHE" == 1 ]]; then
  ./.maint/tools/build-using-ccache.sh -o.tmp/kernel-$$ linux
else
  nix build ".#linux" --option warn-dirty false -o .tmp/kernel-$$
fi

qemu-system-x86_64 --accel kvm -m 256 -nographic \
  -kernel .tmp/kernel-$$ \
  -append console=ttyS0 "$@"

rm .tmp/kernel-$$
