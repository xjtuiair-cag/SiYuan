// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_buffer.v
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

// mostly come from cva6 :https://github.com/openhwgroup/cva6 

module tl_buffer
  import tl_pkg::*;
#(
  parameter int BUF_DEPTH   = 0
)(
  input logic       clk_i  ,
  input logic       rst_i  ,
  TL_BUS.Master     in     ,
  TL_BUS.Slave      out
);

  if (BUF_DEPTH == 0) begin : no_buf
    tl_identity i_identity(
      .in  ( in  ),
      .out ( out )
    );
  end

  // Handle the special case of one cut.
  else if (BUF_DEPTH == 1) begin : only_buf_1
    tl_buf i_buf (
      .clk_i  ( clk_i  ),
      .rst_i  ( rst_i  ),
      .in     ( in     ),
      .out    ( out    )
    );
  end

  // Handle the cases of two or more cuts.
  else begin : buffer
    TL_BUS s_buf [BUF_DEPTH-1:0]();

    tl_buf i_first (
      .clk_i  ( clk_i           ),
      .rst_i  ( rst_i           ),
      .in     ( in              ),
      .out    ( s_buf[0].Master )
    );

    for (genvar i = 1; i < BUF_DEPTH-1; i++) begin
      tl_buf i_middle (
        .clk_i  ( clk_i             ),
        .rst_i  ( rst_i             ),
        .in     ( s_buf[i-1].Slave  ),
        .out    ( s_buf[i].Master   )
      );
    end

    tl_buf i_last (
      .clk_i  ( clk_i                   ),
      .rst_i  ( rst_i                   ),
      .in     ( s_buf[BUF_DEPTH-2].Slave),
      .out    ( out                     )
    );
  end

endmodule