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

quiet_cmd = @printf "  %-7s %s\n" "$(1)" "$(2)"

all: $(O)

$(O): $(IMAGE) $(RAMDISK) $(SIG_KEY)
	$(call quiet_cmd,MKBOOT,$(O))
	@$(MKBOOTIMG) \
		--header_version "$(HEADER_VERSION)" \
		--kernel "$(IMAGE)" \
		--ramdisk "$(RAMDISK)" \
		--os_version "$(OS_VERSION)" \
		--os_patch_level "$(OS_PATCH_LEVEL)" \
		--pagesize "$(PAGESIZE)" \
		-o "$(O)"
	$(call quiet_cmd,AVB,$(O))
	@$(AVBTOOL) \
		add_hash_footer \
		--image $(O) \
		--partition_size "$(PARTITION_SIZE)" \
		--partition_name boot \
		--algorithm SHA256_RSA2048 \
		--key "$(SIG_KEY)"

$(SIG_KEY):
	$(call quiet_cmd,KEYGEN,$(SIG_KEY))
	@$(OPENSSL) genrsa -out "$(SIG_KEY)" 2048

flash: $(O)
	@if adb devices | grep -q -w "device"; then \
		$(call quiet_cmd,ADB,Rebooting to bootloader...); \
		adb reboot bootloader; \
	elif ! fastboot devices | grep -q "fastboot"; then \
		$(call quiet_cmd,ERROR,No device found!); \
		exit 1; \
	fi
	$(call quiet_cmd,FLASH,$(O) -> slot $(SLOT))
	@fastboot flash "boot_$(SLOT)" "$(O)"
	$(call quiet_cmd,REBOOT,system)
	@fastboot reboot

clean:
	$(call quiet_cmd,CLEAN,$(O))
	@rm -f "$(O)"

.PHONY: all flash clean
