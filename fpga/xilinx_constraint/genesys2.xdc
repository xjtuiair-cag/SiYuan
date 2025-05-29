## Buttons
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports cpu_resetn]

## UART
set_property -dict {PACKAGE_PIN Y23 IOSTANDARD LVCMOS33} [get_ports tx]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS33} [get_ports rx]


## LEDs
set_property -dict {PACKAGE_PIN T28 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN W24 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN W23 IOSTANDARD LVCMOS33} [get_ports {led[7]}]

## Switches
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS12} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN G25 IOSTANDARD LVCMOS12} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN H24 IOSTANDARD LVCMOS12} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS12} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS12} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS12} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN P26 IOSTANDARD LVCMOS33} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN P27 IOSTANDARD LVCMOS33} [get_ports {sw[7]}]

## Fan Control
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports fan_pwm]
#set_property -dict { PACKAGE_PIN V21   IOSTANDARD LVCMOS33 } [get_ports { FAN_TACH }]; #IO_L22P_T3_A05_D21_14 Sch=fan_tac

## Ethernet
set_property -dict {PACKAGE_PIN AH24 IOSTANDARD LVCMOS33} [get_ports eth_rst_n]
set_property -dict {PACKAGE_PIN AE10 IOSTANDARD LVCMOS15} [get_ports eth_txck]
set_property -dict {PACKAGE_PIN AK14 IOSTANDARD LVCMOS15} [get_ports eth_txctl]
set_property -dict {PACKAGE_PIN AJ12 IOSTANDARD LVCMOS15} [get_ports {eth_txd[0]}]
set_property -dict {PACKAGE_PIN AK11 IOSTANDARD LVCMOS15} [get_ports {eth_txd[1]}]
set_property -dict {PACKAGE_PIN AJ11 IOSTANDARD LVCMOS15} [get_ports {eth_txd[2]}]
set_property -dict {PACKAGE_PIN AK10 IOSTANDARD LVCMOS15} [get_ports {eth_txd[3]}]
set_property -dict {PACKAGE_PIN AJ14 IOSTANDARD LVCMOS15} [get_ports {eth_rxd[0]}]
set_property -dict {PACKAGE_PIN AG10 IOSTANDARD LVCMOS15} [get_ports eth_rxck]
set_property -dict {PACKAGE_PIN AH11 IOSTANDARD LVCMOS15} [get_ports eth_rxctl]
set_property -dict {PACKAGE_PIN AH14 IOSTANDARD LVCMOS15} [get_ports {eth_rxd[1]}]
set_property -dict {PACKAGE_PIN AK13 IOSTANDARD LVCMOS15} [get_ports {eth_rxd[2]}]
set_property -dict {PACKAGE_PIN AJ13 IOSTANDARD LVCMOS15} [get_ports {eth_rxd[3]}]
set_property -dict {PACKAGE_PIN AF12 IOSTANDARD LVCMOS15} [get_ports eth_mdc]
set_property -dict {PACKAGE_PIN AG12 IOSTANDARD LVCMOS15} [get_ports eth_mdio]

# set_property -dict {PACKAGE_PIN AK15  IOSTANDARD LVCMOS18} [get_ports { eth_pme_b }]; #IO_L1N_T0_32 Sch=eth_pmeb
# set_property -dict {PACKAGE_PIN AK16  IOSTANDARD LVCMOS18} [get_ports { eth_int_b }]; #IO_L1P_T0_32 Sch=eth_intb

#############################################
# Ethernet Constraints for 1Gb/s
#############################################
# Modified for 125MHz receive clock
create_clock -period 8.000 -name eth_rxck [get_ports eth_rxck]

set_clock_groups -asynchronous -group [get_clocks eth_rxck -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks clk_out2_xlnx_clk_gen]

#############################################
## SD Card
#############################################
set_property -dict {PACKAGE_PIN R28 IOSTANDARD LVCMOS33} [get_ports spi_clk_o]
set_property -dict {PACKAGE_PIN T30 IOSTANDARD LVCMOS33} [get_ports spi_ss]
set_property -dict {PACKAGE_PIN R26 IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN R29 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
# set_property -dict { PACKAGE_PIN P28   IOSTANDARD LVCMOS33 } [get_ports { sd_cd }]; #IO_L8N_T1_D12_14 Sch=sd_cd
# set_property -dict { PACKAGE_PIN R29   IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }]; #IO_L7N_T1_D10_14 Sch=sd_cmd
# set_property -dict { PACKAGE_PIN R26   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[0] }]; #IO_L10N_T1_D15_14 Sch=sd_dat[0]
# set_property -dict { PACKAGE_PIN R30   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[1] }]; #IO_L9P_T1_DQS_14 Sch=sd_dat[1]
# set_property -dict { PACKAGE_PIN P29   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[2] }]; #IO_L7P_T1_D09_14 Sch=sd_dat[2]
# set_property -dict { PACKAGE_PIN T30   IOSTANDARD LVCMOS33 } [get_ports { sd_dat[3] }]; #IO_L9N_T1_DQS_D13_14 Sch=sd_dat[3]
# set_property -dict { PACKAGE_PIN AE24  IOSTANDARD LVCMOS33 } [get_ports { sd_reset }]; #IO_L12N_T1_MRCC_12 Sch=sd_reset
# set_property -dict { PACKAGE_PIN R28   IOSTANDARD LVCMOS33 } [get_ports { sd_clk }]; #IO_L11P_T1_SRCC_14 Sch=sd_sclk

# create_generated_clock -name sd_fast_clk -source [get_pins clk_mmcm/sd_sys_clk] -divide_by 2 [get_pins chipset_impl/piton_sd_top/sdc_controller/clock_divider0/fast_clk_reg/Q]
# create_generated_clock -name sd_slow_clk -source [get_pins clk_mmcm/sd_sys_clk] -divide_by 200 [get_pins chipset_impl/piton_sd_top/sdc_controller/clock_divider0/slow_clk_reg/Q]
# create_generated_clock -name sd_clk_out -source [get_pins sd_clk_oddr/C] -divide_by 1 -add -master_clock sd_fast_clk [get_ports sd_clk_out]
# create_generated_clock -name sd_clk_out_1 -source [get_pins sd_clk_oddr/C] -divide_by 1 -add -master_clock sd_slow_clk [get_ports sd_clk_out]

# create_clock -period 40.000 -name VIRTUAL_sd_fast_clk -waveform {0.000 20.000}
# create_clock -period 4000.000 -name VIRTUAL_sd_slow_clk -waveform {0.000 2000.000}

# set_output_delay -clock [get_clocks sd_clk_out] -min -add_delay 5.000 [get_ports {sd_dat[*]}]
# set_output_delay -clock [get_clocks sd_clk_out] -max -add_delay 15.000 [get_ports {sd_dat[*]}]
# set_output_delay -clock [get_clocks sd_clk_out_1] -min -add_delay 5.000 [get_ports {sd_dat[*]}]
# set_output_delay -clock [get_clocks sd_clk_out_1] -max -add_delay 1500.000 [get_ports {sd_dat[*]}]
# set_output_delay -clock [get_clocks sd_clk_out] -min -add_delay 5.000 [get_ports sd_cmd]
# set_output_delay -clock [get_clocks sd_clk_out] -max -add_delay 15.000 [get_ports sd_cmd]
# set_output_delay -clock [get_clocks sd_clk_out_1] -min -add_delay 5.000 [get_ports sd_cmd]
# set_output_delay -clock [get_clocks sd_clk_out_1] -max -add_delay 1500.000 [get_ports sd_cmd]
# set_input_delay -clock [get_clocks VIRTUAL_sd_fast_clk] -min -add_delay 20.000 [get_ports {sd_dat[*]}]
# set_input_delay -clock [get_clocks VIRTUAL_sd_fast_clk] -max -add_delay 35.000 [get_ports {sd_dat[*]}]
# set_input_delay -clock [get_clocks VIRTUAL_sd_slow_clk] -min -add_delay 2000.000 [get_ports {sd_dat[*]}]
# set_input_delay -clock [get_clocks VIRTUAL_sd_slow_clk] -max -add_delay 3500.000 [get_ports {sd_dat[*]}]
# set_input_delay -clock [get_clocks VIRTUAL_sd_fast_clk] -min -add_delay 20.000 [get_ports sd_cmd]
# set_input_delay -clock [get_clocks VIRTUAL_sd_fast_clk] -max -add_delay 35.000 [get_ports sd_cmd]
# set_input_delay -clock [get_clocks VIRTUAL_sd_slow_clk] -min -add_delay 2000.000 [get_ports sd_cmd]
# set_input_delay -clock [get_clocks VIRTUAL_sd_slow_clk] -max -add_delay 3500.000 [get_ports sd_cmd]
# set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks sd_clk_out] -group [get_clocks -include_generated_clocks sd_clk_out_1]
# set_clock_groups -logically_exclusive -group [get_clocks -include_generated_clocks {VIRTUAL_sd_fast_clk sd_fast_clk}] -group [get_clocks -include_generated_clocks {sd_slow_clk VIRTUAL_sd_slow_clk}]
# set_clock_groups -asynchronous -group [get_clocks [list [get_clocks -of_objects [get_pins clk_mmcm/chipset_clk]]]] -group [get_clocks -filter { NAME =~  "*sd*" }]


# Genesys 2 has a quad SPI flash
# set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# # set multicycle path on reset, on the FPGA we do not care about the reset anyway
# set_multicycle_path -from [get_pins i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C] 4
# set_multicycle_path -from [get_pins i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C] 3  -hold



connect_debug_port u_ila_0/probe0 [get_nets [list {dma_inst/fifo/prb_fifo_rdata[0]} {dma_inst/fifo/prb_fifo_rdata[1]} {dma_inst/fifo/prb_fifo_rdata[2]} {dma_inst/fifo/prb_fifo_rdata[3]} {dma_inst/fifo/prb_fifo_rdata[4]} {dma_inst/fifo/prb_fifo_rdata[5]} {dma_inst/fifo/prb_fifo_rdata[6]} {dma_inst/fifo/prb_fifo_rdata[7]} {dma_inst/fifo/prb_fifo_rdata[8]} {dma_inst/fifo/prb_fifo_rdata[9]} {dma_inst/fifo/prb_fifo_rdata[10]} {dma_inst/fifo/prb_fifo_rdata[11]} {dma_inst/fifo/prb_fifo_rdata[12]} {dma_inst/fifo/prb_fifo_rdata[13]} {dma_inst/fifo/prb_fifo_rdata[14]} {dma_inst/fifo/prb_fifo_rdata[15]} {dma_inst/fifo/prb_fifo_rdata[16]} {dma_inst/fifo/prb_fifo_rdata[17]} {dma_inst/fifo/prb_fifo_rdata[18]} {dma_inst/fifo/prb_fifo_rdata[19]} {dma_inst/fifo/prb_fifo_rdata[20]} {dma_inst/fifo/prb_fifo_rdata[21]} {dma_inst/fifo/prb_fifo_rdata[22]} {dma_inst/fifo/prb_fifo_rdata[23]} {dma_inst/fifo/prb_fifo_rdata[24]} {dma_inst/fifo/prb_fifo_rdata[25]} {dma_inst/fifo/prb_fifo_rdata[26]} {dma_inst/fifo/prb_fifo_rdata[27]} {dma_inst/fifo/prb_fifo_rdata[28]} {dma_inst/fifo/prb_fifo_rdata[29]} {dma_inst/fifo/prb_fifo_rdata[30]} {dma_inst/fifo/prb_fifo_rdata[31]} {dma_inst/fifo/prb_fifo_rdata[32]} {dma_inst/fifo/prb_fifo_rdata[33]} {dma_inst/fifo/prb_fifo_rdata[34]} {dma_inst/fifo/prb_fifo_rdata[35]} {dma_inst/fifo/prb_fifo_rdata[36]} {dma_inst/fifo/prb_fifo_rdata[37]} {dma_inst/fifo/prb_fifo_rdata[38]} {dma_inst/fifo/prb_fifo_rdata[39]} {dma_inst/fifo/prb_fifo_rdata[40]} {dma_inst/fifo/prb_fifo_rdata[41]} {dma_inst/fifo/prb_fifo_rdata[42]} {dma_inst/fifo/prb_fifo_rdata[43]} {dma_inst/fifo/prb_fifo_rdata[44]} {dma_inst/fifo/prb_fifo_rdata[45]} {dma_inst/fifo/prb_fifo_rdata[46]} {dma_inst/fifo/prb_fifo_rdata[47]} {dma_inst/fifo/prb_fifo_rdata[48]} {dma_inst/fifo/prb_fifo_rdata[49]} {dma_inst/fifo/prb_fifo_rdata[50]} {dma_inst/fifo/prb_fifo_rdata[51]} {dma_inst/fifo/prb_fifo_rdata[52]} {dma_inst/fifo/prb_fifo_rdata[53]} {dma_inst/fifo/prb_fifo_rdata[54]} {dma_inst/fifo/prb_fifo_rdata[55]} {dma_inst/fifo/prb_fifo_rdata[56]} {dma_inst/fifo/prb_fifo_rdata[57]} {dma_inst/fifo/prb_fifo_rdata[58]} {dma_inst/fifo/prb_fifo_rdata[59]} {dma_inst/fifo/prb_fifo_rdata[60]} {dma_inst/fifo/prb_fifo_rdata[61]} {dma_inst/fifo/prb_fifo_rdata[62]} {dma_inst/fifo/prb_fifo_rdata[63]}]]
connect_debug_port u_ila_0/probe50 [get_nets [list dma_inst/fifo/prb_fifo_empty]]
connect_debug_port u_ila_0/probe51 [get_nets [list dma_inst/fifo/prb_fifo_full]]
connect_debug_port u_ila_0/probe52 [get_nets [list dma_inst/fifo/prb_fifo_pop]]
connect_debug_port u_ila_0/probe53 [get_nets [list dma_inst/fifo/prb_fifo_push]]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_xlnx_clk_gen/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 64 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ddr_inst/prb_ddr_r_data[0]} {ddr_inst/prb_ddr_r_data[1]} {ddr_inst/prb_ddr_r_data[2]} {ddr_inst/prb_ddr_r_data[3]} {ddr_inst/prb_ddr_r_data[4]} {ddr_inst/prb_ddr_r_data[5]} {ddr_inst/prb_ddr_r_data[6]} {ddr_inst/prb_ddr_r_data[7]} {ddr_inst/prb_ddr_r_data[8]} {ddr_inst/prb_ddr_r_data[9]} {ddr_inst/prb_ddr_r_data[10]} {ddr_inst/prb_ddr_r_data[11]} {ddr_inst/prb_ddr_r_data[12]} {ddr_inst/prb_ddr_r_data[13]} {ddr_inst/prb_ddr_r_data[14]} {ddr_inst/prb_ddr_r_data[15]} {ddr_inst/prb_ddr_r_data[16]} {ddr_inst/prb_ddr_r_data[17]} {ddr_inst/prb_ddr_r_data[18]} {ddr_inst/prb_ddr_r_data[19]} {ddr_inst/prb_ddr_r_data[20]} {ddr_inst/prb_ddr_r_data[21]} {ddr_inst/prb_ddr_r_data[22]} {ddr_inst/prb_ddr_r_data[23]} {ddr_inst/prb_ddr_r_data[24]} {ddr_inst/prb_ddr_r_data[25]} {ddr_inst/prb_ddr_r_data[26]} {ddr_inst/prb_ddr_r_data[27]} {ddr_inst/prb_ddr_r_data[28]} {ddr_inst/prb_ddr_r_data[29]} {ddr_inst/prb_ddr_r_data[30]} {ddr_inst/prb_ddr_r_data[31]} {ddr_inst/prb_ddr_r_data[32]} {ddr_inst/prb_ddr_r_data[33]} {ddr_inst/prb_ddr_r_data[34]} {ddr_inst/prb_ddr_r_data[35]} {ddr_inst/prb_ddr_r_data[36]} {ddr_inst/prb_ddr_r_data[37]} {ddr_inst/prb_ddr_r_data[38]} {ddr_inst/prb_ddr_r_data[39]} {ddr_inst/prb_ddr_r_data[40]} {ddr_inst/prb_ddr_r_data[41]} {ddr_inst/prb_ddr_r_data[42]} {ddr_inst/prb_ddr_r_data[43]} {ddr_inst/prb_ddr_r_data[44]} {ddr_inst/prb_ddr_r_data[45]} {ddr_inst/prb_ddr_r_data[46]} {ddr_inst/prb_ddr_r_data[47]} {ddr_inst/prb_ddr_r_data[48]} {ddr_inst/prb_ddr_r_data[49]} {ddr_inst/prb_ddr_r_data[50]} {ddr_inst/prb_ddr_r_data[51]} {ddr_inst/prb_ddr_r_data[52]} {ddr_inst/prb_ddr_r_data[53]} {ddr_inst/prb_ddr_r_data[54]} {ddr_inst/prb_ddr_r_data[55]} {ddr_inst/prb_ddr_r_data[56]} {ddr_inst/prb_ddr_r_data[57]} {ddr_inst/prb_ddr_r_data[58]} {ddr_inst/prb_ddr_r_data[59]} {ddr_inst/prb_ddr_r_data[60]} {ddr_inst/prb_ddr_r_data[61]} {ddr_inst/prb_ddr_r_data[62]} {ddr_inst/prb_ddr_r_data[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {ddr_inst/prb_ddr_w_data[0]} {ddr_inst/prb_ddr_w_data[1]} {ddr_inst/prb_ddr_w_data[2]} {ddr_inst/prb_ddr_w_data[3]} {ddr_inst/prb_ddr_w_data[4]} {ddr_inst/prb_ddr_w_data[5]} {ddr_inst/prb_ddr_w_data[6]} {ddr_inst/prb_ddr_w_data[7]} {ddr_inst/prb_ddr_w_data[8]} {ddr_inst/prb_ddr_w_data[9]} {ddr_inst/prb_ddr_w_data[10]} {ddr_inst/prb_ddr_w_data[11]} {ddr_inst/prb_ddr_w_data[12]} {ddr_inst/prb_ddr_w_data[13]} {ddr_inst/prb_ddr_w_data[14]} {ddr_inst/prb_ddr_w_data[15]} {ddr_inst/prb_ddr_w_data[16]} {ddr_inst/prb_ddr_w_data[17]} {ddr_inst/prb_ddr_w_data[18]} {ddr_inst/prb_ddr_w_data[19]} {ddr_inst/prb_ddr_w_data[20]} {ddr_inst/prb_ddr_w_data[21]} {ddr_inst/prb_ddr_w_data[22]} {ddr_inst/prb_ddr_w_data[23]} {ddr_inst/prb_ddr_w_data[24]} {ddr_inst/prb_ddr_w_data[25]} {ddr_inst/prb_ddr_w_data[26]} {ddr_inst/prb_ddr_w_data[27]} {ddr_inst/prb_ddr_w_data[28]} {ddr_inst/prb_ddr_w_data[29]} {ddr_inst/prb_ddr_w_data[30]} {ddr_inst/prb_ddr_w_data[31]} {ddr_inst/prb_ddr_w_data[32]} {ddr_inst/prb_ddr_w_data[33]} {ddr_inst/prb_ddr_w_data[34]} {ddr_inst/prb_ddr_w_data[35]} {ddr_inst/prb_ddr_w_data[36]} {ddr_inst/prb_ddr_w_data[37]} {ddr_inst/prb_ddr_w_data[38]} {ddr_inst/prb_ddr_w_data[39]} {ddr_inst/prb_ddr_w_data[40]} {ddr_inst/prb_ddr_w_data[41]} {ddr_inst/prb_ddr_w_data[42]} {ddr_inst/prb_ddr_w_data[43]} {ddr_inst/prb_ddr_w_data[44]} {ddr_inst/prb_ddr_w_data[45]} {ddr_inst/prb_ddr_w_data[46]} {ddr_inst/prb_ddr_w_data[47]} {ddr_inst/prb_ddr_w_data[48]} {ddr_inst/prb_ddr_w_data[49]} {ddr_inst/prb_ddr_w_data[50]} {ddr_inst/prb_ddr_w_data[51]} {ddr_inst/prb_ddr_w_data[52]} {ddr_inst/prb_ddr_w_data[53]} {ddr_inst/prb_ddr_w_data[54]} {ddr_inst/prb_ddr_w_data[55]} {ddr_inst/prb_ddr_w_data[56]} {ddr_inst/prb_ddr_w_data[57]} {ddr_inst/prb_ddr_w_data[58]} {ddr_inst/prb_ddr_w_data[59]} {ddr_inst/prb_ddr_w_data[60]} {ddr_inst/prb_ddr_w_data[61]} {ddr_inst/prb_ddr_w_data[62]} {ddr_inst/prb_ddr_w_data[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {ddr_inst/prb_ddr_ar_addr[0]} {ddr_inst/prb_ddr_ar_addr[1]} {ddr_inst/prb_ddr_ar_addr[2]} {ddr_inst/prb_ddr_ar_addr[3]} {ddr_inst/prb_ddr_ar_addr[4]} {ddr_inst/prb_ddr_ar_addr[5]} {ddr_inst/prb_ddr_ar_addr[6]} {ddr_inst/prb_ddr_ar_addr[7]} {ddr_inst/prb_ddr_ar_addr[8]} {ddr_inst/prb_ddr_ar_addr[9]} {ddr_inst/prb_ddr_ar_addr[10]} {ddr_inst/prb_ddr_ar_addr[11]} {ddr_inst/prb_ddr_ar_addr[12]} {ddr_inst/prb_ddr_ar_addr[13]} {ddr_inst/prb_ddr_ar_addr[14]} {ddr_inst/prb_ddr_ar_addr[15]} {ddr_inst/prb_ddr_ar_addr[16]} {ddr_inst/prb_ddr_ar_addr[17]} {ddr_inst/prb_ddr_ar_addr[18]} {ddr_inst/prb_ddr_ar_addr[19]} {ddr_inst/prb_ddr_ar_addr[20]} {ddr_inst/prb_ddr_ar_addr[21]} {ddr_inst/prb_ddr_ar_addr[22]} {ddr_inst/prb_ddr_ar_addr[23]} {ddr_inst/prb_ddr_ar_addr[24]} {ddr_inst/prb_ddr_ar_addr[25]} {ddr_inst/prb_ddr_ar_addr[26]} {ddr_inst/prb_ddr_ar_addr[27]} {ddr_inst/prb_ddr_ar_addr[28]} {ddr_inst/prb_ddr_ar_addr[29]} {ddr_inst/prb_ddr_ar_addr[30]} {ddr_inst/prb_ddr_ar_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {ddr_inst/prb_ddr_aw_addr[0]} {ddr_inst/prb_ddr_aw_addr[1]} {ddr_inst/prb_ddr_aw_addr[2]} {ddr_inst/prb_ddr_aw_addr[3]} {ddr_inst/prb_ddr_aw_addr[4]} {ddr_inst/prb_ddr_aw_addr[5]} {ddr_inst/prb_ddr_aw_addr[6]} {ddr_inst/prb_ddr_aw_addr[7]} {ddr_inst/prb_ddr_aw_addr[8]} {ddr_inst/prb_ddr_aw_addr[9]} {ddr_inst/prb_ddr_aw_addr[10]} {ddr_inst/prb_ddr_aw_addr[11]} {ddr_inst/prb_ddr_aw_addr[12]} {ddr_inst/prb_ddr_aw_addr[13]} {ddr_inst/prb_ddr_aw_addr[14]} {ddr_inst/prb_ddr_aw_addr[15]} {ddr_inst/prb_ddr_aw_addr[16]} {ddr_inst/prb_ddr_aw_addr[17]} {ddr_inst/prb_ddr_aw_addr[18]} {ddr_inst/prb_ddr_aw_addr[19]} {ddr_inst/prb_ddr_aw_addr[20]} {ddr_inst/prb_ddr_aw_addr[21]} {ddr_inst/prb_ddr_aw_addr[22]} {ddr_inst/prb_ddr_aw_addr[23]} {ddr_inst/prb_ddr_aw_addr[24]} {ddr_inst/prb_ddr_aw_addr[25]} {ddr_inst/prb_ddr_aw_addr[26]} {ddr_inst/prb_ddr_aw_addr[27]} {ddr_inst/prb_ddr_aw_addr[28]} {ddr_inst/prb_ddr_aw_addr[29]} {ddr_inst/prb_ddr_aw_addr[30]} {ddr_inst/prb_ddr_aw_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 10 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dma_inst/fifo/prb_fifo_raddr[0]} {dma_inst/fifo/prb_fifo_raddr[1]} {dma_inst/fifo/prb_fifo_raddr[2]} {dma_inst/fifo/prb_fifo_raddr[3]} {dma_inst/fifo/prb_fifo_raddr[4]} {dma_inst/fifo/prb_fifo_raddr[5]} {dma_inst/fifo/prb_fifo_raddr[6]} {dma_inst/fifo/prb_fifo_raddr[7]} {dma_inst/fifo/prb_fifo_raddr[8]} {dma_inst/fifo/prb_fifo_raddr[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 10 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {dma_inst/fifo/prb_fifo_waddr[0]} {dma_inst/fifo/prb_fifo_waddr[1]} {dma_inst/fifo/prb_fifo_waddr[2]} {dma_inst/fifo/prb_fifo_waddr[3]} {dma_inst/fifo/prb_fifo_waddr[4]} {dma_inst/fifo/prb_fifo_waddr[5]} {dma_inst/fifo/prb_fifo_waddr[6]} {dma_inst/fifo/prb_fifo_waddr[7]} {dma_inst/fifo/prb_fifo_waddr[8]} {dma_inst/fifo/prb_fifo_waddr[9]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 2 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {ddr_inst/u_sy_axi4_arbiter/prb_axi_state[0]} {ddr_inst/u_sy_axi4_arbiter/prb_axi_state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 2 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {ddr_inst/u_sy_axi4_arbiter/prb_axi_req_all[0]} {ddr_inst/u_sy_axi4_arbiter/prb_axi_req_all[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {dma_inst/prb_dma_src_addr[0]} {dma_inst/prb_dma_src_addr[1]} {dma_inst/prb_dma_src_addr[2]} {dma_inst/prb_dma_src_addr[3]} {dma_inst/prb_dma_src_addr[4]} {dma_inst/prb_dma_src_addr[5]} {dma_inst/prb_dma_src_addr[6]} {dma_inst/prb_dma_src_addr[7]} {dma_inst/prb_dma_src_addr[8]} {dma_inst/prb_dma_src_addr[9]} {dma_inst/prb_dma_src_addr[10]} {dma_inst/prb_dma_src_addr[11]} {dma_inst/prb_dma_src_addr[12]} {dma_inst/prb_dma_src_addr[13]} {dma_inst/prb_dma_src_addr[14]} {dma_inst/prb_dma_src_addr[15]} {dma_inst/prb_dma_src_addr[16]} {dma_inst/prb_dma_src_addr[17]} {dma_inst/prb_dma_src_addr[18]} {dma_inst/prb_dma_src_addr[19]} {dma_inst/prb_dma_src_addr[20]} {dma_inst/prb_dma_src_addr[21]} {dma_inst/prb_dma_src_addr[22]} {dma_inst/prb_dma_src_addr[23]} {dma_inst/prb_dma_src_addr[24]} {dma_inst/prb_dma_src_addr[25]} {dma_inst/prb_dma_src_addr[26]} {dma_inst/prb_dma_src_addr[27]} {dma_inst/prb_dma_src_addr[28]} {dma_inst/prb_dma_src_addr[29]} {dma_inst/prb_dma_src_addr[30]} {dma_inst/prb_dma_src_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 16 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {dma_inst/prb_dma_volume[0]} {dma_inst/prb_dma_volume[1]} {dma_inst/prb_dma_volume[2]} {dma_inst/prb_dma_volume[3]} {dma_inst/prb_dma_volume[4]} {dma_inst/prb_dma_volume[5]} {dma_inst/prb_dma_volume[6]} {dma_inst/prb_dma_volume[7]} {dma_inst/prb_dma_volume[8]} {dma_inst/prb_dma_volume[9]} {dma_inst/prb_dma_volume[10]} {dma_inst/prb_dma_volume[11]} {dma_inst/prb_dma_volume[12]} {dma_inst/prb_dma_volume[13]} {dma_inst/prb_dma_volume[14]} {dma_inst/prb_dma_volume[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 32 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {dma_inst/prb_dma_des_addr[0]} {dma_inst/prb_dma_des_addr[1]} {dma_inst/prb_dma_des_addr[2]} {dma_inst/prb_dma_des_addr[3]} {dma_inst/prb_dma_des_addr[4]} {dma_inst/prb_dma_des_addr[5]} {dma_inst/prb_dma_des_addr[6]} {dma_inst/prb_dma_des_addr[7]} {dma_inst/prb_dma_des_addr[8]} {dma_inst/prb_dma_des_addr[9]} {dma_inst/prb_dma_des_addr[10]} {dma_inst/prb_dma_des_addr[11]} {dma_inst/prb_dma_des_addr[12]} {dma_inst/prb_dma_des_addr[13]} {dma_inst/prb_dma_des_addr[14]} {dma_inst/prb_dma_des_addr[15]} {dma_inst/prb_dma_des_addr[16]} {dma_inst/prb_dma_des_addr[17]} {dma_inst/prb_dma_des_addr[18]} {dma_inst/prb_dma_des_addr[19]} {dma_inst/prb_dma_des_addr[20]} {dma_inst/prb_dma_des_addr[21]} {dma_inst/prb_dma_des_addr[22]} {dma_inst/prb_dma_des_addr[23]} {dma_inst/prb_dma_des_addr[24]} {dma_inst/prb_dma_des_addr[25]} {dma_inst/prb_dma_des_addr[26]} {dma_inst/prb_dma_des_addr[27]} {dma_inst/prb_dma_des_addr[28]} {dma_inst/prb_dma_des_addr[29]} {dma_inst/prb_dma_des_addr[30]} {dma_inst/prb_dma_des_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 32 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {dma_inst/prb_dma_rdata[0]} {dma_inst/prb_dma_rdata[1]} {dma_inst/prb_dma_rdata[2]} {dma_inst/prb_dma_rdata[3]} {dma_inst/prb_dma_rdata[4]} {dma_inst/prb_dma_rdata[5]} {dma_inst/prb_dma_rdata[6]} {dma_inst/prb_dma_rdata[7]} {dma_inst/prb_dma_rdata[8]} {dma_inst/prb_dma_rdata[9]} {dma_inst/prb_dma_rdata[10]} {dma_inst/prb_dma_rdata[11]} {dma_inst/prb_dma_rdata[12]} {dma_inst/prb_dma_rdata[13]} {dma_inst/prb_dma_rdata[14]} {dma_inst/prb_dma_rdata[15]} {dma_inst/prb_dma_rdata[16]} {dma_inst/prb_dma_rdata[17]} {dma_inst/prb_dma_rdata[18]} {dma_inst/prb_dma_rdata[19]} {dma_inst/prb_dma_rdata[20]} {dma_inst/prb_dma_rdata[21]} {dma_inst/prb_dma_rdata[22]} {dma_inst/prb_dma_rdata[23]} {dma_inst/prb_dma_rdata[24]} {dma_inst/prb_dma_rdata[25]} {dma_inst/prb_dma_rdata[26]} {dma_inst/prb_dma_rdata[27]} {dma_inst/prb_dma_rdata[28]} {dma_inst/prb_dma_rdata[29]} {dma_inst/prb_dma_rdata[30]} {dma_inst/prb_dma_rdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 32 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {dma_inst/prb_dma_wdata[0]} {dma_inst/prb_dma_wdata[1]} {dma_inst/prb_dma_wdata[2]} {dma_inst/prb_dma_wdata[3]} {dma_inst/prb_dma_wdata[4]} {dma_inst/prb_dma_wdata[5]} {dma_inst/prb_dma_wdata[6]} {dma_inst/prb_dma_wdata[7]} {dma_inst/prb_dma_wdata[8]} {dma_inst/prb_dma_wdata[9]} {dma_inst/prb_dma_wdata[10]} {dma_inst/prb_dma_wdata[11]} {dma_inst/prb_dma_wdata[12]} {dma_inst/prb_dma_wdata[13]} {dma_inst/prb_dma_wdata[14]} {dma_inst/prb_dma_wdata[15]} {dma_inst/prb_dma_wdata[16]} {dma_inst/prb_dma_wdata[17]} {dma_inst/prb_dma_wdata[18]} {dma_inst/prb_dma_wdata[19]} {dma_inst/prb_dma_wdata[20]} {dma_inst/prb_dma_wdata[21]} {dma_inst/prb_dma_wdata[22]} {dma_inst/prb_dma_wdata[23]} {dma_inst/prb_dma_wdata[24]} {dma_inst/prb_dma_wdata[25]} {dma_inst/prb_dma_wdata[26]} {dma_inst/prb_dma_wdata[27]} {dma_inst/prb_dma_wdata[28]} {dma_inst/prb_dma_wdata[29]} {dma_inst/prb_dma_wdata[30]} {dma_inst/prb_dma_wdata[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 64 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {dma_inst/prb_fifo_rdata[0]} {dma_inst/prb_fifo_rdata[1]} {dma_inst/prb_fifo_rdata[2]} {dma_inst/prb_fifo_rdata[3]} {dma_inst/prb_fifo_rdata[4]} {dma_inst/prb_fifo_rdata[5]} {dma_inst/prb_fifo_rdata[6]} {dma_inst/prb_fifo_rdata[7]} {dma_inst/prb_fifo_rdata[8]} {dma_inst/prb_fifo_rdata[9]} {dma_inst/prb_fifo_rdata[10]} {dma_inst/prb_fifo_rdata[11]} {dma_inst/prb_fifo_rdata[12]} {dma_inst/prb_fifo_rdata[13]} {dma_inst/prb_fifo_rdata[14]} {dma_inst/prb_fifo_rdata[15]} {dma_inst/prb_fifo_rdata[16]} {dma_inst/prb_fifo_rdata[17]} {dma_inst/prb_fifo_rdata[18]} {dma_inst/prb_fifo_rdata[19]} {dma_inst/prb_fifo_rdata[20]} {dma_inst/prb_fifo_rdata[21]} {dma_inst/prb_fifo_rdata[22]} {dma_inst/prb_fifo_rdata[23]} {dma_inst/prb_fifo_rdata[24]} {dma_inst/prb_fifo_rdata[25]} {dma_inst/prb_fifo_rdata[26]} {dma_inst/prb_fifo_rdata[27]} {dma_inst/prb_fifo_rdata[28]} {dma_inst/prb_fifo_rdata[29]} {dma_inst/prb_fifo_rdata[30]} {dma_inst/prb_fifo_rdata[31]} {dma_inst/prb_fifo_rdata[32]} {dma_inst/prb_fifo_rdata[33]} {dma_inst/prb_fifo_rdata[34]} {dma_inst/prb_fifo_rdata[35]} {dma_inst/prb_fifo_rdata[36]} {dma_inst/prb_fifo_rdata[37]} {dma_inst/prb_fifo_rdata[38]} {dma_inst/prb_fifo_rdata[39]} {dma_inst/prb_fifo_rdata[40]} {dma_inst/prb_fifo_rdata[41]} {dma_inst/prb_fifo_rdata[42]} {dma_inst/prb_fifo_rdata[43]} {dma_inst/prb_fifo_rdata[44]} {dma_inst/prb_fifo_rdata[45]} {dma_inst/prb_fifo_rdata[46]} {dma_inst/prb_fifo_rdata[47]} {dma_inst/prb_fifo_rdata[48]} {dma_inst/prb_fifo_rdata[49]} {dma_inst/prb_fifo_rdata[50]} {dma_inst/prb_fifo_rdata[51]} {dma_inst/prb_fifo_rdata[52]} {dma_inst/prb_fifo_rdata[53]} {dma_inst/prb_fifo_rdata[54]} {dma_inst/prb_fifo_rdata[55]} {dma_inst/prb_fifo_rdata[56]} {dma_inst/prb_fifo_rdata[57]} {dma_inst/prb_fifo_rdata[58]} {dma_inst/prb_fifo_rdata[59]} {dma_inst/prb_fifo_rdata[60]} {dma_inst/prb_fifo_rdata[61]} {dma_inst/prb_fifo_rdata[62]} {dma_inst/prb_fifo_rdata[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 64 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {dma_inst/prb_fifo_wdata[0]} {dma_inst/prb_fifo_wdata[1]} {dma_inst/prb_fifo_wdata[2]} {dma_inst/prb_fifo_wdata[3]} {dma_inst/prb_fifo_wdata[4]} {dma_inst/prb_fifo_wdata[5]} {dma_inst/prb_fifo_wdata[6]} {dma_inst/prb_fifo_wdata[7]} {dma_inst/prb_fifo_wdata[8]} {dma_inst/prb_fifo_wdata[9]} {dma_inst/prb_fifo_wdata[10]} {dma_inst/prb_fifo_wdata[11]} {dma_inst/prb_fifo_wdata[12]} {dma_inst/prb_fifo_wdata[13]} {dma_inst/prb_fifo_wdata[14]} {dma_inst/prb_fifo_wdata[15]} {dma_inst/prb_fifo_wdata[16]} {dma_inst/prb_fifo_wdata[17]} {dma_inst/prb_fifo_wdata[18]} {dma_inst/prb_fifo_wdata[19]} {dma_inst/prb_fifo_wdata[20]} {dma_inst/prb_fifo_wdata[21]} {dma_inst/prb_fifo_wdata[22]} {dma_inst/prb_fifo_wdata[23]} {dma_inst/prb_fifo_wdata[24]} {dma_inst/prb_fifo_wdata[25]} {dma_inst/prb_fifo_wdata[26]} {dma_inst/prb_fifo_wdata[27]} {dma_inst/prb_fifo_wdata[28]} {dma_inst/prb_fifo_wdata[29]} {dma_inst/prb_fifo_wdata[30]} {dma_inst/prb_fifo_wdata[31]} {dma_inst/prb_fifo_wdata[32]} {dma_inst/prb_fifo_wdata[33]} {dma_inst/prb_fifo_wdata[34]} {dma_inst/prb_fifo_wdata[35]} {dma_inst/prb_fifo_wdata[36]} {dma_inst/prb_fifo_wdata[37]} {dma_inst/prb_fifo_wdata[38]} {dma_inst/prb_fifo_wdata[39]} {dma_inst/prb_fifo_wdata[40]} {dma_inst/prb_fifo_wdata[41]} {dma_inst/prb_fifo_wdata[42]} {dma_inst/prb_fifo_wdata[43]} {dma_inst/prb_fifo_wdata[44]} {dma_inst/prb_fifo_wdata[45]} {dma_inst/prb_fifo_wdata[46]} {dma_inst/prb_fifo_wdata[47]} {dma_inst/prb_fifo_wdata[48]} {dma_inst/prb_fifo_wdata[49]} {dma_inst/prb_fifo_wdata[50]} {dma_inst/prb_fifo_wdata[51]} {dma_inst/prb_fifo_wdata[52]} {dma_inst/prb_fifo_wdata[53]} {dma_inst/prb_fifo_wdata[54]} {dma_inst/prb_fifo_wdata[55]} {dma_inst/prb_fifo_wdata[56]} {dma_inst/prb_fifo_wdata[57]} {dma_inst/prb_fifo_wdata[58]} {dma_inst/prb_fifo_wdata[59]} {dma_inst/prb_fifo_wdata[60]} {dma_inst/prb_fifo_wdata[61]} {dma_inst/prb_fifo_wdata[62]} {dma_inst/prb_fifo_wdata[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 64 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {dma_inst/prb_dma_d_rdata[0]} {dma_inst/prb_dma_d_rdata[1]} {dma_inst/prb_dma_d_rdata[2]} {dma_inst/prb_dma_d_rdata[3]} {dma_inst/prb_dma_d_rdata[4]} {dma_inst/prb_dma_d_rdata[5]} {dma_inst/prb_dma_d_rdata[6]} {dma_inst/prb_dma_d_rdata[7]} {dma_inst/prb_dma_d_rdata[8]} {dma_inst/prb_dma_d_rdata[9]} {dma_inst/prb_dma_d_rdata[10]} {dma_inst/prb_dma_d_rdata[11]} {dma_inst/prb_dma_d_rdata[12]} {dma_inst/prb_dma_d_rdata[13]} {dma_inst/prb_dma_d_rdata[14]} {dma_inst/prb_dma_d_rdata[15]} {dma_inst/prb_dma_d_rdata[16]} {dma_inst/prb_dma_d_rdata[17]} {dma_inst/prb_dma_d_rdata[18]} {dma_inst/prb_dma_d_rdata[19]} {dma_inst/prb_dma_d_rdata[20]} {dma_inst/prb_dma_d_rdata[21]} {dma_inst/prb_dma_d_rdata[22]} {dma_inst/prb_dma_d_rdata[23]} {dma_inst/prb_dma_d_rdata[24]} {dma_inst/prb_dma_d_rdata[25]} {dma_inst/prb_dma_d_rdata[26]} {dma_inst/prb_dma_d_rdata[27]} {dma_inst/prb_dma_d_rdata[28]} {dma_inst/prb_dma_d_rdata[29]} {dma_inst/prb_dma_d_rdata[30]} {dma_inst/prb_dma_d_rdata[31]} {dma_inst/prb_dma_d_rdata[32]} {dma_inst/prb_dma_d_rdata[33]} {dma_inst/prb_dma_d_rdata[34]} {dma_inst/prb_dma_d_rdata[35]} {dma_inst/prb_dma_d_rdata[36]} {dma_inst/prb_dma_d_rdata[37]} {dma_inst/prb_dma_d_rdata[38]} {dma_inst/prb_dma_d_rdata[39]} {dma_inst/prb_dma_d_rdata[40]} {dma_inst/prb_dma_d_rdata[41]} {dma_inst/prb_dma_d_rdata[42]} {dma_inst/prb_dma_d_rdata[43]} {dma_inst/prb_dma_d_rdata[44]} {dma_inst/prb_dma_d_rdata[45]} {dma_inst/prb_dma_d_rdata[46]} {dma_inst/prb_dma_d_rdata[47]} {dma_inst/prb_dma_d_rdata[48]} {dma_inst/prb_dma_d_rdata[49]} {dma_inst/prb_dma_d_rdata[50]} {dma_inst/prb_dma_d_rdata[51]} {dma_inst/prb_dma_d_rdata[52]} {dma_inst/prb_dma_d_rdata[53]} {dma_inst/prb_dma_d_rdata[54]} {dma_inst/prb_dma_d_rdata[55]} {dma_inst/prb_dma_d_rdata[56]} {dma_inst/prb_dma_d_rdata[57]} {dma_inst/prb_dma_d_rdata[58]} {dma_inst/prb_dma_d_rdata[59]} {dma_inst/prb_dma_d_rdata[60]} {dma_inst/prb_dma_d_rdata[61]} {dma_inst/prb_dma_d_rdata[62]} {dma_inst/prb_dma_d_rdata[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 4 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {dma_inst/prb_dma_d_opcode[0]} {dma_inst/prb_dma_d_opcode[1]} {dma_inst/prb_dma_d_opcode[2]} {dma_inst/prb_dma_d_opcode[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 4 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {dma_inst/prb_dma_ctrl[0]} {dma_inst/prb_dma_ctrl[1]} {dma_inst/prb_dma_ctrl[2]} {dma_inst/prb_dma_ctrl[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 64 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {dma_inst/prb_dma_a_addr[0]} {dma_inst/prb_dma_a_addr[1]} {dma_inst/prb_dma_a_addr[2]} {dma_inst/prb_dma_a_addr[3]} {dma_inst/prb_dma_a_addr[4]} {dma_inst/prb_dma_a_addr[5]} {dma_inst/prb_dma_a_addr[6]} {dma_inst/prb_dma_a_addr[7]} {dma_inst/prb_dma_a_addr[8]} {dma_inst/prb_dma_a_addr[9]} {dma_inst/prb_dma_a_addr[10]} {dma_inst/prb_dma_a_addr[11]} {dma_inst/prb_dma_a_addr[12]} {dma_inst/prb_dma_a_addr[13]} {dma_inst/prb_dma_a_addr[14]} {dma_inst/prb_dma_a_addr[15]} {dma_inst/prb_dma_a_addr[16]} {dma_inst/prb_dma_a_addr[17]} {dma_inst/prb_dma_a_addr[18]} {dma_inst/prb_dma_a_addr[19]} {dma_inst/prb_dma_a_addr[20]} {dma_inst/prb_dma_a_addr[21]} {dma_inst/prb_dma_a_addr[22]} {dma_inst/prb_dma_a_addr[23]} {dma_inst/prb_dma_a_addr[24]} {dma_inst/prb_dma_a_addr[25]} {dma_inst/prb_dma_a_addr[26]} {dma_inst/prb_dma_a_addr[27]} {dma_inst/prb_dma_a_addr[28]} {dma_inst/prb_dma_a_addr[29]} {dma_inst/prb_dma_a_addr[30]} {dma_inst/prb_dma_a_addr[31]} {dma_inst/prb_dma_a_addr[32]} {dma_inst/prb_dma_a_addr[33]} {dma_inst/prb_dma_a_addr[34]} {dma_inst/prb_dma_a_addr[35]} {dma_inst/prb_dma_a_addr[36]} {dma_inst/prb_dma_a_addr[37]} {dma_inst/prb_dma_a_addr[38]} {dma_inst/prb_dma_a_addr[39]} {dma_inst/prb_dma_a_addr[40]} {dma_inst/prb_dma_a_addr[41]} {dma_inst/prb_dma_a_addr[42]} {dma_inst/prb_dma_a_addr[43]} {dma_inst/prb_dma_a_addr[44]} {dma_inst/prb_dma_a_addr[45]} {dma_inst/prb_dma_a_addr[46]} {dma_inst/prb_dma_a_addr[47]} {dma_inst/prb_dma_a_addr[48]} {dma_inst/prb_dma_a_addr[49]} {dma_inst/prb_dma_a_addr[50]} {dma_inst/prb_dma_a_addr[51]} {dma_inst/prb_dma_a_addr[52]} {dma_inst/prb_dma_a_addr[53]} {dma_inst/prb_dma_a_addr[54]} {dma_inst/prb_dma_a_addr[55]} {dma_inst/prb_dma_a_addr[56]} {dma_inst/prb_dma_a_addr[57]} {dma_inst/prb_dma_a_addr[58]} {dma_inst/prb_dma_a_addr[59]} {dma_inst/prb_dma_a_addr[60]} {dma_inst/prb_dma_a_addr[61]} {dma_inst/prb_dma_a_addr[62]} {dma_inst/prb_dma_a_addr[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 4 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {dma_inst/prb_dma_c_opcode[0]} {dma_inst/prb_dma_c_opcode[1]} {dma_inst/prb_dma_c_opcode[2]} {dma_inst/prb_dma_c_opcode[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 64 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {dma_inst/prb_dma_c_data[0]} {dma_inst/prb_dma_c_data[1]} {dma_inst/prb_dma_c_data[2]} {dma_inst/prb_dma_c_data[3]} {dma_inst/prb_dma_c_data[4]} {dma_inst/prb_dma_c_data[5]} {dma_inst/prb_dma_c_data[6]} {dma_inst/prb_dma_c_data[7]} {dma_inst/prb_dma_c_data[8]} {dma_inst/prb_dma_c_data[9]} {dma_inst/prb_dma_c_data[10]} {dma_inst/prb_dma_c_data[11]} {dma_inst/prb_dma_c_data[12]} {dma_inst/prb_dma_c_data[13]} {dma_inst/prb_dma_c_data[14]} {dma_inst/prb_dma_c_data[15]} {dma_inst/prb_dma_c_data[16]} {dma_inst/prb_dma_c_data[17]} {dma_inst/prb_dma_c_data[18]} {dma_inst/prb_dma_c_data[19]} {dma_inst/prb_dma_c_data[20]} {dma_inst/prb_dma_c_data[21]} {dma_inst/prb_dma_c_data[22]} {dma_inst/prb_dma_c_data[23]} {dma_inst/prb_dma_c_data[24]} {dma_inst/prb_dma_c_data[25]} {dma_inst/prb_dma_c_data[26]} {dma_inst/prb_dma_c_data[27]} {dma_inst/prb_dma_c_data[28]} {dma_inst/prb_dma_c_data[29]} {dma_inst/prb_dma_c_data[30]} {dma_inst/prb_dma_c_data[31]} {dma_inst/prb_dma_c_data[32]} {dma_inst/prb_dma_c_data[33]} {dma_inst/prb_dma_c_data[34]} {dma_inst/prb_dma_c_data[35]} {dma_inst/prb_dma_c_data[36]} {dma_inst/prb_dma_c_data[37]} {dma_inst/prb_dma_c_data[38]} {dma_inst/prb_dma_c_data[39]} {dma_inst/prb_dma_c_data[40]} {dma_inst/prb_dma_c_data[41]} {dma_inst/prb_dma_c_data[42]} {dma_inst/prb_dma_c_data[43]} {dma_inst/prb_dma_c_data[44]} {dma_inst/prb_dma_c_data[45]} {dma_inst/prb_dma_c_data[46]} {dma_inst/prb_dma_c_data[47]} {dma_inst/prb_dma_c_data[48]} {dma_inst/prb_dma_c_data[49]} {dma_inst/prb_dma_c_data[50]} {dma_inst/prb_dma_c_data[51]} {dma_inst/prb_dma_c_data[52]} {dma_inst/prb_dma_c_data[53]} {dma_inst/prb_dma_c_data[54]} {dma_inst/prb_dma_c_data[55]} {dma_inst/prb_dma_c_data[56]} {dma_inst/prb_dma_c_data[57]} {dma_inst/prb_dma_c_data[58]} {dma_inst/prb_dma_c_data[59]} {dma_inst/prb_dma_c_data[60]} {dma_inst/prb_dma_c_data[61]} {dma_inst/prb_dma_c_data[62]} {dma_inst/prb_dma_c_data[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 32 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {dma_inst/prb_dma_addr[0]} {dma_inst/prb_dma_addr[1]} {dma_inst/prb_dma_addr[2]} {dma_inst/prb_dma_addr[3]} {dma_inst/prb_dma_addr[4]} {dma_inst/prb_dma_addr[5]} {dma_inst/prb_dma_addr[6]} {dma_inst/prb_dma_addr[7]} {dma_inst/prb_dma_addr[8]} {dma_inst/prb_dma_addr[9]} {dma_inst/prb_dma_addr[10]} {dma_inst/prb_dma_addr[11]} {dma_inst/prb_dma_addr[12]} {dma_inst/prb_dma_addr[13]} {dma_inst/prb_dma_addr[14]} {dma_inst/prb_dma_addr[15]} {dma_inst/prb_dma_addr[16]} {dma_inst/prb_dma_addr[17]} {dma_inst/prb_dma_addr[18]} {dma_inst/prb_dma_addr[19]} {dma_inst/prb_dma_addr[20]} {dma_inst/prb_dma_addr[21]} {dma_inst/prb_dma_addr[22]} {dma_inst/prb_dma_addr[23]} {dma_inst/prb_dma_addr[24]} {dma_inst/prb_dma_addr[25]} {dma_inst/prb_dma_addr[26]} {dma_inst/prb_dma_addr[27]} {dma_inst/prb_dma_addr[28]} {dma_inst/prb_dma_addr[29]} {dma_inst/prb_dma_addr[30]} {dma_inst/prb_dma_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 16 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {dma_inst/prb_dma_burst_len[0]} {dma_inst/prb_dma_burst_len[1]} {dma_inst/prb_dma_burst_len[2]} {dma_inst/prb_dma_burst_len[3]} {dma_inst/prb_dma_burst_len[4]} {dma_inst/prb_dma_burst_len[5]} {dma_inst/prb_dma_burst_len[6]} {dma_inst/prb_dma_burst_len[7]} {dma_inst/prb_dma_burst_len[8]} {dma_inst/prb_dma_burst_len[9]} {dma_inst/prb_dma_burst_len[10]} {dma_inst/prb_dma_burst_len[11]} {dma_inst/prb_dma_burst_len[12]} {dma_inst/prb_dma_burst_len[13]} {dma_inst/prb_dma_burst_len[14]} {dma_inst/prb_dma_burst_len[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 4 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {dma_inst/prb_dma_a_opcode[0]} {dma_inst/prb_dma_a_opcode[1]} {dma_inst/prb_dma_a_opcode[2]} {dma_inst/prb_dma_a_opcode[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 64 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {dma_inst/prb_dma_c_addr[0]} {dma_inst/prb_dma_c_addr[1]} {dma_inst/prb_dma_c_addr[2]} {dma_inst/prb_dma_c_addr[3]} {dma_inst/prb_dma_c_addr[4]} {dma_inst/prb_dma_c_addr[5]} {dma_inst/prb_dma_c_addr[6]} {dma_inst/prb_dma_c_addr[7]} {dma_inst/prb_dma_c_addr[8]} {dma_inst/prb_dma_c_addr[9]} {dma_inst/prb_dma_c_addr[10]} {dma_inst/prb_dma_c_addr[11]} {dma_inst/prb_dma_c_addr[12]} {dma_inst/prb_dma_c_addr[13]} {dma_inst/prb_dma_c_addr[14]} {dma_inst/prb_dma_c_addr[15]} {dma_inst/prb_dma_c_addr[16]} {dma_inst/prb_dma_c_addr[17]} {dma_inst/prb_dma_c_addr[18]} {dma_inst/prb_dma_c_addr[19]} {dma_inst/prb_dma_c_addr[20]} {dma_inst/prb_dma_c_addr[21]} {dma_inst/prb_dma_c_addr[22]} {dma_inst/prb_dma_c_addr[23]} {dma_inst/prb_dma_c_addr[24]} {dma_inst/prb_dma_c_addr[25]} {dma_inst/prb_dma_c_addr[26]} {dma_inst/prb_dma_c_addr[27]} {dma_inst/prb_dma_c_addr[28]} {dma_inst/prb_dma_c_addr[29]} {dma_inst/prb_dma_c_addr[30]} {dma_inst/prb_dma_c_addr[31]} {dma_inst/prb_dma_c_addr[32]} {dma_inst/prb_dma_c_addr[33]} {dma_inst/prb_dma_c_addr[34]} {dma_inst/prb_dma_c_addr[35]} {dma_inst/prb_dma_c_addr[36]} {dma_inst/prb_dma_c_addr[37]} {dma_inst/prb_dma_c_addr[38]} {dma_inst/prb_dma_c_addr[39]} {dma_inst/prb_dma_c_addr[40]} {dma_inst/prb_dma_c_addr[41]} {dma_inst/prb_dma_c_addr[42]} {dma_inst/prb_dma_c_addr[43]} {dma_inst/prb_dma_c_addr[44]} {dma_inst/prb_dma_c_addr[45]} {dma_inst/prb_dma_c_addr[46]} {dma_inst/prb_dma_c_addr[47]} {dma_inst/prb_dma_c_addr[48]} {dma_inst/prb_dma_c_addr[49]} {dma_inst/prb_dma_c_addr[50]} {dma_inst/prb_dma_c_addr[51]} {dma_inst/prb_dma_c_addr[52]} {dma_inst/prb_dma_c_addr[53]} {dma_inst/prb_dma_c_addr[54]} {dma_inst/prb_dma_c_addr[55]} {dma_inst/prb_dma_c_addr[56]} {dma_inst/prb_dma_c_addr[57]} {dma_inst/prb_dma_c_addr[58]} {dma_inst/prb_dma_c_addr[59]} {dma_inst/prb_dma_c_addr[60]} {dma_inst/prb_dma_c_addr[61]} {dma_inst/prb_dma_c_addr[62]} {dma_inst/prb_dma_c_addr[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 32 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {main_mem/probe_ctrl_inst/prb_cc_a_addr[0]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[1]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[2]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[3]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[4]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[5]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[6]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[7]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[8]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[9]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[10]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[11]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[12]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[13]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[14]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[15]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[16]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[17]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[18]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[19]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[20]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[21]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[22]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[23]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[24]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[25]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[26]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[27]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[28]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[29]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[30]} {main_mem/probe_ctrl_inst/prb_cc_a_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 3 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {main_mem/probe_ctrl_inst/prb_cc_a_source[0]} {main_mem/probe_ctrl_inst/prb_cc_a_source[1]} {main_mem/probe_ctrl_inst/prb_cc_a_source[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 2 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {main_mem/probe_ctrl_inst/prb_cc_state[0]} {main_mem/probe_ctrl_inst/prb_cc_state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 32 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {npu/prb_npu_axi_aw_addr[0]} {npu/prb_npu_axi_aw_addr[1]} {npu/prb_npu_axi_aw_addr[2]} {npu/prb_npu_axi_aw_addr[3]} {npu/prb_npu_axi_aw_addr[4]} {npu/prb_npu_axi_aw_addr[5]} {npu/prb_npu_axi_aw_addr[6]} {npu/prb_npu_axi_aw_addr[7]} {npu/prb_npu_axi_aw_addr[8]} {npu/prb_npu_axi_aw_addr[9]} {npu/prb_npu_axi_aw_addr[10]} {npu/prb_npu_axi_aw_addr[11]} {npu/prb_npu_axi_aw_addr[12]} {npu/prb_npu_axi_aw_addr[13]} {npu/prb_npu_axi_aw_addr[14]} {npu/prb_npu_axi_aw_addr[15]} {npu/prb_npu_axi_aw_addr[16]} {npu/prb_npu_axi_aw_addr[17]} {npu/prb_npu_axi_aw_addr[18]} {npu/prb_npu_axi_aw_addr[19]} {npu/prb_npu_axi_aw_addr[20]} {npu/prb_npu_axi_aw_addr[21]} {npu/prb_npu_axi_aw_addr[22]} {npu/prb_npu_axi_aw_addr[23]} {npu/prb_npu_axi_aw_addr[24]} {npu/prb_npu_axi_aw_addr[25]} {npu/prb_npu_axi_aw_addr[26]} {npu/prb_npu_axi_aw_addr[27]} {npu/prb_npu_axi_aw_addr[28]} {npu/prb_npu_axi_aw_addr[29]} {npu/prb_npu_axi_aw_addr[30]} {npu/prb_npu_axi_aw_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
set_property port_width 32 [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {npu/prb_npu_axi_ar_addr[0]} {npu/prb_npu_axi_ar_addr[1]} {npu/prb_npu_axi_ar_addr[2]} {npu/prb_npu_axi_ar_addr[3]} {npu/prb_npu_axi_ar_addr[4]} {npu/prb_npu_axi_ar_addr[5]} {npu/prb_npu_axi_ar_addr[6]} {npu/prb_npu_axi_ar_addr[7]} {npu/prb_npu_axi_ar_addr[8]} {npu/prb_npu_axi_ar_addr[9]} {npu/prb_npu_axi_ar_addr[10]} {npu/prb_npu_axi_ar_addr[11]} {npu/prb_npu_axi_ar_addr[12]} {npu/prb_npu_axi_ar_addr[13]} {npu/prb_npu_axi_ar_addr[14]} {npu/prb_npu_axi_ar_addr[15]} {npu/prb_npu_axi_ar_addr[16]} {npu/prb_npu_axi_ar_addr[17]} {npu/prb_npu_axi_ar_addr[18]} {npu/prb_npu_axi_ar_addr[19]} {npu/prb_npu_axi_ar_addr[20]} {npu/prb_npu_axi_ar_addr[21]} {npu/prb_npu_axi_ar_addr[22]} {npu/prb_npu_axi_ar_addr[23]} {npu/prb_npu_axi_ar_addr[24]} {npu/prb_npu_axi_ar_addr[25]} {npu/prb_npu_axi_ar_addr[26]} {npu/prb_npu_axi_ar_addr[27]} {npu/prb_npu_axi_ar_addr[28]} {npu/prb_npu_axi_ar_addr[29]} {npu/prb_npu_axi_ar_addr[30]} {npu/prb_npu_axi_ar_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list ddr_inst/u_sy_axi4_arbiter/prb_axi_oup_ar_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list ddr_inst/u_sy_axi4_arbiter/prb_axi_oup_ar_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list ddr_inst/u_sy_axi4_arbiter/prb_axi_sel]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list main_mem/probe_ctrl_inst/prb_cc_a_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list main_mem/probe_ctrl_inst/prb_cc_a_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list ddr_inst/prb_ddr_ar_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list ddr_inst/prb_ddr_ar_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list ddr_inst/prb_ddr_aw_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list ddr_inst/prb_ddr_aw_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list ddr_inst/prb_ddr_r_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe40]
set_property port_width 1 [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list ddr_inst/prb_ddr_r_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
set_property port_width 1 [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list ddr_inst/prb_ddr_w_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe42]
set_property port_width 1 [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list ddr_inst/prb_ddr_w_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list dma_inst/prb_dma_a_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
set_property port_width 1 [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list dma_inst/prb_dma_a_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
set_property port_width 1 [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list dma_inst/prb_dma_c_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
set_property port_width 1 [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list dma_inst/prb_dma_c_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
set_property port_width 1 [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list dma_inst/prb_dma_d_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
set_property port_width 1 [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list dma_inst/prb_dma_d_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
set_property port_width 1 [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list dma_inst/prb_dma_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
set_property port_width 1 [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list dma_inst/prb_dma_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe51]
set_property port_width 1 [get_debug_ports u_ila_0/probe51]
connect_debug_port u_ila_0/probe51 [get_nets [list dma_inst/prb_fifo_empty]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe52]
set_property port_width 1 [get_debug_ports u_ila_0/probe52]
connect_debug_port u_ila_0/probe52 [get_nets [list dma_inst/prb_fifo_full]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe53]
set_property port_width 1 [get_debug_ports u_ila_0/probe53]
connect_debug_port u_ila_0/probe53 [get_nets [list dma_inst/prb_fifo_pop]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe54]
set_property port_width 1 [get_debug_ports u_ila_0/probe54]
connect_debug_port u_ila_0/probe54 [get_nets [list dma_inst/prb_fifo_push]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe55]
set_property port_width 1 [get_debug_ports u_ila_0/probe55]
connect_debug_port u_ila_0/probe55 [get_nets [list npu/prb_npu_axi_ar_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe56]
set_property port_width 1 [get_debug_ports u_ila_0/probe56]
connect_debug_port u_ila_0/probe56 [get_nets [list npu/prb_npu_axi_ar_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe57]
set_property port_width 1 [get_debug_ports u_ila_0/probe57]
connect_debug_port u_ila_0/probe57 [get_nets [list npu/prb_npu_axi_aw_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe58]
set_property port_width 1 [get_debug_ports u_ila_0/probe58]
connect_debug_port u_ila_0/probe58 [get_nets [list npu/prb_npu_axi_aw_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
