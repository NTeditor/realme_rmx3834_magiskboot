O := new-boot.img
IMAGE := $(abspath ../out/android12-5.4/dist/Image)
RAMDISK := ./blobs/ramdisk.cpio.lz4
SIG_KEY := test_key.pem

MKBOOTIMG := python3 $(abspath ../tools/mkbootimg/mkbootimg.py)
AVBTOOL := python3 $(abspath ../tools/avbtool/avbtool.py)
OPENSSL := $(abspath ../prebuilts/build-tools/linux-x86/bin/openssl)

SLOT := a

HEADER_VERSION := 4
PARTITION_SIZE := 67108864
OS_VERSION := 13.0.0
OS_PATCH_LEVEL := 2024-01
PAGESIZE := 4096

all: $(O)
$(O): $(IMAGE) $(RAMDISK) $(SIG_KEY)
	@$(MKBOOTIMG) \
		--header_version "$(HEADER_VERSION)" \
		--kernel "$(IMAGE)" \
		--ramdisk "$(RAMDISK)" \
		--os_version "$(OS_VERSION)" \
		--os_patch_level "$(OS_PATCH_LEVEL)" \
		--pagesize "$(PAGESIZE)" \
		-o "$(O)"
	@$(AVBTOOL) \
		add_hash_footer \
		--image $(O) \
		--partition_size "$(PARTITION_SIZE)" \
		--partition_name boot \
		--algorithm SHA256_RSA2048 \
		--key "$(SIG_KEY)"

$(SIG_KEY):
	$(OPENSSL) genrsa -out "$(SIG_KEY)" 2048

flash: $(O)
	@adb reboot bootloader
	@fastboot flash "boot_$(SLOT)" "$(O)"
	@fastboot reboot

clean:
	@rm -f "$(O)"

.PHONY: all flash clean
