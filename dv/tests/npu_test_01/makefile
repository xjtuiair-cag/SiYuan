GNU ?= riscv64-unknown-elf

COPS += -save-temps=obj -g -O0 -Wall -nostdlib -nostdinc -Iinclude -mcmodel=medany -mabi=lp64 -march=rv64imafd -fno-PIE -fomit-frame-pointer

##############
#  build src
##############
BUILD_DIR = build_src
SRC_DIR = src

# Check if verbosity is ON for build process
CMD_PREFIX_DEFAULT := @
ifeq ($(V), 1)
	CMD_PREFIX :=
else
	CMD_PREFIX := $(CMD_PREFIX_DEFAULT)
endif
all : clean ddr.bin 

clean :
	rm -rf $(BUILD_DIR) output $(SBI_BUILD_DIR) *.bin  *.map *.elf *.hex *.s

$(BUILD_DIR)/%_c.o: $(SRC_DIR)/%.c
	$(CMD_PREFIX)mkdir -p $(BUILD_DIR); echo " CC   $@" ; $(GNU)-gcc $(COPS) -c $< -o $@

$(BUILD_DIR)/%_s.o: $(SRC_DIR)/%.S
	$(CMD_PREFIX)mkdir -p $(BUILD_DIR); echo " AS   $@"; $(GNU)-gcc $(COPS) -c $< -o $@

C_FILES = $(wildcard $(SRC_DIR)/*.c)
ASM_FILES = $(wildcard $(SRC_DIR)/*.S)
OBJ_FILES = $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%_s.o)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

ddr.bin: config.ld $(OBJ_FILES)
	$(CMD_PREFIX)$(GNU)-ld -T config.ld -o $(BUILD_DIR)/ddr.elf  $(OBJ_FILES) -Map ddr.map; echo " LD $(BUILD_DIR)/ddr.elf"
	$(CMD_PREFIX)$(GNU)-objcopy $(BUILD_DIR)/ddr.elf -O binary ddr.bin; echo " OBJCOPY ddr.bin"
	$(CMD_PREFIX)$(GNU)-objcopy $(BUILD_DIR)/ddr.elf -O verilog ddr.hex; echo " OBJCOPY ddr.hex"
	$(CMD_PREFIX)$(GNU)-objdump -Sxtd $(BUILD_DIR)/ddr.elf > ddr.s; echo " objdump ddr.s"
	$(CMD_PREFIX)cp $(BUILD_DIR)/ddr.elf ddr.elf
	mkdir -p output; python gen_verilog_data.py --file "ddr.hex" --offset "0x80000000" --output "ddr.dat"
	cp 1_itcm.verilog output/1_itcm.verilog
	cp 1_dtcm.verilog output/1_dtcm.verilog
	python gen_wt_bias.py --input total_bias.txt --output bias.dat
	python gen_wt_bias.py --input total_weight.txt --output weight.dat
	python gen_ifm.py --input image.jpg --output ifm.dat

