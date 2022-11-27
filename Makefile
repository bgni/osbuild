# LINUX_GITDIR := ext/linux
BUILD_DIR = build3
#EXTERNAL_SRC := ext
#EXTERNAL_LINUX := $(EXTERNAL_SRC)/linux
SHARED_SRC_URL=$(addprefix $(HOME),/build_setup/dev_src)

LINUX_ORIGIN := $(addprefix $(SHARED_SRC_URL)/, github.com/torvalds/linux.git)
KERNELUTILS_ORIGIN := $(addprefix $(SHARED_SRC_URL)/, github.com/aweeraman/kernel-utils.git)
BUSYBOX_ORIGIN := $(addprefix $(SHARED_SRC_URL)/, github.com/mirror/busybox.git)
SYSTEMD_ORIGIN := $(addprefix $(SHARED_SRC_URL)/, github.com/systemd/systemd.git)


LINUX_SRC := $(addprefix $(BUILD_DIR)/, linux.git)
LINUX_SRC_GIT := $(addprefix $(LINUX_SRC)/, .git)
KERNELUTILS_SRC := $(addprefix $(BUILD_DIR)/, kernelutils)
BUSYBOX_SRC := $(addprefix $(BUILD_DIR)/, busybox)
SYSTEMD_SRC := $(addprefix $(BUILD_DIR)/, systemd)

INITRAMFS_DIR := $(addprefix $(BUILD_DIR)/, initramfs)
INITRAMFS_SUBDIRS := bin dev etc home mnt proc sys usr

BZ_LINUX := $(LINUX_SRC)/arch/x86/boot/bzImage
KERNELUTILS := $(KERNELUTILS_SRC)
# BUSYBOX_BINARY := $(BUSYBOX_SRC)/busybox
# BUSYBOX_CONFIG := $(BUSYBOX_SRC)/.config
IRSUBS := $(addprefix $(INITRAMFS_DIR)/,$(INITRAMFS_SUBDIRS))
BUSYBOX_ROOT_FS = $(addprefix $(BUILD_DIR)/, root_fs)
INITRAMFS_CPIO_GZ := $(BUILD_DIR)/initramfs.cpio.gz
INITRAMFS_CPIO_XZ := $(BUILD_DIR)/initramfs.cpio.xz
INITRAMFS_CPIO := $(BUILD_DIR)/initramfs.cpio
all: show
	file "$(LINUX_SRC_GIT)"
# 	$(INITRAMFS_CPIO_GZ) $(INITRAMFS_DIR)/bin/busybox
# 	$(LINUX_SRC_GIT)
# all: $(LINUX_SRC)/arch/x86/boot/bzImage
# 	echo "L: $(LINUX_SRC)/arch/x86/boot/bzImage"
# 	$(BUSYBOX_SRC)/busybox 
# 	$(BUSYBOX_ROOT_FS) initram
# 	echo "Sbs:" $(IRSUBS)
# 	$(INITRAMFS_DIR)/bin
# 	build3/busybox/busybox
# 	$(BUSYBOX_BINARY)


# $(KERNELUTILS)

$(LINUX_SRC)/.config: $(LINUX_SRC_GIT)
	stat $(LINUX_SRC)/.config
# 	make -C $(LINUX_SRC) tinyconfig

$(BZ_LINUX): $(LINUX_SRC)/.config initram
	make -C $(LINUX_SRC) -j2
	ls -lah $(BZ_LINUX)
	
$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(SYSTEMD_SRC)/.git: $(BUILD_DIR)
	echo "Cloning $(SYSTEMD_ORIGIN) -> $(SYSTEMD_SRC)"
	git clone -sl $(SYSTEMD_ORIGIN) $(SYSTEMD_SRC)


$(KERNELUTILS_SRC)/.git: $(BUILD_DIR)
	echo "Cloning $(KERNELUTILS_ORIGIN) -> $(KERNELUTILS_SRC)"
	git clone -sl $(KERNELUTILS_ORIGIN) $(KERNELUTILS_SRC)

$(LINUX_SRC_GIT)/HEAD: $(BUILD_DIR)
	echo "Cloning $(LINUX_ORIGIN) -> $(LINUX_SRC)"
	git clone -sl $(LINUX_ORIGIN) $(LINUX_SRC)

$(BUSYBOX_SRC)/.git:
	git clone -sl $(BUSYBOX_ORIGIN) $(BUSYBOX_SRC)	
	
$(BUSYBOX_SRC)/.config: $(BUSYBOX_SRC)/.git/HEAD
	echo make -C $(BUSYBOX_SRC) defconfig

# $(BUSYBOX_SRC)/busybox: $(BUSYBOX_SRC)/.config
# 	make -C $(BUSYBOX_SRC) -j2 CONFIG_PREFIX=$(BUSYBOX_ROOT_FS)

$(BUSYBOX_ROOT_FS): $(BUSYBOX_SRC)/.config
	echo "Installing to $(PWD)/$(BUSYBOX_ROOT_FS)"
	make -C $(BUSYBOX_SRC) -j2 CONFIG_PREFIX=$(PWD)/$(BUSYBOX_ROOT_FS) install

$(INITRAMFS_DIR): $(BUSYBOX_ROOT_FS)
	mkdir -p $(INITRAMFS_DIR)

$(INITRAMFS_DIR)/bin/busybox: $(BUSYBOX_ROOT_FS)/bin/busybox
	cp -Tar $(BUSYBOX_ROOT_FS)/ $(INITRAMFS_DIR)/

$(INITRAMFS_DIR)/init:	
	cp src/init $(INITRAMFS_DIR) 

$(IRSUBS): $(INITRAMFS_DIR)
	mkdir -p $@

$(INITRAMFS_DIR)/dev/console: $(INITRAMFS_DIR)/dev
# 	cd $(INITRAMFS_DIR)/dev ; mknod console c 5 1

$(INITRAMFS_DIR)/dev/sda: $(INITRAMFS_DIR)/dev	
# 	cd $(INITRAMFS_DIR)/dev ; mknod sda b 8 0



$(INITRAMFS_CPIO): $(IRSUBS) $(INITRAMFS_DIR)/init $(INITRAMFS_DIR)/dev/console $(INITRAMFS_DIR)/bin/busybox
	rm -f $(INITRAMFS_CPIO)
	find $(INITRAMFS_DIR) -mindepth 1  -printf '%P\0' | cpio -D $(INITRAMFS_DIR) --null -ov --format=newc > $(INITRAMFS_CPIO)
# 	cd $(INITRAMFS_DIR) && (find . -print0 | cpio --null -ov --format=newc | > ../initramfs.cpio )
# 	 |  > ../initramfs.cpio.gz

# 	find . -print0 | cpio --null -ov --format=newc | gzip > ../initramfs.cpio.gz
# 	gzip $(BUILD_DIR)/initramfs.cpio

$(INITRAMFS_CPIO_GZ): $(INITRAMFS_CPIO)
	gzip -kfvc $(INITRAMFS_CPIO)  > $(INITRAMFS_CPIO_GZ)
	

$(INITRAMFS_CPIO_XZ): $(INITRAMFS_CPIO)
	xz -kfz9 $(INITRAMFS_CPIO)  > $(INITRAMFS_CPIO_XZ)
	
initram: $(INITRAMFS_CPIO_GZ) $(INITRAMFS_CPIO_XZ) $(BZ_LINUX) 
	ls -lah $(INITRAMFS_CPIO_GZ) $(INITRAMFS_CPIO_XZ) $(INITRAMFS_CPIO)
# 	find $(INITRAMFS_DIR)
# 	find . -print0 | cpio --null -ov --format=newc > initramfs.cpio  
show:
	ls -lah $(INITRAMFS_CPIO_GZ) $(INITRAMFS_CPIO_XZ) $(INITRAMFS_CPIO) $(BZ_LINUX)

run: $(INITRAMFS_CPIO_GZ)
	qemu-system-x86_64  -kernel $(BZ_LINUX)  -initrd $(INITRAMFS_CPIO_GZ) -append "" 
# 	-nographic 
# 	-append "boot_delay=10000"
# 	-initrd $(BUILD_DIR)/initramfs.cpio.gz 
# 	-append "init=/bin/dmesg" 
# 	-append "console=ttyS0" 
# 	-append "init=/sbin/init" 
# 	-append "console=ttyS0" 
# 	-append "init=/sbin/init" -nographic 
# 	$(BZ_LINUX)
chroot:
	sudo chroot $(INITRAMFS_DIR) bin/sh

.PHONY: clean
clean:
	rm -fr $(BUSYBOX_ROOT_FS) $(INITRAMFS_DIR) $(INITRAMFS_CPIO_GZ) $(INITRAMFS_CPIO_XZ) $(INITRAMFS_CPIO) $(BZ_LINUX) 
# 	rm -rf $(EXTERNAL_SRC) $(LINUXSRC)
	