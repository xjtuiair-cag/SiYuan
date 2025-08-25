CROSS_PREFIX = riscv64-unknown-elf
CC = $(CROSS_PREFIX)-gcc
G++ = $(CROSS_PREFIX)-g++
AS = $(CROSS_PREFIX)-as
LD = $(CROSS_PREFIX)-ld
NM = $(CROSS_PREFIX)-nm
OBJCOPY = $(CROSS_PREFIX)-objcopy
OBJDUMP = $(CROSS_PREFIX)-objdump

config = ./config.lds
obj = test.o 

output_name = swf_code
elf = $(output_name).mo
bin = $(output_name).bin
hex = $(output_name).hex
dump = $(output_name).s

all: $(obj)
	mkdir -p output
	$(LD) $(obj) -o output/$(elf) -T $(config)
	$(OBJDUMP) -Sxtd output/$(elf) > output/$(dump)
	# $(OBJCOPY) -O binary output/$(elf) output/$(bin)
	$(OBJCOPY) -O verilog output/$(elf) output/$(hex)
	python gen_verilog_data.py

gen_verilog_data:
	$(OBJCOPY) -O verilog ${output_name} swf_code.hex
	python gen_verilog_data.py

%.o: src/%.s
	$(CC) -c $< -o $@ -march=rv64imafd -mabi=lp64 

%.co: src/%.c
	$(CC) -g -c $< -o $@ -march=rv64imafd -mabi=lp64 

#$(CC) -c $< -o $@ -march=rv32ifd -mabi=ilp32

clean:
	rm -rf $(obj) output/*
