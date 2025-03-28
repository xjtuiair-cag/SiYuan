// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : div64x64_d20_wrap.v
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

module div64x64_d20_wrap(
    input   logic                       clk_i,
    input   logic[63:0]                 dividend_i,
    input   logic[63:0]                 divisor_i,
    input   logic                       start_i,
    output  logic[63:0]                 quotient_sign_o,
    output  logic[63:0]                 remainder_sign_o,
    output  logic[63:0]                 quotient_uns_o,
    output  logic[63:0]                 remainder_uns_o

);

`ifdef PLATFORM_SIM
localparam DLY_NUM = 20;
logic[64:0] quo_dlychain_sign[DLY_NUM : 0];
logic[64:0] rem_dlychain_sign[DLY_NUM : 0];
logic[64:0] quo_dlychain_uns[DLY_NUM : 0];
logic[64:0] rem_dlychain_uns[DLY_NUM : 0];

logic signed[64:0] quo_sign_tmp, rem_sign_tmp;
logic[64:0] quo_uns_tmp, rem_uns_tmp;
logic signed[64:0] quo_sign, rem_sign;
logic[64:0] quo_uns, rem_uns;

assign quo_sign_tmp = (divisor_i == 0) ? 0 : $signed(dividend_i) / $signed(divisor_i);
assign rem_sign_tmp = (divisor_i == 0) ? 0 : $signed(dividend_i) % $signed(divisor_i);
assign quo_uns_tmp  = (divisor_i == 0) ? 0 : dividend_i / divisor_i;
assign rem_uns_tmp  = (divisor_i == 0) ? 0 : dividend_i % divisor_i;

assign quo_sign = (dividend_i==64'h8000000000000000 && divisor_i==64'hffffffffffffffff) ? 64'h8000000000000000 : quo_sign_tmp;
assign rem_sign = (dividend_i==64'h8000000000000000 && divisor_i==64'hffffffffffffffff) ? 64'h8000000000000000 : rem_sign_tmp;
assign quo_uns  = (dividend_i==64'h8000000000000000 && divisor_i==64'hffffffffffffffff) ? 64'h0000000000000000 : quo_uns_tmp;
assign rem_uns  = (dividend_i==64'h8000000000000000 && divisor_i==64'hffffffffffffffff) ? 64'h8000000000000000 : rem_uns_tmp;

assign quo_dlychain_sign[0] = quo_sign;
assign rem_dlychain_sign[0] = rem_sign;
assign quo_dlychain_uns[0] = quo_uns;
assign rem_dlychain_uns[0] = rem_uns;

always_ff @(posedge clk_i) begin
    quo_dlychain_sign[DLY_NUM : 1] <= quo_dlychain_sign[DLY_NUM-1 : 0];
    rem_dlychain_sign[DLY_NUM : 1] <= rem_dlychain_sign[DLY_NUM-1 : 0];
    quo_dlychain_uns[DLY_NUM : 1]  <= quo_dlychain_uns[DLY_NUM-1 : 0];
    rem_dlychain_uns[DLY_NUM : 1]  <= rem_dlychain_uns[DLY_NUM-1 : 0];
end

assign quotient_sign_o = quo_dlychain_sign[DLY_NUM];
assign remainder_sign_o = rem_dlychain_sign[DLY_NUM];
assign quotient_uns_o = quo_dlychain_uns[DLY_NUM];
assign remainder_uns_o = rem_dlychain_uns[DLY_NUM];

`endif

`ifdef PLATFORM_XILINX

div64x64_d20_s u_div64x64_d20_s (
    .aclk                               (clk_i),                                // IN STD_LOGIC;
    .s_axis_divisor_tvalid              (start_i),                              // IN STD_LOGIC;
    .s_axis_divisor_tready              (),                                     // OUT STD_LOGIC;
    .s_axis_divisor_tdata               (divisor_i),                              // IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    .s_axis_dividend_tvalid             (start_i),                              // IN STD_LOGIC;
    .s_axis_dividend_tready             (),                                     // OUT STD_LOGIC;
    .s_axis_dividend_tdata              (dividend_i),                             // IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    .m_axis_dout_tvalid                 (),                                     // OUT STD_LOGIC;
    .m_axis_dout_tdata                  ({quotient_sign_o,remainder_sign_o}) // OUT STD_LOGIC_VECTOR(79 DOWNTO 0)
);

div64x64_d20_us u_div64x64_d20_us (
    .aclk                               (clk_i),                                // IN STD_LOGIC;
    .s_axis_divisor_tvalid              (start_i),                              // IN STD_LOGIC;
    .s_axis_divisor_tready              (),                                     // OUT STD_LOGIC;
    .s_axis_divisor_tdata               (divisor_i),                              // IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    .s_axis_dividend_tvalid             (start_i),                              // IN STD_LOGIC;
    .s_axis_dividend_tready             (),                                     // OUT STD_LOGIC;
    .s_axis_dividend_tdata              (dividend_i),                             // IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    .m_axis_dout_tvalid                 (),                                     // OUT STD_LOGIC;
    .m_axis_dout_tdata                  ({quotient_uns_o,remainder_uns_o}) // OUT STD_LOGIC_VECTOR(79 DOWNTO 0)
);

`endif

`ifdef PLATFORM_ASIC

`endif

endmodule : div64x64_d20_wrap
