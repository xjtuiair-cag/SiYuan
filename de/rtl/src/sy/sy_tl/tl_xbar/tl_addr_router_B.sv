// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_addr_router_B.v
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

module tl_addr_router_B
   import tl_pkg::*;
#(
   parameter int unsigned MASTER_NUM      = 0,
   parameter int unsigned SOURCE_LSB      = 0,
   parameter int unsigned SOURCE_MSB      = 0
) (
   input  logic                          inp_valid_i,
   output logic                          inp_ready_o,
   input  source_t                       inp_source_i,

   output logic [MASTER_NUM-1:0]         oup_valid_o,
   input  logic [MASTER_NUM-1:0]         oup_ready_i
);

   localparam                            ROUTE_NUM = 2**(SOURCE_MSB - SOURCE_LSB);
   logic [ROUTE_NUM-1:0]                 req_mask;
   logic [(SOURCE_MSB-SOURCE_LSB-1):0]   ROUTING;


   assign ROUTING = inp_source_i[SOURCE_MSB-1:SOURCE_LSB];

   always_comb begin
      req_mask = '0;
      req_mask[ROUTING] = 1'b1;
   end

   always_comb begin
      if (inp_valid_i) begin
         oup_valid_o= {ROUTE_NUM{inp_valid_i}} & req_mask;
      end else begin
         oup_valid_o = '0;
      end
      inp_ready_o = |(oup_ready_i & req_mask[MASTER_NUM-1:0]);
   end

 endmodule