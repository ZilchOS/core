#!/usr/bin/env bash

set -uex

[ -e .gitignore ]
mkdir -p .tmp

./.maint/tools/build-using-ccache.sh -o.tmp/kernel-$$ linux.config

cat .tmp/kernel-$$-config |
  grep -v 'is not set' |
  grep -v '^# end of' |
  grep -v '^#$' |
  grep -v '^$' |
  cat

rm .tmp/kernel-$$-config
