// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_arbiter.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : 
// -----------------------------------------------------------------------------
// PURPOSE    :
// -----------------------------------------------------------------------------
// PARAMETERS :
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Strategy   :
// Clock Domains    :
// Critical Timing  :
// Test Features    :
// Asynchronous I/F :
// Scan Methodology : N
// Instantiations   : N
// Synthesizable    : Y
// Other :
// -FHDR------------------------------------------------------------------------

module tl_arbiter #(
  parameter int unsigned N_MASTER   = 0,
  parameter type         DATA_T     = logic[0:0] 
) (
  input  logic                                  clk_i,
  input  logic                                  rst_i,

  input  DATA_T[N_MASTER-1:0]                   inp_data_i,
  input  logic [N_MASTER-1:0]                   inp_valid_i,
  output logic [N_MASTER-1:0]                   inp_ready_o,

  output DATA_T                                 oup_data_o,
  output logic                                  oup_valid_o,
  input  logic                                  oup_ready_i
);

  stream_arbiter #(
    .DATA_T (DATA_T),
    .N_INP  (N_MASTER)
  ) i_arb_inp (
    .clk_i        (clk_i),
    .rst_ni       (rst_i),
    .inp_data_i   (inp_data_i),
    .inp_valid_i  (inp_valid_i),
    .inp_ready_o  (inp_ready_o),
    .oup_data_o   (oup_data_o),
    .oup_valid_o  (oup_valid_o),
    .oup_ready_i  (oup_ready_i)
  );

endmodule