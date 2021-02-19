# path to the config space shoud be absolute, see fai.conf(5)

DESTDIR = .
# mimics variables which are set by gitlab-ci
CLOUD_IMAGE_BUILD_ID = vagrant-cloud-images-master
export CI_PIPELINE_IID = 1
# this is how ./bin/debian-cloud-images build defines a version
VERSION := $(shell date '+%Y%m%d')-$(CI_PIPELINE_IID)

NAMESPACE = debian-sandbox
IS_RELEASE = do-release

help:
	@echo "To run this makefile, run:"
	@echo "   make <DIST>-<CLOUD>-<ARCH>"
	@echo "  WHERE <DIST> is bullseye, buster, stretch, sid or testing"
	@echo "    And <CLOUD> is azure, ec2, gce, generic, genericcloud, nocloud, vagrant, vagrantcontrib"
	@echo "    And <ARCH> is amd64, arm64, ppc64el"
	@echo "Set DESTDIR= to write images to given directory."

%:
	umask 022; \
	./bin/debian-cloud-images build \
	  $(subst -, ,$*) \
	  --build-id $(CLOUD_IMAGE_BUILD_ID) \
	  --build-type official

install-build-deps:
	sudo apt install -y --no-install-recommends ca-certificates debsums dosfstools \
    fai-server fai-setup-storage make python3 python3-libcloud python3-marshmallow \
    python3-pytest python3-yaml qemu-utils udev \
    libguestfs-perl libxml-writer-perl uuid-runtime

build-libvirt-%:
	# if raw disk image is missing, build it
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*

	# if box archive is missing, package it
	test -f libvirt-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/libvirt/create-vagrant-libvirt-box \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw

test-libvirt-%:
	# boot a Vagrant env based on that box, run E2E tests
	utils/vagrant/tests/vagrant-test libvirt $* \
	  libvirt-debian-$*-official-$(VERSION).box

	# workaround for https://github.com/vagrant-libvirt/vagrant-libvirt/issues/85
	virsh vol-delete --pool default test-$*_vagrant_box_image_0.img || true

upload-libvirt-%:
	# if raw disk image is missing, build it
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*

	# if box archive is missing, package it
	test -f libvirt-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/libvirt/create-vagrant-libvirt-box \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw

	#  upload box to vagrant cloud, using trickle to limit bandwith
	trickle -su 128  utils/vagrant/release \
		libvirt-debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.box \
       $(NAMESPACE) $(IS_RELEASE)

build-virtualbox-%:
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*
	test -f virtualbox-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/virtualbox/create-vagrant-virtualbox-box \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw

test-virtualbox-%:
	utils/vagrant/tests/vagrant-test virtualbox $* \
	  virtualbox-debian-$*-official-$(VERSION).box

upload-virtualbox-%:
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*
	test -f virtualbox-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/virtualbox/create-vagrant-virtualbox-box \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw
	trickle -su 128 utils/vagrant/release \
	  virtualbox-debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.box \
	  $(NAMESPACE) $(IS_RELEASE)

clean:
	rm -rf debian-*.* *.box
