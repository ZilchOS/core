#!/usr/bin/env bash

set -ex

D1=${1-./result-ccached}
D2=${2-./result}

D1=$(realpath "$D1")
D2=$(realpath "$D2")

set -u

ZEROED=/nix/store/00000000000000000000000000000000-
ZEROED_1=$(<<<"$D1" sed "s|/nix/store/[0-9a-z]*-|$ZEROED|")
ZEROED_2=$(<<<"$D2" sed "s|/nix/store/[0-9a-z]*-|$ZEROED|")
[[ "$ZEROED_1" == "$ZEROED_2" ]]

rm -rf ./.tmp/dehash_and_diff
mkdir -p ./.tmp/dehash_and_diff
cp -r "$D1" ./.tmp/dehash_and_diff/1
cp -r "$D2" ./.tmp/dehash_and_diff/2
chmod -R +rw ./.tmp/dehash_and_diff

find ./.tmp/dehash_and_diff/1 -type f | xargs sed -i "s|$D1|$ZEROED_1|g"
find ./.tmp/dehash_and_diff/2 -type f | xargs sed -i "s|$D2|$ZEROED_1|g"

find ./.tmp/dehash_and_diff/1 | xargs touch -h -t197001010000
find ./.tmp/dehash_and_diff/2 | xargs touch -h -t197001010000

diffoscope ./.tmp/dehash_and_diff/1 ./.tmp/dehash_and_diff/2 | less
