// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_butfly.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : butterfly operation
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

module sy_fft_butfly#(
)(
    input  logic                                clk_i,           
    // operand A
    input  logic                                A_valid,
    input  logic [31:0]                         A_data_real,
    input  logic [31:0]                         A_data_img,
    // operand B
    input  logic                                B_valid,
    input  logic [31:0]                         B_data_real,
    input  logic [31:0]                         B_data_img,
    // Weight
    input  logic                                W_valid,
    input  logic [31:0]                         W_data_real,
    input  logic [31:0]                         W_data_img,
    // result
    output logic                                res_valid,
    output logic [31:0]                         res_A_data_real,
    output logic [31:0]                         res_A_data_img,
    output logic [31:0]                         res_B_data_real,
    output logic [31:0]                         res_B_data_img
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam DLY_NUM = 16;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [31:0]                                B_r_mul_W_r;
    logic                                       B_r_mul_W_r_vld;
    logic [31:0]                                B_i_mul_W_i;
    logic                                       B_i_mul_W_i_vld;
    logic [31:0]                                B_r_mul_W_i;
    logic                                       B_r_mul_W_i_vld;
    logic [31:0]                                B_i_mul_W_r;
    logic                                       B_i_mul_W_r_vld;
    logic                                       A_valid_dlc[DLY_NUM:0];
    logic [31:0]                                A_data_real_dlc[DLY_NUM:0];
    logic [31:0]                                A_data_img_dlc[DLY_NUM:0];
    logic                                       B_r_W_r_sub_B_i_W_i_vld;
    logic [31:0]                                B_r_W_r_sub_B_i_W_i;
    logic                                       B_r_W_i_add_B_i_W_r_vld;
    logic [31:0]                                B_r_W_i_add_B_i_W_r;
//======================================================================================================================
// Formula
//======================================================================================================================
    // input : A, B, W
    // output: res_A = A + B * W, res_B = A - B * W
    // B * W = (B_r * W_r - B_i * W_i) + j (B_r * W_i + B_i * W_r)
    // res_A =  (A_r + B_r * W_r - B_i * W_i) + j (A_i + B_r * W_i + B_i * W_r)
    // res_B =  (A_r - B_r * W_r + B_i * W_i) + j (A_i - B_r * W_i - B_i * W_r)
//======================================================================================================================
// Multiply (Stage 0)
//======================================================================================================================
    // fp32 mul unit
    // B_r * W_r
    fp32mul_d8_wrap fp32mul_inst_0(
        .clk_i          (clk_i),
        .a_valid        (B_valid),
        .a_data         (B_data_real),
        .b_valid        (W_valid),
        .b_data         (W_data_real),
        .c_valid        (B_r_mul_W_r_vld),
        .c_data         (B_r_mul_W_r)
    );
    // B_i * W_i
    fp32mul_d8_wrap fp32mul_inst_1(
        .clk_i          (clk_i),
        .a_valid        (B_valid),
        .a_data         (B_data_img),
        .b_valid        (W_valid),
        .b_data         (W_data_img),
        .c_valid        (B_i_mul_W_i_vld),
        .c_data         (B_i_mul_W_i)
    );
    // B_r * W_i
    fp32mul_d8_wrap fp32mul_inst_2(
        .clk_i          (clk_i),
        .a_valid        (B_valid),
        .a_data         (B_data_real),
        .b_valid        (W_valid),
        .b_data         (W_data_img),
        .c_valid        (B_r_mul_W_i_vld),
        .c_data         (B_r_mul_W_i)
    );
    // B_i * W_r
    fp32mul_d8_wrap fp32mul_inst_3(
        .clk_i          (clk_i),
        .a_valid        (B_valid),
        .a_data         (B_data_img),
        .b_valid        (W_valid),
        .b_data         (W_data_real),
        .c_valid        (B_i_mul_W_r_vld),
        .c_data         (B_i_mul_W_r)
    );
//======================================================================================================================
// Add (stage 1)
//======================================================================================================================
    // B_r * W_r - B_i * W_i
    fp32sub_d8_wrap fp32sub_inst_0(
        .clk_i          (clk_i),
        .a_valid        (B_r_mul_W_r_vld),
        .a_data         (B_r_mul_W_r),
        .b_valid        (B_i_mul_W_i_vld),
        .b_data         (B_i_mul_W_i),
        .c_valid        (B_r_W_r_sub_B_i_W_i_vld),
        .c_data         (B_r_W_r_sub_B_i_W_i)
    );
    // B_r * W_i + B_i * W_r
    fp32add_d8_wrap fp32add_inst_0(
        .clk_i          (clk_i),
        .a_valid        (B_r_mul_W_i_vld),
        .a_data         (B_r_mul_W_i),
        .b_valid        (B_i_mul_W_r_vld),
        .b_data         (B_i_mul_W_r),
        .c_valid        (B_r_W_i_add_B_i_W_r_vld),
        .c_data         (B_r_W_i_add_B_i_W_r)
    );
//======================================================================================================================
// stage 2
//======================================================================================================================
    assign A_valid_dlc[0]       = A_valid;
    assign A_data_real_dlc[0]   = A_data_real;
    assign A_data_img_dlc[0]    = A_data_img;
    always_ff @(posedge clk_i) begin 
        A_valid_dlc[DLY_NUM : 1] <= A_valid_dlc[DLY_NUM-1 : 0];
        A_data_real_dlc[DLY_NUM : 1] <= A_data_real_dlc[DLY_NUM-1 : 0];
        A_data_img_dlc[DLY_NUM : 1] <= A_data_img_dlc[DLY_NUM-1 : 0];
    end

    // res_A_r = A_r + B_r * W_r - B_i * W_i
    fp32add_d8_wrap fp32add_inst_1(
        .clk_i          (clk_i),
        .a_valid        (A_valid_dlc[DLY_NUM]),
        .a_data         (A_data_real_dlc[DLY_NUM]),
        .b_valid        (B_r_W_r_sub_B_i_W_i_vld),
        .b_data         (B_r_W_r_sub_B_i_W_i),
        .c_valid        (res_valid),
        .c_data         (res_A_data_real)
    );
    // res_A_i = A_i + B_r * W_i + B_i * W_r
    fp32add_d8_wrap fp32add_inst_2(
        .clk_i          (clk_i),
        .a_valid        (A_valid_dlc[DLY_NUM]),
        .a_data         (A_data_img_dlc[DLY_NUM]),
        .b_valid        (B_r_W_i_add_B_i_W_r_vld),
        .b_data         (B_r_W_i_add_B_i_W_r),
        .c_valid        (),
        .c_data         (res_A_data_img)
    );

    // res_B_r = A_r - B_r * W_r + B_i * W_i
    fp32sub_d8_wrap fp32sub_inst_1(
        .clk_i          (clk_i),
        .a_valid        (A_valid_dlc[DLY_NUM]),
        .a_data         (A_data_real_dlc[DLY_NUM]),
        .b_valid        (B_r_W_r_sub_B_i_W_i_vld),
        .b_data         (B_r_W_r_sub_B_i_W_i),
        .c_valid        (),
        .c_data         (res_B_data_real)
    );
    // res_B_i = A_i - B_r * W_i - B_i * W_r
    fp32sub_d8_wrap fp32sub_inst_2(
        .clk_i          (clk_i),
        .a_valid        (A_valid_dlc[DLY_NUM]),
        .a_data         (A_data_img_dlc[DLY_NUM]),
        .b_valid        (B_r_W_i_add_B_i_W_r_vld),
        .b_data         (B_r_W_i_add_B_i_W_r),
        .c_valid        (),
        .c_data         (res_B_data_img)
    );
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule 