#!/usr/bin/env bash

: ${UPDATE=0}
: ${USE_CCACHE=0}
: ${SERIAL=0}

set -ue

if [[ "$SERIAL" != 1 ]]; then
    # first build everything from .maint/hashes in parallel
    targets=''
    while IFS=" " read -r _ pkg; do
	if [[ "$USE_CCACHE" == 1 ]]; then
	    targets+=" $pkg"
	else
	    targets+=" .#$pkg"
	fi
    done < .maint/hashes
    if [[ "$USE_CCACHE" == 1 ]]; then
	./.maint/tools/build-using-ccache.sh --no-link $targets "$@"
    else
	nix build --no-link $targets "$@"
    fi
fi

# then print the hash differences and update the hashfile
if [[ "$UPDATE" == 1 ]]; then mkdir -p .tmp; :> .tmp/out-$$; fi
while IFS=" " read -r old_hash pkg; do
    if [[ "$USE_CCACHE" == 1 ]]; then
	./.maint/tools/build-using-ccache.sh -o.tmp/res-$$ "$pkg" "$@" \
	    2>/dev/null
    else
	nix build ".#$pkg" -o .tmp/res-$$ "$@" 2>/dev/null
    fi
    new_hash=$(basename $(readlink .tmp/res-$$*))
    rm .tmp/res-$$*
    [[ $new_hash =~ ^([a-z0-9]{32})-.* ]]
    new_hash=${BASH_REMATCH[1]}
    if [[ "$old_hash" == "$new_hash" ]]; then
	    echo "  $old_hash $pkg"
    else
	    echo "- $old_hash $pkg"
	    echo "+ $new_hash $pkg"
    fi
    if [[ "$UPDATE" == 1 ]]; then echo "$new_hash $pkg" >> .tmp/out-$$; fi
done < .maint/hashes
# TODO: possibly with ccache

if [[ "$UPDATE" == 1 ]]; then mv .tmp/out-$$ .maint/hashes; fi
