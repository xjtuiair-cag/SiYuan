// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_mdu.v
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

module sy_ppl_mdu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [block control]
    //! If CTRL module sends kill command, current instruction should be set as invalid.
    //! This kill instruction can disable all phases's signals except phase[BASE].
    input   logic                           ctrl_x__mem_kill_i,
    // =====================================
    // [to ppl_ctrl]
    // status of FUs
    output  logic                           mdu_ctrl__mul_act_o,
    output  logic                           mdu_ctrl__div_act_o,
    // =====================================
    // [to ppl_dec]
    input   logic                           dec_mdu__ex0_avail_i,
    input   logic[AWTH-1:0]                 dec_mdu__pc_i,
    input   mdu_opcode_e                    dec_mdu__mdu_opcode_i,
    input   logic                           dec_mdu__rs1_sign_i,
    input   logic                           dec_mdu__rs2_sign_i,
    input   logic[DWTH-1:0]                 dec_mdu__rs1_data_i,
    input   logic[DWTH-1:0]                 dec_mdu__rs2_data_i,
    input   logic[4:0]                      dec_mdu__rdst_idx_i,
    //modified by liushenghuan
    input   logic                           dec_mdu__only_word_i,
    // output the block information
    output  logic[MUL_STAGE-1:0]            mdu_dec__blk_en_mul_o,
    output  logic[MUL_STAGE-1:0][4:0]       mdu_dec__blk_idx_mul_o,
    output  logic                           mdu_dec__blk_en_div_o,
    output  logic[4:0]                      mdu_dec__blk_idx_div_o,
    // status of MDU
    output  logic                           mdu_alu__mul_wb_busy_o,
    output  logic                           mdu_alu__div_wb_busy_o,
    // =====================================
    // [to ppl_reg]
    output  logic                           mdu_reg__rdst_en_o,
    output  logic[4:0]                      mdu_reg__rdst_idx_o,
    output  logic[DWTH-1:0]                 mdu_reg__rdst_data_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic[MUL_STAGE-1:0]                mul_act_dlychain;
logic[MUL_STAGE-1:0]                mulh_act_dlychain;
logic[MUL_STAGE-1:0][4:0]           mul_rdst_idx_dlychain;
logic[MUL_STAGE-1:0]                mul_only_word;
logic[127:0]                        mul_prod;
logic                               div_type;
logic[4:0]                          div_rdst_idx;
logic[4:0]                          div_cnt;
logic                               div_only_word;
logic[DWTH-1:0]                     rs1_jdg;
logic[DWTH-1:0]                     rs2_jdg;
logic                               div_start;
logic                               div_sign;
logic[63:0]                         quo_sign_data;
logic[63:0]                         rem_sign_data;
logic[63:0]                         quo_uns_data;
logic[63:0]                         rem_uns_data;
logic[DWTH-1:0]                     quo_data_revised;
logic[DWTH-1:0]                     rem_data_revised;
logic[DWTH-1:0]                     dividend;
logic[DWTH-1:0]                     divisor;

//======================================================================================================================
// Instance
//======================================================================================================================

// -----
// For Multiply operation

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        for(integer i=0; i<MUL_STAGE; i=i+1) begin
            mul_act_dlychain[i] <= `TCQ 1'b0;
            mulh_act_dlychain[i] <= `TCQ 1'b0;
            mul_rdst_idx_dlychain[i] <= `TCQ 5'h0;
            mul_only_word[i] <= `TCQ 1'b0;
        end
    end else begin
        if(ctrl_x__mem_kill_i) begin
            for(integer i=0; i<MUL_STAGE-1; i=i+1) begin
                mul_act_dlychain[i] <= `TCQ 1'b0;
                mulh_act_dlychain[i] <= `TCQ 1'b0;
                mul_rdst_idx_dlychain[i] <= `TCQ 5'h0;
                mul_only_word[i] <= `TCQ 1'b0;
            end
        end else begin
            mul_act_dlychain <= `TCQ {mul_act_dlychain, dec_mdu__ex0_avail_i && dec_mdu__mdu_opcode_i == MDU_OP_MUL};
            mulh_act_dlychain <= `TCQ {mulh_act_dlychain, dec_mdu__ex0_avail_i && dec_mdu__mdu_opcode_i == MDU_OP_MULH};
            mul_rdst_idx_dlychain <= `TCQ {mul_rdst_idx_dlychain, dec_mdu__rdst_idx_i};
            mul_only_word <= `TCQ {mul_only_word, dec_mdu__only_word_i && (dec_mdu__mdu_opcode_i == MDU_OP_MUL)};
        end
    end
end

mul64x64_d3_wrap u_mul64x64_d3_wrap (
    .clk_i                              (clk_i),
    .rst_ni                             (rst_i),
    .a_i                                (dec_mdu__rs1_data_i),
    .sign_a_i                           (dec_mdu__rs1_sign_i),
    .b_i                                (dec_mdu__rs2_data_i),
    .sign_b_i                           (dec_mdu__rs2_sign_i),
    .prod_o                             (mul_prod)
);

assign mdu_ctrl__mul_act_o = (|mul_act_dlychain) || (|mulh_act_dlychain) || mdu_reg__rdst_en_o;
assign mdu_alu__mul_wb_busy_o = mul_act_dlychain[MUL_STAGE-1] || mulh_act_dlychain[MUL_STAGE-1];

// output the block information
assign mdu_dec__blk_en_mul_o = mul_act_dlychain | mulh_act_dlychain;
assign mdu_dec__blk_idx_mul_o = mul_rdst_idx_dlychain;

// -----
// For Divid operation

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        div_type <= `TCQ 1'b0; //0:div, 1:rem
        div_rdst_idx <= `TCQ 5'h0;
        div_cnt <= `TCQ 5'h0;
        div_sign <= 1'b0; 
        mdu_alu__div_wb_busy_o <= `TCQ 1'b0;
        div_only_word <= 1'b0;
    end else begin
        if(ctrl_x__mem_kill_i && (div_cnt > 5'h12)) begin // > 18
            div_cnt <= `TCQ 5'h0;
            mdu_alu__div_wb_busy_o <= `TCQ 1'b0; 
            div_rdst_idx <= `TCQ 5'h0;
            div_type <= 1'b0;
            div_only_word <= 1'b0;
            div_sign <= 1'b0;
        end else if(dec_mdu__ex0_avail_i && dec_mdu__mdu_opcode_i == MDU_OP_DIV) begin
            div_type <= `TCQ 1'b0;
            div_rdst_idx <= `TCQ dec_mdu__rdst_idx_i;
            div_cnt <= `TCQ DIV_STAGE;
            div_only_word <= `TCQ dec_mdu__only_word_i;
            div_sign <= dec_mdu__rs1_sign_i;
        end else if(dec_mdu__ex0_avail_i && dec_mdu__mdu_opcode_i == MDU_OP_REM) begin
            div_type <= `TCQ 1'b1;
            div_rdst_idx <= `TCQ dec_mdu__rdst_idx_i;
            div_cnt <= `TCQ DIV_STAGE;
            div_only_word  <= `TCQ dec_mdu__only_word_i;
            div_sign <= dec_mdu__rs1_sign_i;
        end else begin
            div_cnt <= `TCQ (div_cnt == 5'h0) ? 5'h0 : div_cnt - 1'b1;
            mdu_alu__div_wb_busy_o <= `TCQ (div_cnt == 5'h2);
            div_rdst_idx <= div_rdst_idx;
            div_type <= div_type;
            div_only_word <= div_only_word;
            div_sign <= div_sign;
        end
    end
end

always_ff @(posedge clk_i) begin
    if(dec_mdu__ex0_avail_i && (div_cnt == 5'h0)) begin
        rs1_jdg <= `TCQ dec_mdu__rs1_data_i;
        rs2_jdg <= `TCQ dec_mdu__rs2_data_i;
    end
end

assign div_start = dec_mdu__ex0_avail_i && (dec_mdu__mdu_opcode_i == MDU_OP_DIV || dec_mdu__mdu_opcode_i == MDU_OP_REM);

always_comb begin: gen_div_oprand
    dividend = dec_mdu__rs1_data_i;
    divisor  = dec_mdu__rs2_data_i;
    if(dec_mdu__only_word_i) begin
        if(dec_mdu__rs1_sign_i) begin
            dividend = {{32{dec_mdu__rs1_data_i[31]}}, dec_mdu__rs1_data_i[31:0]};
            divisor  = {{32{dec_mdu__rs2_data_i[31]}}, dec_mdu__rs2_data_i[31:0]};
        end else begin
            dividend = {32'b0, dec_mdu__rs1_data_i[31:0]};
            divisor  = {32'b0, dec_mdu__rs2_data_i[31:0]};
        end
    end
end

div64x64_d20_wrap u_div64x64_d20_wrap (
    .clk_i                              (clk_i),
    .dividend_i                         (dividend),
    .divisor_i                          (divisor),
    .start_i                            (div_start),
    .quotient_sign_o                    (quo_sign_data),
    .remainder_sign_o                   (rem_sign_data),
    .quotient_uns_o                     (quo_uns_data),
    .remainder_uns_o                    (rem_uns_data)

);

assign quo_data_revised = (rs2_jdg == DWTH'(0)) ? DWTH'(0) - 1
                        : (div_sign ? ((rs1_jdg == {1'b1,{DWTH-1{1'b0}}} && rs2_jdg == DWTH'(0)-1) ? {1'b1,{DWTH-1{1'b0}}}
                        : quo_sign_data) : quo_uns_data);
assign rem_data_revised = (rs2_jdg == DWTH'(0)) ? rs1_jdg 
                        : (div_sign ? ((rs1_jdg == {1'b1,{DWTH-1{1'b0}}} && rs2_jdg == DWTH'(0)-1) ? DWTH'(0)
                        : rem_sign_data) : rem_uns_data);
// assign quo_data_revised = div_sign ? quo_sign_data : quo_uns_data;
// assign rem_data_revised = div_sign ? rem_sign_data : rem_uns_data;

// output the block information
assign mdu_dec__blk_en_div_o = |div_cnt;
assign mdu_dec__blk_idx_div_o = div_rdst_idx;

// the output of MDU module.
always_ff @(posedge clk_i) begin
    if(mul_act_dlychain[MUL_STAGE-1]) begin
        mdu_reg__rdst_en_o <= `TCQ (mul_rdst_idx_dlychain[MUL_STAGE-1] != 5'h0);
        mdu_reg__rdst_idx_o <= `TCQ mul_rdst_idx_dlychain[MUL_STAGE-1];
        mdu_reg__rdst_data_o <= `TCQ mul_only_word[MUL_STAGE-1] ? {{32{mul_prod[31]}}, mul_prod[31:0]} : mul_prod;
    end else if(mulh_act_dlychain[MUL_STAGE-1]) begin
        mdu_reg__rdst_en_o <= `TCQ (mul_rdst_idx_dlychain[MUL_STAGE-1] != 5'h0);
        mdu_reg__rdst_idx_o <= `TCQ mul_rdst_idx_dlychain[MUL_STAGE-1];
        mdu_reg__rdst_data_o <= `TCQ mul_prod[127:64];
    end else begin
        mdu_reg__rdst_en_o <= `TCQ mdu_alu__div_wb_busy_o && (div_rdst_idx != 5'h0);
        mdu_reg__rdst_idx_o <= `TCQ div_rdst_idx;
        mdu_reg__rdst_data_o <= `TCQ div_type ? (div_only_word ? {{32{rem_data_revised[31]}}, rem_data_revised[31:0]} : rem_data_revised)
                                    : (div_only_word ? {{32{quo_data_revised[31]}},quo_data_revised[31:0]} : quo_data_revised);
    end
end

assign mdu_ctrl__div_act_o = (|div_cnt) || mdu_reg__rdst_en_o;

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_mdu
