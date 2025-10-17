// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : fp32mul_d8_wrap.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     :wenzhe, jingming 
// AUTHOR'S EMAIL :
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

// compute C = A * B
module fp32mul_d8_wrap(
    input   logic        clk_i,
    input   logic        a_valid,
    input   logic [31:0] a_data,
    input   logic        b_valid,
    input   logic [31:0] b_data,
    output  logic        c_valid,
    output  logic [31:0] c_data
);
// for simulation
`ifdef PLATFORM_SIM
    localparam DLY_NUM = 8;
    shortreal ra, rb, rc;
    logic [31:0]         res_dlychain[DLY_NUM : 0];
    logic                valid_dlychain[DLY_NUM : 0];

    assign valid_dlychain[0] = a_valid & b_valid;
    always_comb begin
        ra = $bitstoshortreal(a_data);
        rb = $bitstoshortreal(b_data);
        rc = ra * rb;
        res_dlychain[0] = $shortrealtobits(rc);
    end
    always_ff @(posedge clk_i) begin
        res_dlychain[DLY_NUM : 1] <= res_dlychain[DLY_NUM-1 : 0];
        valid_dlychain[DLY_NUM : 1] <= valid_dlychain[DLY_NUM-1 : 0];
    end

    assign c_valid = valid_dlychain[DLY_NUM];
    assign c_data = res_dlychain[DLY_NUM];
`endif

// for FPGA
`ifdef PLATFORM_XILINX
`endif 
// for ASIC
`ifdef PLATFORM_ASIC
`endif

endmodule
