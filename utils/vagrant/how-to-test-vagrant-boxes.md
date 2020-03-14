# How to test Vagrant boxes

## libvirt

Provide you successfully built a box named boxed-image-bullseye-vagrant-amd64.box

1. Install vagrant-libvirt as explained in https://wiki.debian.org/Vagrant

2. Add the locally created box in the list of vagrant boxes
```
vagrant box add --name fai-0 --provider libvirt boxed-image-bullseye-vagrant-amd64.box
```

3. In a test directory, create a new vagrant environement
```
cd $MYDIR
vagrant init fai-0
vagrant up --provider=libvirt
vagrant ssh
```

4. Cleaning up
From your test directory, destroy the vagrant environment
```
vagrant destroy --force && rm Vagrantfile
``

Optionally remove the box
```
vagrant box remove fai-0
```



