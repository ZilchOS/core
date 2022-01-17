#!/usr/bin/env bash

# build with ccache and without /bin/sh present
# your nix needs experimental-options = ca-derivations
# and you need root access / to be a trusted user

set -ue

CCACHE_HOST=/var/cache/ccache
mkdir -p $CCACHE_HOST/data
sudo chgrp nixbld $CCACHE_HOST $CCACHE_HOST/data
sudo chmod g+ws $CCACHE_HOST $CCACHE_HOST/data

if [[ ! -e $CCACHE_HOST/bin/ccache ]]; then
	nix build 'nixpkgs#pkgsStatic.ccache' --out-link $CCACHE_HOST/result
	mkdir -p $CCACHE_HOST/bin
	cp --reflink=auto $CCACHE_HOST/result/bin/ccache $CCACHE_HOST/bin/ccache
	rm $CCACHE_HOST/result
fi

[[ -e $CCACHE_HOST/ccache.conf ]] || cat > $CCACHE_HOST/ccache.conf <<EOF
cache_dir = /ccache
compiler_check = content
compression = false
sloppiness = include_file_ctime,include_file_mtime
max_size = 0
umask = 005
EOF

[[ -e $CCACHE_HOST/setup ]] || cat > $CCACHE_HOST/setup <<\EOF
mkdir -p .ccache-wrappers
for prefix in '' x86_64-linux- x86_64-linux-musl- x86_64-linux-unknown-; do
	for name in cc c++ gcc g++ clang clang++ tcc; do
		if command -v $prefix$name; then
			ln -s /ccache/bin/ccache .ccache-wrappers/$prefix$name
		fi
	done
done
export PATH="$(pwd)/.ccache-wrappers:$PATH"
export CCACHE_CONFIGPATH=/ccache/ccache.conf
export CCACHE_DIR="/ccache/data/$1"
EOF
chmod +x $CCACHE_HOST/setup

sudo env "NIX_CONFIG=sandbox-paths = /ccache=$CCACHE_HOST" nix build "$@"
