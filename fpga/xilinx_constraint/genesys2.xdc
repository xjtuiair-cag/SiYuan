## Buttons
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports cpu_resetn]

## UART
set_property -dict {PACKAGE_PIN Y23 IOSTANDARD LVCMOS33} [get_ports tx]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS33} [get_ports rx]

## To use FTDI FT2232 JTAG
set_property -dict {PACKAGE_PIN Y29 IOSTANDARD LVCMOS33} [get_ports trst_n]
set_property -dict {PACKAGE_PIN AD27 IOSTANDARD LVCMOS33} [get_ports tck]
set_property -dict {PACKAGE_PIN W27 IOSTANDARD LVCMOS33} [get_ports tdi]
set_property -dict {PACKAGE_PIN W28 IOSTANDARD LVCMOS33} [get_ports tdo]
set_property -dict {PACKAGE_PIN W29 IOSTANDARD LVCMOS33} [get_ports tms]

#############################################
## SD Card
set_property -dict { PACKAGE_PIN P28   IOSTANDARD LVCMOS33 } [get_ports { sd_detect }]; #IO_L8N_T1_D12_14 Sch=sd_cd
set_property -dict { PACKAGE_PIN R29   IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }]; #IO_L7N_T1_D10_14 Sch=sd_cmd
set_property -dict { PACKAGE_PIN R26   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[0] }]; #IO_L10N_T1_D15_14 Sch=sd_dat[0]
set_property -dict { PACKAGE_PIN R30   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[1] }]; #IO_L9P_T1_DQS_14 Sch=sd_dat[1]
set_property -dict { PACKAGE_PIN P29   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[2] }]; #IO_L7P_T1_D09_14 Sch=sd_dat[2]
set_property -dict { PACKAGE_PIN T30   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[3] }]; #IO_L9N_T1_DQS_D13_14 Sch=sd_dat[3]
set_property -dict { PACKAGE_PIN AE24  IOSTANDARD LVCMOS33 } [get_ports { sd_reset }]; #IO_L12N_T1_MRCC_12 Sch=sd_reset
set_property -dict { PACKAGE_PIN R28   IOSTANDARD LVCMOS33 } [get_ports { sd_sclk }]; #IO_L11P_T1_SRCC_14 Sch=sd_sclk

set_max_delay -to   [get_ports tdo ] 20
set_max_delay -from [get_ports tms ] 20
set_max_delay -from [get_ports tdi ] 20
set_max_delay -from [get_ports trst ] 20

create_generated_clock -name clk_fpu -source [get_pins i_xlnx_clk_gen0/clk_out1] -divide_by 2 [get_pins cpu_inst/SiYuan_top_inst/clk_fpu_reg/Q]