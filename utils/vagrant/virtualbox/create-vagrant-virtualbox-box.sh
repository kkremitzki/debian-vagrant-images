#!/bin/sh
if test -z $1 || ! test -r $1; then
  echo "could not read disk image to convert $1"
  exit 1
fi

set -e
RAW_DISK=$1
VMDK="box.vmdk"
BOX="virtualbox-$(basename $RAW_DISK .raw).box"
SCRIPT_DIR="$(dirname $0)"

cleanup() {
  for FILE in box.ovf $VMDK; do
    rm -f $SCRIPT_DIR/$FILE
  done
}
trap cleanup INT TERM EXIT

set -x
qemu-img convert -O vmdk $RAW_DISK $SCRIPT_DIR/$VMDK
(
  cd $SCRIPT_DIR
  ./import2vbox --memory 512 --vcpus 2 $VMDK
)
echo '{"provider": "virtualbox"}' > $SCRIPT_DIR/metadata.json
tar --directory $SCRIPT_DIR \
  --sparse -czvf $BOX metadata.json box.ovf Vagrantfile $VMDK
