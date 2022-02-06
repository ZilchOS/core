# TODO: get rid of initrd, boot to squashfs appended to iso?
{ name ? "ZilchOS-core-iso", mkCaDerivation
, linux, musl, busybox, nix
, zstd, limine, gnuxorriso }:

let
  version = "2022.02.1";
in
  mkCaDerivation {
    name = "ZilchOS-core-live-cd-${version}";

    outputs = [ "iso" "initscript" "initrd" "limine_config" ];

    builder = "${busybox}/bin/ash";
    args = [ "-uexc" ''
      PATH=${busybox}/bin

      cat > $initscript <<EOF
      #!${busybox}/bin/ash
      set -uex
      export PATH=${busybox}/bin
      echo 'Hello world!'
      mount -t devtmpfs devtmpfs /dev
      mount -t proc proc /proc
      mount -t sysfs sysfs /sys
      mkdir /dev/pts; mount -t devpts none /dev/pts -o mode=620
      setsid ash -c 'getty 0 /dev/tty0 &'
      exec setsid cttyhack ash
      EOF
      chmod +x $initscript

      mkdir initrd
      mkdir initrd/dev initrd/proc initrd/sys
      mkdir initrd/boot
      cp $initscript initrd/boot/rdinit
      mkdir -p initrd/nix/store
      cp -r ${musl} initrd/nix/store/
      cp -r ${busybox} initrd/nix/store/

      cd initrd
      find . | cpio --quiet -H newc -o | ${zstd}/bin/zstd -22 > $initrd
      cd ..

      cat > $limine_config <<EOF
      TIMEOUT=1
      VERBOSE=yes
      GRAPHICS=no

      : ZilchOS ${version}
      PROTOCOL=linux
      KERNEL_PATH=boot:///vmlinuz
      MODULE_PATH=boot:///initrd
      CMDLINE=rdinit=/boot/rdinit root=/dev/ram0 console=tty0 console=ttyS0
      TEXTMODE=yes
      RESOLUTION=1024x768
      EOF

      mkdir isoroot
      cp ${linux} isoroot/vmlinuz
      cp $initrd isoroot/initrd
      mkdir isoroot/boot
      cp $limine_config isoroot/boot/limine.cfg
      cp ${limine}/share/limine/limine.sys isoroot/boot/
      cp ${limine}/share/limine/limine-cd.bin isoroot/boot/
      cp ${limine}/share/limine/limine-eltorito-efi.bin isoroot/boot/

      ${gnuxorriso}/bin/xorriso \
        -as mkisofs \
        -b boot/limine-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --efi-boot boot/limine-eltorito-efi.bin \
        --efi-boot-part --efi-boot-image \
        --protective-msdos-label \
        isoroot -o $iso
      ${limine}/bin/limine-install $iso
    '' ];
  }
