# TODO: get rid of initrd, boot to squashfs appended to iso?
{ name ? "ZilchOS-core-iso", mkCaDerivation
, linux, musl, busybox, nix
, zstd, limine, gnuxorriso }:

let
  version = "2022.03.1";
in
  mkCaDerivation {
    name = "ZilchOS-core-live-cd-${version}";

    outputs = [
      "iso"
      "initrd"
      "limine_config"
      "initscript"
    ];

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
      setsid ash -c 'getty -n -l ${busybox}/bin/ash 0 /dev/tty0 &'
      exec setsid cttyhack ash
      EOF
      chmod +x $initscript
      touch -d @0 $initscript

      cat > packlist <<EOF
      dir  /boot                    0550 0 0
      file /boot/rdinit $initscript 0550 0 0
      dir  /dev                     0555 0 0
      dir  /proc                    0555 0 0
      dir  /sys                     0555 0 0
      dir  /root                    0550 0 0
      dir  /nix                     0555 0 0
      dir  /nix/store               0555 0 0
      EOF
      included='${musl} ${busybox}'
      for derivation in $included; do
        find $derivation -type d | sort > dirlist
        while IFS= read -r dir || [ -n "$dir" ]; do
          mode=$(stat -c %a "$dir")
          echo "dir $dir $mode 0 0" >> packlist
        done < dirlist
        find $derivation -type f | sort > filelist
        while IFS= read -r file || [ -n "$file" ]; do
          mode=$(stat -c %a "$file")
          echo "file $file $file $mode 0 0" >> packlist
        done < filelist
        find $derivation -type l | sort > linklist
        while IFS= read -r link || [ -n "$link" ]; do
          mode=$(stat -c %a "$link")
          target=$(readlink "$link")
          echo "slink $link $target $mode 0 0" >> packlist
        done < linklist
      done
      # TODO: perform hardlinking optimization on /nix/store?
      cat packlist

      ${linux.gen_init_cpio} -t0 packlist > uncompressed.cpio
      ${zstd}/bin/zstd -22 < uncompressed.cpio > $initrd
      touch -d @0 $initrd

      cat > $limine_config <<EOF
      TIMEOUT=1
      VERBOSE=yes
      GRAPHICS=no
      SERIAL=yes

      : ZilchOS Core ${version}
      PROTOCOL=linux
      KERNEL_PATH=boot:///vmlinuz
      MODULE_PATH=boot:///initrd
      CMDLINE=rdinit=/boot/rdinit root=/dev/ram0 console=tty0 console=ttyS0
      TEXTMODE=yes
      EOF

      mkdir isoroot
      cp ${linux} isoroot/vmlinuz
      cp $initrd isoroot/initrd
      mkdir isoroot/boot
      cp $limine_config isoroot/boot/limine.cfg
      cp ${limine}/share/limine/limine.sys isoroot/boot/
      cp ${limine}/share/limine/limine-cd.bin isoroot/boot/
      cp ${limine}/share/limine/limine-eltorito-efi.bin isoroot/boot/
      find isoroot | xargs touch -d @0

      SOURCE_DATE_EPOCH=0 \
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
