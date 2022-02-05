#!/usr/bin/env bash

[ -e .gitignore ]
mkdir -p .tmp

.maint/tools/build-using-ccache.sh linux -o.tmp/kernel-$$

qemu-system-x86_64 --accel kvm -m 256 -nographic \
	-kernel .tmp/kernel-$$ \
	-append console=ttyS0 "$@"

rm .tmp/kernel-$$
