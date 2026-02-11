O := new-boot.img
STOCK_BOOT := stock-boot.img
IMAGE := ../out/android12-5.4/dist/Image
MAGISKBOOT := tools/magiskboot_x86
SLOT := a

all: $(O)

$(O): $(IMAGE) $(STOCK_BOOT) $(MAGISKBOOT)
	@$(MAGISKBOOT) unpack "$(STOCK_BOOT)"
	@cp -f "$(IMAGE)" "kernel"
	@$(MAGISKBOOT) repack "$(STOCK_BOOT)" "$(O)"
	@$(MAGISKBOOT) cleanup

flash: $(O)
	@adb reboot bootloader
	@fastboot flash "boot_$(SLOT)" "$(O)"
	@fastboot reboot

clean:
	@rm -f "$(O)" "ramdisk.cpio" "kernel"

.PHONY: all flash clean
