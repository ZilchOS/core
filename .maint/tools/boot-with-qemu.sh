#!/usr/bin/env bash

set -uex

: ${USE_CCACHE=0}

[ -e .gitignore ]
mkdir -p .tmp

if [[ "$USE_CCACHE" == 1 ]]; then
  ./.maint/tools/build-using-ccache.sh -o.tmp/live-cd-$$ live-cd.iso
else
  nix build --option warn-dirty false -o.tmp/live-cd-$$ '.#live-cd^iso'
fi

qemu-system-x86_64 --accel kvm -m 512 -cdrom .tmp/live-cd-$$-iso "$@"

rm .tmp/live-cd-$$*
