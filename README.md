packer templates
================

archlinux
---------

### building

Both i686 and x86_64 are supported.

~~~ sh
$ cd archlinux
$ packer-io build archlinux-i686.json # i686
$ packer-io build archlinux-x86_64.json # x86_64
~~~

### add as vagrant base box

~~~ sh
$ vagrant add --name archlinux32 archlinux-i686-virtualbox.box
$ vagrant add --name archlinux64 archlinux-x86_64-virtualbox.box
~~~
