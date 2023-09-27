#!/usr/bin/env bash

set -ex

D1=${1-./result-ccached}
D2=${2-./result}

D1=$(realpath "$D1")
D2=$(realpath "$D2")

H1=$(echo "$D1" | sed -E 's|.*(/nix/store/[0-9a-z]*-.*)|\1|')
H2=$(echo "$D2" | sed -E 's|.*(/nix/store/[0-9a-z]*-.*)|\1|')

set -u

ZEROED=/nix/store/00000000000000000000000000000000-
ZEROED_1=$(<<<"$H1" sed "s|/nix/store/[0-9a-z]*-|$ZEROED|")
ZEROED_2=$(<<<"$H2" sed "s|/nix/store/[0-9a-z]*-|$ZEROED|")
[[ "$ZEROED_1" == "$ZEROED_2" ]]

rm -rf ./.tmp/dehash_and_diff
mkdir -p ./.tmp/dehash_and_diff
cp -r "$D1" ./.tmp/dehash_and_diff/1
cp -r "$D2" ./.tmp/dehash_and_diff/2
chmod -R +rw ./.tmp/dehash_and_diff

find ./.tmp/dehash_and_diff/1 -type f -print0 | xargs -0 sed -i "s|$H1|$ZEROED_1|g"
find ./.tmp/dehash_and_diff/2 -type f -print0 | xargs -0 sed -i "s|$H2|$ZEROED_1|g"

find ./.tmp/dehash_and_diff/1 -print0 | xargs -0 touch -h -t197001010000
find ./.tmp/dehash_and_diff/2 -print0 | xargs -0 touch -h -t197001010000

diff -qr ./.tmp/dehash_and_diff/1 ./.tmp/dehash_and_diff/2
