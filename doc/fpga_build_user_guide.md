# FPGA bitstream generation

## 1. Requirement
To build SiYuan, you need to install the following tools:

1. `vivado 2018.2` 

2. `python3` : make sure `python` refers to python3 in your computer

3. `riscv64-unknown-elf-gcc` 

4. `Xilinx VC707 FPGA board`  or `Genesys 2 Kintex-7 FPGA Development Board`

If you don't want to install `python3` or `riscv64-unknown-elf-gcc`, that's ok. You can use default source file to build SiYuan. But if you want to change default configuration, you need to install `python3` and `riscv64-unknown-elf-gcc`.


## 2. Download SiYuan

Please make sure you have installed the above tools in `Requirement`.
```sh
git https://github.com/xjtuiair-cag/SiYuan.git 
cd SiYuan
git submodule update --init --recursive
```
## 3. Generate source file

If you don't install `python3` or `riscv64-unknown-elf-gcc`, please skip this step.
```sh
make gen_src
```

## 4. Generate bitstream

Generate bitstream need vivado, so please make sure you have installed vivado. We recommend to use vivado 2018.2, but other version is acceptable. If you have any problems in generating bitstream, please put it in the `Issue`.

If you are familiar with vivado GUI, you can run the following command to create SiYuan project. Then you will see the project in vivado GUI, and you need to run sythesis and implementation and generate bitstream by yourself. 
```sh
make fpga_gui
```
or you can run the following command to generate bitstream directly. When the process done, you will find bitstream `sy_soc_fpga.bit` and `sy_soc_fpga.mcs` in `fpga/build/`
```sh
make fpga
```
