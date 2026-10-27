// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_addr_router_C.v
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

module tl_addr_router_C
  import tl_pkg::*;
#(
    parameter int unsigned      ADDR_WIDTH     = 32,
    parameter                   SLAVE_NUM      = 8,
    parameter                   REGION_NUM     = 2,
    parameter  type             DATA_T         = logic[0:0]
)
(
    input  logic                                                        clk_i,
    input  logic                                                        rst_i,

    input  logic                                                        inp_valid_i,
    output logic                                                        inp_ready_o,
    input  logic [ADDR_WIDTH-1:0]                                       inp_addr_i,

    output logic [SLAVE_NUM-1:0]                                        oup_valid_o,
    input  logic [SLAVE_NUM-1:0]                                        oup_ready_i,

    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][ADDR_WIDTH-1:0]        start_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][ADDR_WIDTH-1:0]        end_addr_i,
    input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                        enable_region_i,
    input  logic [SLAVE_NUM-1:0]                                        connectivity_map_i
);


  logic [SLAVE_NUM-1:0]                                                 match_region; 
  logic [SLAVE_NUM:0]                                                   match_region_masked;
  logic [REGION_NUM-1:0][SLAVE_NUM-1:0]                                 match_region_int;
  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                                 match_region_rev;
  logic                                                                 error_detected;

  genvar i,j;
  generate
      // First calculate for each region where what slave ist matching
      for(j=0;j<REGION_NUM;j++) begin
           for(i=0;i<SLAVE_NUM;i++) begin
              assign match_region_int[j][i]  =  enable_region_i[i][j] && 
                        (inp_addr_i >= start_addr_i[i][j]) && (inp_addr_i <= end_addr_i[i][j]);
           end
      end
      // transpose the match_region_int bidimensional array
      for(j=0;j<SLAVE_NUM;j++) begin
           for(i=0;i<REGION_NUM;i++) begin
             assign match_region_rev[j][i] = match_region_int[i][j];
           end
      end

      //Or reduction
      for(i=0;i<SLAVE_NUM;i++) begin
        assign match_region[i] = |match_region_rev[i];
      end

      assign match_region_masked[SLAVE_NUM-1:0] = match_region & connectivity_map_i;

      // if there are no moatches, then assert an error
      assign match_region_masked[SLAVE_NUM] = ~(|match_region_masked[SLAVE_NUM-1:0]);
  endgenerate

  always_comb begin
        if(inp_valid_i) begin
            {error_detected,oup_valid_o} = {SLAVE_NUM+1{inp_valid_i}} & match_region_masked;
        end else begin
            oup_valid_o     = '0;
            error_detected  = 1'b0;
        end
        inp_ready_o = |(oup_ready_i & match_region_masked[SLAVE_NUM-1:0]);
  end

endmodule