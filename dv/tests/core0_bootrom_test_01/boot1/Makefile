GNU ?= riscv64-unknown-elf

COPS += -Os -ggdb -march=rv64im -mabi=lp64 -Wall -mcmodel=medany -mexplicit-relocs -ffreestanding -Iinclude

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
all : clean boot1.bin 

clean :
	rm -rf $(BUILD_DIR) output $(SBI_BUILD_DIR) *.bin  *.map *.elf *.hex *.s *.dat

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

boot1.bin: config.ld $(OBJ_FILES)
	$(CMD_PREFIX)$(GNU)-ld -T config.ld -o $(BUILD_DIR)/boot1.elf  $(OBJ_FILES) -Map boot1.map; echo " LD $(BUILD_DIR)/boot1.elf"
	$(CMD_PREFIX)$(GNU)-objcopy $(BUILD_DIR)/boot1.elf -O binary boot1.bin; echo " OBJCOPY boot1.bin"
	$(CMD_PREFIX)$(GNU)-objcopy $(BUILD_DIR)/boot1.elf -O verilog boot1.hex; echo " OBJCOPY boot1.hex"
	$(CMD_PREFIX)$(GNU)-objdump -Sxtd $(BUILD_DIR)/boot1.elf > boot1.s; echo " objdump boot1.s"
	$(CMD_PREFIX)cp $(BUILD_DIR)/boot1.elf boot1.elf
	python gen_verilog_data.py --file "boot1.hex" --offset "0x80000000" --output "boot1.dat"