# path to the config space shoud be absolute, see fai.conf(5)

# mimics variables which are set by gitlab-ci
CLOUD_IMAGE_BUILD_ID = vagrant-cloud-images-master
export CI_PIPELINE_IID = 1
# this is how ./bin/debian-cloud-images build defines a version
VERSION := $(shell date '+%Y%m%d')-$(CI_PIPELINE_IID)

help:
	@echo "To run this makefile, run:"
	@echo "   make <DIST>-<CLOUD>-<ARCH>"
	@echo "  WHERE <DIST> is bullseye, buster, stretch or sid"
	@echo "    And <CLOUD> is azure, ec2, gce, generic, genericcloud, nocloud, vagrant"
	@echo "    And <ARCH> is amd64, arm64, ppc64el"

%:
	umask 022; \
	./bin/debian-cloud-images build \
	  $(subst -, ,$*) \
	  --build-id $(CLOUD_IMAGE_BUILD_ID) \
	  --build-type official

test-libvirt-%:
	# if raw disk image is missing, build it
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*

	# if box archive is missing, package it
	test -f libvirt-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/libvirt/create-vagrant-libvirt-box.sh \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw

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
	  utils/vagrant/libvirt/create-vagrant-libvirt-box.sh \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw

	#  upload box to vagrant cloud, using trickle to limit bandwith
	trickle -u 128  vagrant cloud publish --force debian-sandbox/$(word 1, $(subst -, ,$*))64 \
		$$(date '+%Y%m%d')-$${CI_PIPELINE_IID} libvirt \
		libvirt-debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.box

test-virtualbox-%:
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*
	test -f virtualbox-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/virtualbox/create-vagrant-virtualbox-box.sh \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw
	utils/vagrant/tests/vagrant-test virtualbox $* \
	  virtualbox-debian-$*-official-$(VERSION).box

upload-virtualbox-%:
	test -f debian-$*-official-$(VERSION).raw || $(MAKE) $*

	test -f libvirt-debian-$*-official-$(VERSION).box || \
	  utils/vagrant/virtualbox/create-vagrant-virtualbox-box.sh \
	  debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.raw
	trickle -u 128 vagrant cloud publish --force debian-sandbox/$(word 1, $(subst -, ,$*))64 \
		$$(date '+%Y%m%d')-$${CI_PIPELINE_IID} virtualbox \
		virtualbox-debian-$*-official-$$(date '+%Y%m%d')-$${CI_PIPELINE_IID}.box

clean:
	rm -rf debian-*.* *.box
