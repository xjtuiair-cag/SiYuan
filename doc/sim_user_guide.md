# Simulation User Guide for SiYuan
## 1. requirement
1. python3 
2. riscv64-unknown-elf-gcc
3. VCS and Verdi

Use `riscv64-unknown-elf-gcc -v` to Check whether the riscv64-unknown-elf-gcc is installed correctly. 

Use `vcs -help` to Check whether the VCS. 

Use `verdi --version` to Check whether the Verdi is installed correctly.

## 2. Tests
We have prepared the following types of test case for SiYuan: `riscv_test`, `benos test`, `dma test`, and `linux test`.

* riscv test 
   
   The riscv-tests are a set of programs used to verify whether a RISC-V processor implementation complies with its instruction set architecture specification. The riscv test includes test cases for each type of instruction, and the corresponding test environment can be selected. For example, if the current system is in bare-metal mode, the "P" environment should be selected; if it's running under a Linux OS, then the "V" environment should be used.
   
   Since SiYuan operates in a bare-metal environment, the "P" environment is selected. The ISA test suite from riscv-tests is used to verify the correctness of the SiYuan processor. 

* benos test
    
    benos is a small teaching-oriented operating system developed by `benshushu`. The source code is available from the [repository](https://github.com/runninglinuxkernel/riscv_programming_practice). We use benos to further test the correctness of the SiYuan processor.

* dma test
    
    The DMA test cases are used to verify the correctness of the DMA module within SiYuan.

* linux test

    The Linux test cases are used to simulate the booting of the Linux operating system, including both the bootloader and the Linux kernel. These test cases are very large and may take several days to run completely. Therefore, we recommend using an FPGA to run Linux.

## 3. Run

### 3.1 Source generation

Before starting the tests, please ensure that you have installed the `riscv64-unknown-elf-gcc` toolchain.

Use the following command to generate the necessary test files.
```bash
make prepare_sim_src CONFIG = sim.yaml
```

This command generates the `sy_soc_pkg` header file and compiles the relevant riscv test cases.

### 3.2 Build SiYuan

Before building SiYuan, please make sure that `VCS` and `Verdi` are properly installed.

Use the following command to set the test suite environment variable. Available options are: `riscv_test`, `benos`, `dma`, and `linux`.
```bash
export SIM_TYPE = benos # riscv_test/benos/dma/linux are available
```

Then use the following command to build the SiYuan simulation environment.
```bash
make build_sim_src
```

### 3.3 Run Test
Use the following command to run a specific test case. 
```bash
make run_sim_test TEST = benos_test_01 
```
If you want to use `Verdi` to view simulation waveforms, please add the option `GUI=1`.
```bash
make run_sim_test TEST = benos_test_01 GUI=1
```

`benos/dma/linux` test case are list in `dv/tests` and riscv test case are list in `dv/tests/riscv_test_list`

### 3.4 Run Regression Test
Regression test are only available for `riscv test`. 

Regression testing is used to test the correctness of SiYuan on specific instruction sets, such as testing the `I/M/A/F/D` instruction sets, etc. Run it using the following command. Regression testing does not support `Verdi to view waveforms.

```bash
make run_sim_regression TEST_REGRESSION=rv64ui
```

Available regression test cases options are as follows: `rv64ui/rv64um/rv64ua/rv64uf/rv64ud`.
