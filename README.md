# ioi2021-image (for garytang only)

## Install/Setup

Create a VM: 2 VCPU, 4 GB RAM, 25 GB disk.

Install Ubuntu 20.04 server. Defaults work fine (but please uncheck the "Set up this disk as an LVM group" option). Create a user account called ansible.

When Ubuntu install completes, clone or copy this repo into a local directory. E.g.:

```
git clone https://github.com/gary-tang/ioi2021-image.git
cd ioi2021-image
sudo ./setup.sh
sudo ./cleanup.sh
cd ..
rm -rf ioi2021-image
```


## VM Image Finalisation

Boot into install or rescure CDROM (change the boot order if required). Get to a shell (Ctrl+Alt+F2) and zero-out the empty space in the ext4 FS.

$ sudo zerofree -v /dev/sda2

Shutdown the VM.

In the VM settings:

- Remove all CDROM and floppy drives.
- In the Hard Disk device, click Defragment, then click Compact.

Go to File, Export to OVF, then enter a filename with .ova extension.
- 
