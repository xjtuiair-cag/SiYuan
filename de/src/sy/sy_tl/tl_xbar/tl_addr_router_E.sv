// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_addr_router_E.v
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


module tl_addr_router_E 
    import tl_pkg::*;
#(
    parameter                   SLAVE_NUM       = 8,
    parameter                   SINK_LSB        = 2,   
    parameter                   SINK_MSB        = 4,   
    parameter  type             DATA_T          = logic[0:0]
) (
    input  logic                                                        clk_i,
    input  logic                                                        rst_i,

    input  logic                                                        e_valid_i,
    output logic                                                        e_ready_o,
    input  DATA_T                                                       e_bits_i,

    output logic [SLAVE_NUM-1:0]                                        e_valid_o,
    input  logic [SLAVE_NUM-1:0]                                        e_ready_i
);
  localparam                           ROUTE_NUM = 2**(SINK_MSB-SINK_LSB);

  logic [ROUTE_NUM-1:0]                 mask;
  logic [ROUTE_NUM-1:0]                 valid;
  logic [SINK_MSB-SINK_LSB-1:0]         routing;


  assign routing = e_bits_i.sink[SINK_MSB-1:SINK_LSB];

  always_comb begin
      mask = '0;
      mask[routing] = 1'b1;
  end
  
  assign valid = {ROUTE_NUM{e_valid_i}} & mask;
  assign e_valid_o = valid[SLAVE_NUM-1:0];
  assign e_ready_o = |(e_ready_i & mask[SLAVE_NUM-1:0]);

endmodule