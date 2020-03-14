#!/bin/bash
if test -z $1 || ! test -r $1; then
  echo "could not read disk image to convert $1"
  exit 1
fi

set -e
RAW_DISK=$1
BOX="boxed-$(basename ${RAW_DISK} .raw).box"
SCRIPT_DIR="$(dirname $BASH_SOURCE)"

set -x
qemu-img convert -O qcow2 $RAW_DISK box.img
ln box.img $SCRIPT_DIR/box.img
tar --directory $SCRIPT_DIR \
   -czf $BOX box.img Vagrantfile metadata.json
rm -f box.img $SCRIPT_DIR/box.img
