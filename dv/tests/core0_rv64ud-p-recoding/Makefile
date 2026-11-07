CROSS_PREFIX = riscv64-unknown-elf
OBJCOPY = $(CROSS_PREFIX)-objcopy

all:
	mkdir -p output
	$(OBJCOPY) -O verilog rv64ud-p-recoding ./output/ddr.dat
	cp bootrom.dat ./output/bootrom.dat
clean:
	rm -rf output
