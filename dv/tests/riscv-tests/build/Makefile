prefix          := /home/iair/projects/cva6_4_2/cva6_riscv_toolchain/target
abs_top_src_dir := /home/iair/projects/cva6_4_2/cva6-sdk/riscv-tests/build/..
XLEN            := 64
target_alias    := 
ifeq ($(target_alias),)
RISCV_PREFIX_VAR :=
else
RISCV_PREFIX_VAR := RISCV_PREFIX=-
endif
instbasedir     := $(DESTDIR)$(prefix)
bmarkdir        := $(abs_top_src_dir)/benchmarks
isa_src_dir     := $(abs_top_src_dir)/isa
debug_src_dir   := $(abs_top_src_dir)/debug

all: benchmarks isa

install: all
	install -d $(instbasedir)/share/riscv-tests/isa
	install -d $(instbasedir)/share/riscv-tests/benchmarks
	install -p -m 644 `find isa -maxdepth 1 -type f` $(instbasedir)/share/riscv-tests/isa
	install -p -m 644 `find benchmarks -maxdepth 1 -type f` $(instbasedir)/share/riscv-tests/benchmarks

benchmarks:
	mkdir -p benchmarks
	$(MAKE) -C benchmarks -f $(bmarkdir)/Makefile src_dir=$(bmarkdir) XLEN=$(XLEN) $(RISCV_PREFIX_VAR)

isa:
	mkdir -p isa
	$(MAKE) -C isa -f $(isa_src_dir)/Makefile src_dir=$(isa_src_dir) XLEN=$(XLEN) $(RISCV_PREFIX_VAR)

debug-check:
	mkdir -p debug
	$(MAKE) -C debug -f $(debug_src_dir)/Makefile src_dir=$(debug_src_dir) XLEN=$(XLEN)

clean:
	[ ! -d isa ]        || $(MAKE) -C isa -f $(isa_src_dir)/Makefile src_dir=$(isa_src_dir) clean
	[ ! -d benchmarks ] || $(MAKE) -C benchmarks -f $(bmarkdir)/Makefile src_dir=$(bmarkdir) clean
	[ ! -d debug ]      || $(MAKE) -C debug -f $(debug_src_dir)/Makefile src_dir=$(debug_src_dir) clean

.PHONY: benchmarks isa clean

