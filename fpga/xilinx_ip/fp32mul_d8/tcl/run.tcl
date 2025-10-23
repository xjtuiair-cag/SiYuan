set partNumber $::env(XILINX_PART)
set boardName  $::env(XILINX_BOARD)

set ipName fp32mul_d8
create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name $ipName

set_property -dict {
  CONFIG.Operation_Type {Multiply}
  CONFIG.A_Precision_Type {Single}
  CONFIG.C_A_Exponent_Width {8}
  CONFIG.C_A_Fraction_Width {24}
  CONFIG.Result_Precision_Type {Single}
  CONFIG.C_Result_Exponent_Width {8}
  CONFIG.C_Result_Fraction_Width {24}
  CONFIG.C_Mult_Usage {Full_Usage}
  CONFIG.Flow_Control {NonBlocking}
  CONFIG.Has_RESULT_TREADY {false}
  CONFIG.Maximum_Latency {true}
  CONFIG.C_Latency {8}
  CONFIG.C_Rate {1}
} [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1

