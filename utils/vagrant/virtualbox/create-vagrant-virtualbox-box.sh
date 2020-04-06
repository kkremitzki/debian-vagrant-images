#!/bin/bash
if test -z $1 || ! test -r $1; then
  echo "could not read disk image to convert $1"
  exit 1
fi

set -e
RAW_DISK=$1
VMDK="box.vmdk"
BOX="virtualbox-$(basename $RAW_DISK .raw).box"
SCRIPT_DIR="$(dirname $BASH_SOURCE)"

set -x
qemu-img convert -O vmdk $RAW_DISK $SCRIPT_DIR/$VMDK
(
  cd $SCRIPT_DIR
  ./import2vbox --memory 512 --vcpus 2 $VMDK
)
echo '{"provider": "virtualbox"}' > $SCRIPT_DIR/metadata.json
tar --directory $SCRIPT_DIR \
   -czvf $BOX metadata.json box.ovf Vagrantfile $VMDK
rm -f $SCRIPT_DIR/{box.ovf,$VMDK,box.ovf}
