#!/bin/bash

# create new root partition
sgdisk --new=1:0:0 /dev/sda
# set legacy boot flag
sgdisk /dev/sda --attributes=1:set:2
# create 'safe' ext4 filesystem
mkfs.ext4 -q -L root /dev/sda1
# mount root for installation
mount /dev/sda1 /mnt

# archlinux installation
pacstrap /mnt base
arch-chroot /mnt pacman -S --noconfirm \
	syslinux openssh sudo bash-completion virtualbox-guest-modules \
	virtualbox-guest-utils nfs-utils
arch-chroot /mnt syslinux-install_update -i -m
sed -e 's/sda3/sda1/g' \
	-e 's/TIMEOUT.*/TIMEOUT 05/' \
	-i /mnt/boot/syslinux/syslinux.cfg
genfstab -p /mnt >> /mnt/etc/fstab

# basic configuration
echo 'archlinux.vagrant' > /mnt/etc/hostname
echo 'KEYMAP=be-latin1' > /mnt/etc/vconsole.conf
sed -e 's/#en_US.UTF-8/en_US.UTF-8/' -i /mnt/etc/locale.gen
sed -e 's/#UseDNS.*/UseDNS no/' -i /mnt/etc/ssh/sshd_config
echo -e "vboxguest\nvboxsf\nvboxvideo" \
	> /mnt/etc/modules-load.d/virtualbox-modules.conf
arch-chroot /mnt locale-gen
arch-chroot /mnt ln -s /usr/share/zoneinfo/UTC /etc/localtime
arch-chroot /mnt mkinitcpio -p linux
arch-chroot /mnt ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
arch-chroot /mnt systemctl enable 'dhcpcd@eth0.service'
arch-chroot /mnt systemctl enable 'sshd.service'
arch-chroot /mnt systemctl enable 'vboxservice.service'

# vagrant user
arch-chroot /mnt groupadd vagrant
arch-chroot /mnt useradd -p $(openssl passwd -crypt 'vagrant') \
	-c 'vagrant user' -g vagrant -G vboxsf -d /home/vagrant \
	-s /bin/bash -m vagrant
echo -e "Defaults env_keep += \"SSH_AUTH_SOCK\"\nvagrant ALL=(ALL) NOPASSWD: ALL" \
	> /mnt/etc/sudoers.d/vagrant
chmod 0440 /mnt/etc/sudoers.d/vagrant
arch-chroot /mnt install -dm0700 -g vagrant -o vagrant /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" \
	> /mnt/home/vagrant/.ssh/authorized_keys
arch-chroot /mnt chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
arch-chroot /mnt chmod 0600 /home/vagrant/.ssh/authorized_keys

arch-chroot /mnt pacman -Scc --noconfirm

# disable root user
arch-chroot /mnt passwd root -l

