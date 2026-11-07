all: boot0 test_case 

clean: 
	$(MAKE) -C boot0 clean
	$(MAKE) -C test_case clean

boot0/boot0.dat: $(BOOTROM_FILE)
	mkdir -p output
	$(MAKE) -C boot0

boot0: boot0/boot0.dat
	cp boot0/boot0.dat ./output/bootrom.dat

test_case/ddr.dat:
	$(MAKE) -C test_case 
test_case: test_case/ddr.dat
	cp test_case/ddr.dat ./output/ddr.dat