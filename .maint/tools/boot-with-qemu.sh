#!/usr/bin/env bash

set -uex

: ${USE_CCACHE=0}

[ -e .gitignore ]
mkdir -p .tmp

if [[ "$USE_CCACHE" == 1 ]]; then
  ./.maint/tools/build-using-ccache.sh -o.tmp/linux-$$ linux
  ./.maint/tools/build-using-ccache.sh -o.tmp/iso-$$ iso
else
  nix build --option warn-dirty false -o.tmp/linux-$$ '.#linux'
  nix build --option warn-dirty false -o.tmp/iso-$$ '.#iso'
fi

qemu-system-x86_64 --accel kvm -m 512 -nographic \
  -kernel .tmp/linux-$$-kernel \
  -drive if=virtio,format=raw,media=disk,readonly=on,file=.tmp/iso-$$ \
  -append 'console=ttyS0 init=/boot/init rootfstype=squashfs root=/dev/vda ro' \
  "$@"

rm .tmp/linux-$$* .tmp/iso-$$*
