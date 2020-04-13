#!/bin/sh
if test -z $1 || ! test -r $1; then
  echo "could not read disk image to convert $1"
  exit 1
fi

set -e
RAW_DISK=$1
BOX="libvirt-$(basename ${RAW_DISK} .raw).box"
SCRIPT_DIR="$(dirname $0)"

cleanup() {
  rm -f box.img $SCRIPT_DIR/box.img
}
trap cleanup INT TERM EXIT

set -x
qemu-img convert -O qcow2 $RAW_DISK box.img
ln box.img $SCRIPT_DIR/box.img
tar --directory $SCRIPT_DIR \
  --sparse -czvf $BOX box.img Vagrantfile metadata.json
