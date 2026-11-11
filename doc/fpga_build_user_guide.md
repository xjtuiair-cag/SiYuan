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
or you can run the following command to generate bitstream directly. Each
`BOARD` + `BOOTROM_TYPE` + `CORE_NUM` combination is fully isolated under
`fpga/build/`, so concurrent `make fpga` jobs are safe:

```
fpga/build/<BOARD>/<BOOTROM_TYPE>_<N>cores/
  bootrom/     # sources copied here, then compiled (DTS embedded for normal)
  ip/          # Xilinx IP copied from xilinx_ip/ and compiled here
  *.bit/*.mcs  # Vivado outputs
```

Defaults (`BOARD=vc707`, `BOOTROM_TYPE=normal`, `CORE_NUM=2`) write bit/mcs to
`fpga/build/vc707/normal_2cores/`.

Core count is selected with `CORE_NUM` (1–4). The same value is passed to Vivado
as `SY_CORE_NUM` and used when regenerating the per-config bootrom DTS.

```sh
make fpga
make fpga CORE_NUM=4                                    # -> .../normal_4cores/
make fpga BOARD=genesys2 BOOTROM_TYPE=lowrisc CORE_NUM=4
```
