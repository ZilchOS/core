#!/usr/bin/env sh

: ${UPDATE=0}
: ${USE_CCACHE=0}
: ${SERIAL=0}

set -ue

if [ "$SERIAL" != 1 ]; then
    # first build everything from .maint/hashes in parallel
    targets=''
    while IFS=" " read -r _ pkg; do
	if [ "$USE_CCACHE" == 1 ]; then
	    targets="$targets $pkg"
	else
	    targets="$targets .#$pkg"
	fi
    done < .maint/hashes
    if [ "$USE_CCACHE" == 1 ]; then
	./.maint/tools/build-using-ccache.sh --no-link $targets "$@"
    else
	nix build --option warn-dirty false --no-link $targets "$@"
    fi
fi

# then print the hash differences and update the hashfile
RET=0
if [ "$UPDATE" == 1 ]; then mkdir -p .tmp; :> .tmp/out-$$; fi
while IFS=" " read -r old_hash pkg; do
    if [ "$USE_CCACHE" == 1 ]; then
	./.maint/tools/build-using-ccache.sh -o.tmp/res-$$ "$pkg" "$@"
    else
	nix build ".#$pkg" --option warn-dirty false -o .tmp/res-$$ "$@"
    fi
    new_path=$(readlink .tmp/res-$$*)
    new_hash=$(echo $new_path | sed -E 's|.*/([a-z0-9]{32})-.*|\1|')
    rm .tmp/res-$$*
    if [ "$new_hash" == "$old_hash" ]; then
        echo "  $old_hash $pkg"
    else
        echo "- $old_hash $pkg"
        echo "+ $new_hash $pkg"
        RET=1
    fi
    if [ "$UPDATE" == 1 ]; then echo "$new_hash $pkg" >> .tmp/out-$$; fi
done < .maint/hashes

if [ "$UPDATE" == 1 ]; then
    mv .tmp/out-$$ .maint/hashes;
else
    exit $RET
fi
