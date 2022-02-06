{ name ? "ZilchOS-core-iso", mkCaDerivation
, linux, musl, busybox, nix
, squashfs-tools-ng, zstd }:

mkCaDerivation {
  name = "ZilchOS-core-iso-2022.02.1";

  builder = "${busybox}/bin/ash";
  args = [ "-uexc" ''
    PATH=${busybox}/bin

    mkdir store
    cp -r ${busybox} store/

    cat > init <<EOF
    #!${busybox}/bin/ash
    set -uex
    export PATH=${busybox}/bin
    echo 'Hello world!'
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mkdir /dev/pts; mount -t devpts none /dev/pts -o mode=620
    exec setsid cttyhack ash
    EOF
    chmod +x init

    cat > packfile <<EOF
    dir  /boot                   0550 0 0
    file /boot/init              0550 0 0 $(pwd)/init
    dir  /dev                    0555 0 0
    dir  /proc                   0555 0 0
    dir  /sys                    0555 0 0
    dir  /nix                    0555 0 0
    dir  /nix/store              0555 0 0
    glob ${musl}                 *    0 0 ${musl}
    glob ${busybox}              *    0 0 ${busybox}
    EOF
    cat packfile

    ${squashfs-tools-ng}/bin/gensquashfs -D / -F packfile $out
  '' ];
}
