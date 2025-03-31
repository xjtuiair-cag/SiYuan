set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName sdp_512x64sd1
create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $ipName

set_property -dict { 
  CONFIG.Memory_Type {Simple_Dual_Port_RAM}
  CONFIG.Use_Byte_Write_Enable {true}
  CONFIG.Byte_Size {8}
  CONFIG.Write_Width_A {64}
  CONFIG.Write_Depth_A {512}
  CONFIG.Read_Width_A {64}
  CONFIG.Operating_Mode_A {WRITE_FIRST}
  CONFIG.Enable_A {Use_ENA_Pin}
  CONFIG.Write_Width_B {64}
  CONFIG.Read_Width_B {64}
  CONFIG.Enable_B {Use_ENB_Pin}
  CONFIG.Register_PortA_Output_of_Memory_Primitives {false}
  CONFIG.Register_PortB_Output_of_Memory_Primitives {false}
  CONFIG.Port_B_Clock {100}
  CONFIG.Port_B_Enable_Rate {100}
} [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1

