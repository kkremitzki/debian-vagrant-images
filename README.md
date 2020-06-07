# FAI vagrant image builder

This repository aims to build the Debian Vagrant base boxes available at 
https://app.vagrantup.com/debian
See that URL for the end user documentation.
This repository is based on a fork of https://salsa.debian.org/cloud-team/debian-cloud-images and tries to minimize changes to vagrant specific changes when possible.

## Getting started

You will need a checkout of this repository on your disk and a recent fai-server
package (at least 5.7) installed. Install the necessary fai packages without
the recommends (which avoids turning your host into a DHCP server!).
You also need python3-libcloud from Buster or newer.

```
  # git clone https://salsa.debian.org/cloud-team/debian-vagrant-images.git
  # sudo apt install --no-install-recommends ca-certificates debsums dosfstools \
    fai-server fai-setup-storage make python3 python3-libcloud python3-marshmallow \
    python3-pytest python3-yaml qemu-utils udev
```

  Call `make help` and follow the instructions

Example 1:

```
   # make stretch-vagrant-amd64
```

This will create some log output and the following files:

- debian-stretch-nocloud-amd64-official-20200421-1.build.json
- debian-stretch-nocloud-amd64-official-20200421-1.info
- debian-stretch-nocloud-amd64-official-20200421-1.raw
- debian-stretch-nocloud-amd64-official-20200421-1.raw.tar

## Boxes creation

To convert the raw disk images into a usable vagrant box you will need
```
# apt install libxml-writer-perl libguestfs-perl uuid-runtime
```

## Box creation and E2E test suite
To run the test suite you will also need
```
apt install vagrant vagrant-libvirt virtualbox
```

Then if you call
```
make test-virtualbox-stretch-vagrant-amd64
```
a box called virtualbox-debian-stretch-vagrant-amd64-official-20200421-1.box
will be created in the current directory, and a test environment based on this box will run the e2e tests.

## Uploading boxes to Vagrant Cloud
To upload the boxes via make, you will need:
- the trickle package, which is a bandwidth usage limiter
- the VAGRANT_CLOUD_TOKEN set as an environment variable

Then if you call
```
   #  make NAMESPACE=debian IS_RELEASE=norelease test-virtualbox-stretch-vagrant-amd64
```
The box virtualbox-debian-stretch-vagrant-amd64-official-20200421-1.box will be uploaded to 
'https://app.vagrantup.com/debian/', and you will have to release it manually.

