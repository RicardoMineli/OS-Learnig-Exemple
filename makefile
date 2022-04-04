ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always

#
#Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

#Make floppy disk image FAT12 format
$(BUILD_DIR)/main_floppy.img: bootloader kernel
# 	create empty 1.44 megabyte file
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
#	create FAT 12 file system
	mkfs.fat -F 12 -n "OSDEV" $(BUILD_DIR)/main_floppy.img
#	put bootloader in the first sector of disk with no truncate
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
#	copy the files(kernel) to image using mtools
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"


#Bootloader
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#Kernel
#Make bin file from source
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin


#Always
always:
	mkdir -p $(BUILD_DIR) 

#Clean
clean:
	rm -rf $(BUILD_DIR)/*