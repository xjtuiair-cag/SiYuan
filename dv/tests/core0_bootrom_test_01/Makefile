all: clean
	$(MAKE) -C boot0 
	$(MAKE) -C boot1
	mkdir -p output
	python merge_boot.py boot0/boot0.dat boot1/boot1.dat 0x80 output/bootrom.dat	

boot0_clean:
	make -C boot0 clean
boot1_clean:
	make -C boot1 clean

clean: boot0_clean boot1_clean
