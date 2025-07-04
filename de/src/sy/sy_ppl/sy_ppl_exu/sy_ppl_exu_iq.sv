// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_exu_iq.v
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

module sy_ppl_exu_iq
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From Dispatch]
    input   logic                           dis_exu__vld_i,          
    output  logic                           exu_dis__rdy_o,          
    input   exu_packet_t                    dis_exu__packet_i,
    // =====================================
    // [Issue]
    output  logic                           issue_vld_o,
    input   logic                           issue_rdy_i,
    output  exu_packet_t                    issue_packet_o,
    // =====================================
    // [Awake]
    // alu
    input   logic                           alu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          alu_awake_idx_i,
    // alu
    input   logic                           csr_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          csr_awake_idx_i,
    // lsu
    input   logic                           lsu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          lsu_awake_idx_i,
    input   logic                           lsu_awake_is_fp_i,
    // mdu
    input   logic                           mdu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_awake_idx_i,
    // fpu
    input   logic                           fpu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_awake_idx_i,
    input   logic                           fpu_awake_is_fp_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    exu_packet_t [EXU_IQ_LEN-1:0]           exu_iq_d,exu_iq_q;
    logic[EXU_IQ_LEN-1:0]                   rs1_ready;
    logic[EXU_IQ_LEN-1:0]                   rs2_ready;
    logic[EXU_IQ_LEN-1:0]                   rs3_ready;
    logic[EXU_IQ_LEN-1:0]                   rs1_state_d,rs1_state_q;
    logic[EXU_IQ_LEN-1:0]                   rs2_state_d,rs2_state_q;
    logic[EXU_IQ_LEN-1:0]                   rs3_state_d,rs3_state_q;
    logic[EXU_IQ_WTH:0]                     ins_idx_d, ins_idx_q;
    logic                                   ins_en;               
    logic                                   del_en;   
    logic[EXU_IQ_WTH:0]                     cnt_d, cnt_q;        
    logic                                   iq_is_full;
    logic                                   iq_is_empty;   
    logic                                   sel_act;        
    logic[EXU_IQ_WTH-1:0]                   sel_idx;        
//======================================================================================================================
// Issue Queue
//======================================================================================================================
    assign iq_is_full = (cnt_q == EXU_IQ_LEN);
    assign iq_is_empty = (cnt_q == 0);
    assign exu_dis__rdy_o = ~iq_is_full;
    assign ins_en = dis_exu__vld_i && exu_dis__rdy_o;
    // insert new instr to issue queen
    // The IQ(Issue Queue) is a compressed issue queen
    always_comb begin : rs_state
        for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
            // awake
            if (i == ins_idx_q && ins_en) begin
                rs1_state_d[i] = dis_exu__packet_i.rs1_state;
                rs2_state_d[i] = dis_exu__packet_i.rs2_state;
                rs3_state_d[i] = dis_exu__packet_i.rs3_state;
            end else begin
                rs1_state_d[i] = rs1_state_q[i];
                rs2_state_d[i] = rs2_state_q[i];
                rs3_state_d[i] = rs3_state_q[i];
                // RS1
                // General purpose register
                if (!exu_iq_q[i].rs1_is_fp) begin
                    if (alu_awake_vld_i && alu_awake_idx_i == exu_iq_q[i].phy_rs1_idx || 
                        csr_awake_vld_i && csr_awake_idx_i == exu_iq_q[i].phy_rs1_idx || 
                        lsu_awake_vld_i && lsu_awake_idx_i == exu_iq_q[i].phy_rs1_idx && !lsu_awake_is_fp_i || 
                        mdu_awake_vld_i && mdu_awake_idx_i == exu_iq_q[i].phy_rs1_idx || 
                        fpu_awake_vld_i && fpu_awake_idx_i == exu_iq_q[i].phy_rs1_idx && !fpu_awake_is_fp_i
                    ) begin
                        rs1_state_d[i] = 1'b1;        
                    end                   
                // float point register
                end else begin
                    if (lsu_awake_vld_i && lsu_awake_idx_i == exu_iq_q[i].phy_rs1_idx && lsu_awake_is_fp_i || 
                        fpu_awake_vld_i && fpu_awake_idx_i == exu_iq_q[i].phy_rs1_idx && fpu_awake_is_fp_i
                    ) begin
                        rs1_state_d[i] = 1'b1;        
                    end               
                end
                // RS2
                // General purpose register
                if (!exu_iq_q[i].rs2_is_fp) begin
                    if (alu_awake_vld_i && alu_awake_idx_i == exu_iq_q[i].phy_rs2_idx || 
                        csr_awake_vld_i && csr_awake_idx_i == exu_iq_q[i].phy_rs2_idx || 
                        lsu_awake_vld_i && lsu_awake_idx_i == exu_iq_q[i].phy_rs2_idx && !lsu_awake_is_fp_i || 
                        mdu_awake_vld_i && mdu_awake_idx_i == exu_iq_q[i].phy_rs2_idx || 
                        fpu_awake_vld_i && fpu_awake_idx_i == exu_iq_q[i].phy_rs2_idx && !fpu_awake_is_fp_i
                    ) begin
                        rs2_state_d[i] = 1'b1;        
                    end
                // float point register
                end else begin
                     if (lsu_awake_vld_i && lsu_awake_idx_i == exu_iq_q[i].phy_rs2_idx && lsu_awake_is_fp_i || 
                         fpu_awake_vld_i && fpu_awake_idx_i == exu_iq_q[i].phy_rs2_idx && fpu_awake_is_fp_i
                    ) begin
                        rs2_state_d[i] = 1'b1;        
                    end               
                end
                // RS3 (RS3 always be  float point register)
                // float point register
                if (lsu_awake_vld_i && lsu_awake_idx_i == exu_iq_q[i].phy_rs3_idx && lsu_awake_is_fp_i || 
                    fpu_awake_vld_i && fpu_awake_idx_i == exu_iq_q[i].phy_rs3_idx && fpu_awake_is_fp_i
                ) begin
                    rs3_state_d[i] = 1'b1;        
                end               
            end
        end 
    end

    always_comb begin : iq_gen
        for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
            exu_iq_d[i] = exu_iq_q[i];
            if (del_en) begin
                if (i >= sel_idx && i < (ins_idx_q - 1) && i < (EXU_IQ_LEN - 1)) begin
                    exu_iq_d[i] = exu_iq_q[i+1];  // make IQ compressed
                end else if (i == (ins_idx_q - 1) && ins_en)begin
                    exu_iq_d[i] = dis_exu__packet_i;   
                end
            end else begin
                if (i == ins_idx_q && ins_en) begin
                    exu_iq_d[i] = dis_exu__packet_i; // insert new instr
                end              
            end
        end 
    end
    always_comb begin : ins_idx
        ins_idx_d = ins_idx_q;
        cnt_d = cnt_q;
        if (flush_i) begin
            ins_idx_d = '0;
            cnt_d = '0;
        end else if (del_en && ins_en) begin  // don't change
            ins_idx_d = ins_idx_q;
            cnt_d = cnt_q;
        end else if (del_en) begin     // -1
            ins_idx_d = ins_idx_q - 1;
            cnt_d = cnt_q - 1;
        end else if (ins_en) begin
            ins_idx_d = ins_idx_q + 1; // +1
            cnt_d = cnt_q + 1;
        end 
    end
//======================================================================================================================
// Select an instr
//======================================================================================================================
    // select an instr to issue
    always_comb begin
        sel_act = 1'b0;
        sel_idx = '0;
        for (integer i=EXU_IQ_LEN-1; i>=0; i=i-1) begin
            rs1_ready[i] =  rs1_state_q[i]; 
            rs2_ready[i] =  rs2_state_q[i]; 
            rs3_ready[i] =  rs3_state_q[i]; 
            if ((i < ins_idx_q) && rs1_ready[i] && rs2_ready[i] && rs3_ready[i] && !iq_is_empty) begin
                sel_act = 1'b1;
                sel_idx = i;
            end
        end
    end
    assign issue_vld_o = sel_act && !flush_i;
    assign issue_packet_o = exu_iq_q[sel_idx];
    assign del_en = issue_vld_o & issue_rdy_i;
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
                exu_iq_q[i] <= exu_packet_t'(0);
            end
            ins_idx_q   <= '0;
            cnt_q       <= '0;
        end else begin
            for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
                exu_iq_q[i] <= exu_iq_d[i];
            end
            ins_idx_q   <= ins_idx_d;
            cnt_q       <= cnt_d;
        end
    end
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
                rs1_state_q[i] <= 1'b0;
                rs2_state_q[i] <= 1'b0;
                rs3_state_q[i] <= 1'b0;
            end
        end else begin
            for (integer i=0; i<EXU_IQ_LEN; i=i+1) begin
                if (i >= sel_idx && del_en && i < (EXU_IQ_LEN-1)) begin
                    rs1_state_q[i] <= rs1_state_d[i+1];
                    rs2_state_q[i] <= rs2_state_d[i+1];
                    rs3_state_q[i] <= rs3_state_d[i+1];
                end else begin
                    rs1_state_q[i] <= rs1_state_d[i];
                    rs2_state_q[i] <= rs2_state_d[i];
                    rs3_state_q[i] <= rs3_state_d[i];
                end
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_exu_iq
