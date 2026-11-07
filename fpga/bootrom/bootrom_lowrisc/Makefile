export CROSSCOMPILE=riscv64-unknown-elf-
CC = ${CROSSCOMPILE}gcc
PYTHON=python
MODEL=medany
#MODEL=medlow
BOARD=vc707
VENDOR=cag
CPU=SiYuan
BITSIZE=0xB00000
MEMSIZE=0x40000000

CFLAGS = -Os -ggdb -march=rv64imafdc -mabi=lp64d -Wall -mcmodel=$(MODEL) -fno-builtin-printf -fno-builtin-memcpy -fno-builtin -ffreestanding -fshort-wchar -DBITSIZE=$(BITSIZE) # -mexplicit-relocs
CCASFLAGS = -mcmodel=$(MODEL) # -mexplicit-relocs
LDFLAGS = -nostdlib -nodefaultlibs -nostartfiles -Wl,-Map=mapfile

INCLUDES = -I./ -I./src

SRCS_C = src/elf.c src/ff.c src/mini-printf.c src/random.c src/string.c src/uart.c src/boot.c src/dram.c src/cachetest.c src/hid.c src/bt.c

SRCS_ASM = startup.S $(BOARD)_$(CPU).S 
OBJS_C = $(SRCS_C:.c=.o)
OBJS_S = $(SRCS_ASM:.S=.o)

MAIN = $(BOARD)_$(CPU).elf
MAIN_BIN = $(MAIN:.elf=.bin)
MAIN_DIS = $(MAIN:.elf=.dis)
MAIN_IMG = $(MAIN:.elf=.img)
BOOT0_BIN = boot0/boot0.bin
BOOTROM_SV = bootrom_lowrisc.sv

.PHONY: all clean dis img

# Final FPGA ROM content is produced by merge.py from boot0 + etherboot binaries.
# iverilog/cnvmem are NOT required for this path.
all: $(BOOTROM_SV)
	@echo "zero stage etherboot loader has been compiled!"

$(BOOT0_BIN):
	$(MAKE) -C boot0 all

$(BOOTROM_SV): $(BOOT0_BIN) $(MAIN_BIN) merge.py
	$(PYTHON) merge.py $(BOOT0_BIN) $(MAIN_BIN) 0x80 -o $@

$(MAIN): $(OBJS_C) src/main.c $(OBJS_S) $(BOARD)_$(CPU).o linker.lds
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCLUDES) -Tlinker.lds $(OBJS_S) $(OBJS_C) src/main.c -o $@
	@echo "LD    >= $(MAIN)"

$(BOARD)_$(CPU).dtb: ./generic.dts
	sed -e "s/VENDOR/$(VENDOR)/" -e "s/CPU/$(CPU)/" -e "s/MEMSIZE/$(MEMSIZE)/" -e "s/BOARD/$(BOARD)/" $< | dtc -I dts -O dtb -o $@

$(BOARD)_$(CPU).o: $(BOARD)_$(CPU).dtb
	echo -e .section .dtb \; .align 4,0 \; .globl _dtb \; _dtb: \; .incbin \"$(BOARD)_$(CPU).dtb\" | $(CC) $(CFLAGS) -c -xassembler - -o $@

%.img: %.bin
	dd if=$< of=$@ bs=128

%.bin: %.elf
	$(CROSSCOMPILE)objcopy -O binary $< $@

%.dis: %.elf
	$(CROSSCOMPILE)objdump -d -l -S $< > $@

%.o: %.c
	@$(CC) $(CFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

%.o: %.S
	@$(CC) $(CFLAGS) $(CCASFLAGS) $(INCLUDES) -c $<  -o $@
	@echo "CC    <= $<"

dis: $(MAIN_DIS)
img: $(MAIN_IMG)

# Remove all build outputs (keep sources: *.c/*.h/*.S, generic.dts, cnvmem.v, merge.py, ...).
# Also drop stale leftovers from the old gen_rom / cnvmem flow.
clean:
	$(RM) $(OBJS_C) $(OBJS_S) $(MAIN) $(MAIN_BIN) $(MAIN_IMG) $(MAIN_DIS) \
		$(BOARD)_$(CPU).dtb $(BOARD)_$(CPU).o $(BOARD)_$(CPU).s \
		$(BOARD)_$(CPU).sv $(BOARD)_$(CPU).mem $(BOARD)_$(CPU).vlog \
		$(BOOTROM_SV) cnvmem mapfile \
		src/*.o *.o _.dtb etherboot.h

# DO NOT DELETE THIS LINE -- make depend needs it
