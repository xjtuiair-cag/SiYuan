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
    // [clock & reset & flush_i]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [to ppl_dec]
    input   logic                           mdu_en_i,
    input   mdu_opcode_e                    mdu_opcode_i,
    input   logic                           mdu_rs1_sign_i,
    input   logic                           mdu_rs2_sign_i,
    input   logic[DWTH-1:0]                 mdu_rs1_data_i,
    input   logic[DWTH-1:0]                 mdu_rs2_data_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_rdst_idx_i,
    input   logic                           mdu_is_32_i,
    input   logic[ROB_WTH-1:0]              mdu_rob_idx_i,
    output  logic                           div_busy_o,
    output  logic                           div_wb_stall_o,
    // =====================================
    // [Awake]
    output  logic                           mdu_awake__vld_o,
    output  logic[PHY_REG_WTH-1:0]          mdu_awake__idx_o,
    // =====================================
    // [Awake]
    output  mdu_commit_t                    mdu_rob__commit_o,
    // =====================================
    // [to ppl_reg]
    output  logic                           mdu_gpr__we_o,
    output  logic[PHY_REG_WTH-1:0]          mdu_gpr__idx_o,
    output  logic[DWTH-1:0]                 mdu_gpr__wdata_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

    logic[MUL_STAGE-1:0]                mul_act_dlychain;
    logic[MUL_STAGE-1:0]                mulh_act_dlychain;
    logic[MUL_STAGE-1:0][PHY_REG_WTH-1:0] mul_rdst_idx_dlychain;
    logic[MUL_STAGE-1:0]                mul_is_32;
    logic[127:0]                        mul_prod;
    logic                               div_type;
    logic[PHY_REG_WTH-1:0]              div_rdst_idx;
    logic[4:0]                          div_cnt;
    logic                               div_is_32;
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
    logic[MUL_STAGE-1:0][ROB_WTH-1:0]   mul_rob_idx_dlychain;               
    logic[ROB_WTH-1:0]                  div_rob_idx;               
    logic[ROB_WTH-1:0]                  mdu_rob_idx;
    logic                               div_wr_en;
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
                mul_rdst_idx_dlychain[i] <= `TCQ '0;
                mul_is_32[i] <= `TCQ 1'b0;
                mul_rob_idx_dlychain[i] <= `TCQ '0;
            end
        end else begin
            if(flush_i) begin
                for(integer i=0; i<MUL_STAGE-1; i=i+1) begin
                    mul_act_dlychain[i] <= `TCQ 1'b0;
                    mulh_act_dlychain[i] <= `TCQ 1'b0;
                    mul_rdst_idx_dlychain[i] <= `TCQ '0;
                    mul_is_32[i] <= `TCQ 1'b0;
                    mul_rob_idx_dlychain[i] <= `TCQ '0;
                end
            end else begin
                mul_act_dlychain <= `TCQ {mul_act_dlychain, mdu_en_i && mdu_opcode_i == MDU_OP_MUL};
                mulh_act_dlychain <= `TCQ {mulh_act_dlychain, mdu_en_i && mdu_opcode_i == MDU_OP_MULH};
                mul_rdst_idx_dlychain <= `TCQ {mul_rdst_idx_dlychain, mdu_rdst_idx_i};
                mul_is_32<= `TCQ {mul_is_32, mdu_is_32_i && (mdu_opcode_i == MDU_OP_MUL)};
                mul_rob_idx_dlychain <= `TCQ {mul_rob_idx_dlychain, mdu_rob_idx_i};
            end
        end
    end

    mul64x64_d3_wrap u_mul64x64_d3_wrap (
        .clk_i                              (clk_i),
        .rst_ni                             (rst_i),
        .a_i                                (mdu_rs1_data_i),
        .sign_a_i                           (mdu_rs1_sign_i),
        .b_i                                (mdu_rs2_data_i),
        .sign_b_i                           (mdu_rs2_sign_i),
        .prod_o                             (mul_prod)
    );

    // -----
    // For Divid operation

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            div_type     <= `TCQ 1'b0; //0:div, 1:rem
            div_rdst_idx <= `TCQ 5'h0;
            div_cnt      <= `TCQ 5'h0;
            div_sign     <= 1'b0; 
            div_is_32    <= 1'b0;
            div_wb_stall_o  <= `TCQ 1'b0;
            div_rob_idx  <= `TCQ '0;
        end else begin
            if (flush_i) begin 
                div_cnt         <= `TCQ 5'h0;
                div_rdst_idx    <= `TCQ 5'h0;
                div_type        <= `TCQ 1'b0;
                div_is_32       <= `TCQ 1'b0;
                div_sign        <= `TCQ 1'b0;
                div_wb_stall_o  <= `TCQ 1'b0;
            end else if (mdu_en_i && mdu_opcode_i == MDU_OP_DIV) begin
                div_type        <= `TCQ 1'b0;
                div_rdst_idx    <= `TCQ mdu_rdst_idx_i;
                div_cnt         <= `TCQ DIV_STAGE;
                div_is_32       <= `TCQ mdu_is_32_i;
                div_sign        <= `TCQ mdu_rs1_sign_i;
                div_wb_stall_o  <= `TCQ 1'b0;
                div_rob_idx     <= `TCQ mdu_rob_idx_i;
            end else if (mdu_en_i && mdu_opcode_i == MDU_OP_REM) begin
                div_type        <= `TCQ 1'b1;
                div_rdst_idx    <= `TCQ mdu_rdst_idx_i;
                div_cnt         <= `TCQ DIV_STAGE;
                div_is_32       <= `TCQ mdu_is_32_i;
                div_sign        <= `TCQ mdu_rs1_sign_i;
                div_wb_stall_o  <= `TCQ 1'b0;
                div_rob_idx     <= `TCQ mdu_rob_idx_i;
            end else begin
                div_cnt         <= `TCQ (div_cnt == 5'h0) ? 5'h0 : div_cnt - 1'b1;
                div_rdst_idx    <= div_rdst_idx;
                div_type        <= div_type;
                div_is_32       <= div_is_32;
                div_sign        <= div_sign;
                div_wb_stall_o  <= `TCQ (div_cnt == 5'h5);
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if(mdu_en_i && (div_cnt == 5'h0)) begin
            rs1_jdg <= `TCQ mdu_rs1_data_i;
            rs2_jdg <= `TCQ mdu_rs2_data_i;
        end
    end

    assign div_start = mdu_en_i && (mdu_opcode_i == MDU_OP_DIV || mdu_opcode_i == MDU_OP_REM);
    assign div_wr_en = div_cnt == 5'h1;

    always_comb begin: gen_div_oprand
        dividend = mdu_rs1_data_i;
        divisor  = mdu_rs2_data_i;
        if (mdu_is_32_i) begin
            if(mdu_rs1_sign_i) begin
                dividend = {{32{mdu_rs1_data_i[31]}}, mdu_rs1_data_i[31:0]};
                divisor  = {{32{mdu_rs2_data_i[31]}}, mdu_rs2_data_i[31:0]};
            end else begin
                dividend = {32'b0, mdu_rs1_data_i[31:0]};
                divisor  = {32'b0, mdu_rs2_data_i[31:0]};
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
    
    // output the block information
    assign div_busy_o = |div_cnt;
    
    // the output of MDU module.
    always_ff @(posedge clk_i) begin
        if(mul_act_dlychain[MUL_STAGE-1]) begin
            mdu_gpr__we_o    <= `TCQ  1'b1;
            mdu_gpr__idx_o   <= `TCQ  mul_rdst_idx_dlychain[MUL_STAGE-1];
            mdu_gpr__wdata_o <= `TCQ  mul_is_32[MUL_STAGE-1] ? {{32{mul_prod[31]}}, mul_prod[31:0]} : mul_prod;
            mdu_rob_idx      <= `TCQ  mul_rob_idx_dlychain[MUL_STAGE-1];
        end else if(mulh_act_dlychain[MUL_STAGE-1]) begin
            mdu_gpr__we_o    <= `TCQ  1'b1;
            mdu_gpr__idx_o   <= `TCQ  mul_rdst_idx_dlychain[MUL_STAGE-1];
            mdu_gpr__wdata_o <= `TCQ  mul_prod[127:64];
            mdu_rob_idx      <= `TCQ  mul_rob_idx_dlychain[MUL_STAGE-1];
        end else begin
            mdu_gpr__we_o   <= `TCQ div_wr_en;
            mdu_gpr__idx_o  <= `TCQ div_rdst_idx;
            mdu_gpr__wdata_o <= `TCQ div_type ? (div_is_32 ? {{32{rem_data_revised[31]}},rem_data_revised[31:0]} : rem_data_revised)
                                             : (div_is_32 ? {{32{quo_data_revised[31]}},quo_data_revised[31:0]} : quo_data_revised);
            mdu_rob_idx      <= `TCQ  div_rob_idx;
        end
    end

    assign mdu_awake__vld_o = mdu_gpr__we_o;
    assign mdu_awake__idx_o = mdu_gpr__idx_o;
    
    assign mdu_rob__commit_o.vld     = mdu_gpr__we_o;
    assign mdu_rob__commit_o.rob_idx = mdu_rob_idx;
    
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_mdu
