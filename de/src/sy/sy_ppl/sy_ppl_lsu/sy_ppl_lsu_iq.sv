// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu_iq.v
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

module sy_ppl_lsu_iq
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
    input   logic                           dis_lsu__vld_i,          
    output  logic                           lsu_dis__rdy_o,          
    input   lsu_packet_t                    dis_lsu__packet_i,
    // =====================================
    // [Issue to access D$]
    output  logic                           iq_issue_vld_o,
    input   logic                           iq_issue_rdy_i,
    output  logic[AWTH-1:0]                 iq_issue_paddr_o,
    output  logic[DWTH-1:0]                 iq_issue_wdata_o,
    output  logic[PHY_REG_WTH-1:0]          iq_issue_rdst_idx_o,
    output  logic                           iq_issue_rdst_is_fp_o,
    output  size_e                          iq_issue_size_o,
    output  amo_opcode_e                    iq_issue_amo_opcode_o,
    output  mem_opcode_e                    iq_issue_mem_opcode_o,
    output  logic[ROB_WTH-1:0]              iq_issue_rob_idx_o,
    output  logic                           iq_issue_sign_ext_o,
    // =====================================
    // [Read Reg and address translation]
    output  logic                           atrans_vld_o,
    input   logic                           atrans_rdy_i,
    output  logic[LSU_IQ_WTH-1:0]           atrans_iq_idx_o,
    output  logic[ROB_WTH-1:0]              atrans_rob_idx_o,
    output  logic[PHY_REG_WTH-1:0]          atrans_rs1_idx_o,
    output  logic[PHY_REG_WTH-1:0]          atrans_rs2_idx_o,
    output  logic                           atrans_rs2_is_fp_o,
    output  logic[DWTH-1:0]                 atrans_imm_o,
    output  mem_opcode_e                    atrans_mem_op_o, 
    output  size_e                          atrans_size_o,

    input   logic                           atrans_done_i,
    input   logic[LSU_IQ_WTH-1:0]           atrans_done_idx_i,
    input   logic[DWTH-1:0]                 atrans_wdata_i,
    input   logic[AWTH-1:0]                 atrans_paddr_i,
    // =====================================
    // [Awake]
    // alu
    input   logic                           alu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          alu_awake_idx_i,
    // csr
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
    typedef struct packed {
        logic                                 atrans_done;
    } lsu_state_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    lsu_packet_t [LSU_IQ_LEN-1:0]           lsu_iq_d,lsu_iq_q;
    logic[LSU_IQ_LEN-1:0][DWTH-1:0]         paddr_queen_d, paddr_queen_q; 
    logic[LSU_IQ_LEN-1:0][DWTH-1:0]         wdata_queen_d, wdata_queen_q; 
    logic[LSU_IQ_LEN-1:0]                   atrans_done_d, atrans_done_q; 
    logic[LSU_IQ_LEN-1:0]                   rs1_state_d,rs1_state_q;
    logic[LSU_IQ_LEN-1:0]                   rs2_state_d,rs2_state_q;
    logic[LSU_IQ_WTH-1:0]                   ins_idx_d, ins_idx_q;
    logic[LSU_IQ_WTH-1:0]                   del_idx_d, del_idx_q;
    logic[LSU_IQ_WTH-1:0]                   issue_idx_d, issue_idx_q;
    logic[LSU_IQ_WTH-1:0]                   atrans_idx_d,atrans_idx_q;//address translation index
    logic                                   atrans_flag_d,atrans_flag_q;
    logic                                   ins_flag_d, ins_flag_q;       
    logic                                   del_flag_d, del_flag_q;    
    logic                                   issue_flag_d, issue_flag_q;    
    logic                                   ins_en;               
    logic                                   del_en;   
    logic[LSU_IQ_WTH:0]                     cnt_d, cnt_q;        
    logic                                   iq_is_full;
    logic                                   iq_is_empty;
    logic                                   atrans_is_empty;
    logic                                   issue_sel_act;        
    logic[LSU_IQ_WTH-1:0]                   issue_sel_idx;        
    logic                                   atrans_sel_act;        
    logic                                   atrans_is_fence;
    logic[LSU_IQ_WTH-1:0]                   atrans_sel_idx;        
    logic                                   issue_is_empty;
//======================================================================================================================
// Issue Queue
//======================================================================================================================
    assign iq_is_full = {~del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign iq_is_empty= { del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign lsu_dis__rdy_o = ~iq_is_full;
    assign ins_en = dis_lsu__vld_i && lsu_dis__rdy_o;
    // insert new instr to issue queue
       always_comb begin : rs_state
        for (integer i=0; i<LSU_IQ_LEN; i=i+1) begin
            // awake
            if (i == ins_idx_q && ins_en) begin
                rs1_state_d[i] = dis_lsu__packet_i.rs1_state;
                rs2_state_d[i] = dis_lsu__packet_i.rs2_state;
            end else begin
                rs1_state_d[i] = rs1_state_q[i];
                rs2_state_d[i] = rs2_state_q[i];
                // rs1
                if (alu_awake_vld_i && alu_awake_idx_i == lsu_iq_q[i].phy_rs1_idx || 
                    csr_awake_vld_i && csr_awake_idx_i == lsu_iq_q[i].phy_rs1_idx || 
                    lsu_awake_vld_i && lsu_awake_idx_i == lsu_iq_q[i].phy_rs1_idx && !lsu_awake_is_fp_i || 
                    mdu_awake_vld_i && mdu_awake_idx_i == lsu_iq_q[i].phy_rs1_idx || 
                    fpu_awake_vld_i && fpu_awake_idx_i == lsu_iq_q[i].phy_rs1_idx && !fpu_awake_is_fp_i
                   ) begin
                    rs1_state_d[i] = 1'b1;        
                end
                // rs2 is float point reg
                if (lsu_iq_q[i].rs2_is_fp) begin
                    if (lsu_awake_vld_i && lsu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx && lsu_awake_is_fp_i || 
                        fpu_awake_vld_i && fpu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx && fpu_awake_is_fp_i
                    ) begin
                        rs2_state_d[i] = 1'b1;        
                    end
                end else begin
                    if (alu_awake_vld_i && alu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx || 
                        csr_awake_vld_i && csr_awake_idx_i == lsu_iq_q[i].phy_rs2_idx || 
                        lsu_awake_vld_i && lsu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx && !lsu_awake_is_fp_i || 
                        mdu_awake_vld_i && mdu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx || 
                        fpu_awake_vld_i && fpu_awake_idx_i == lsu_iq_q[i].phy_rs2_idx && !fpu_awake_is_fp_i
                    ) begin
                        rs2_state_d[i] = 1'b1;        
                    end
                end
            end
        end 
    end 

    // state of instr
    always_comb begin : iq_gen
        for (integer i=LSU_IQ_LEN-1; i>=0; i=i-1) begin
            lsu_iq_d[i] = lsu_iq_q[i];
            // lsu_state_d[i] = lsu_state_q[i];
            atrans_done_d[i] = atrans_done_q[i];
            if (i == ins_idx_q && ins_en) begin
                lsu_iq_d[i] = dis_lsu__packet_i; // insert new instr
                atrans_done_d[i] = dis_lsu__packet_i.lsu_cmd.is_fence;
            end else if (atrans_done_i && atrans_done_idx_i == i) begin
                atrans_done_d[i] = 1'b1;
            end 
        end
    end

    always_comb begin : ins_idx
        {ins_flag_d,ins_idx_d} = {ins_flag_q,ins_idx_q};
        {del_flag_d,del_idx_d} = {del_flag_q,del_idx_q};
        if (flush_i) begin
            {ins_flag_d,ins_idx_d} = '0;
            {del_flag_d,del_idx_d} = '0;
        end else if (del_en && ins_en) begin  // don't change
            {ins_flag_d,ins_idx_d} = {ins_flag_q,ins_idx_q} + 1;
            {del_flag_d,del_idx_d} = {del_flag_q,del_idx_q} + 1;
        end else if (del_en) begin     // -1
            {del_flag_d,del_idx_d} = {del_flag_q,del_idx_q} + 1;
        end else if (ins_en) begin
            {ins_flag_d,ins_idx_d} = {ins_flag_q,ins_idx_q} + 1;
        end 
    end

//======================================================================================================================
// Select an instr to translate address
//======================================================================================================================
    assign atrans_is_empty = {atrans_flag_q,atrans_idx_q} == {ins_flag_q,ins_idx_q};
    always_comb begin : address_trans_idx
        {atrans_flag_d,atrans_idx_d} = {atrans_flag_q,atrans_idx_q};
        if (flush_i) begin
            {atrans_flag_d,atrans_idx_d} = '0;
        end else if (atrans_vld_o && atrans_rdy_i || atrans_is_fence) begin  // don't change
            {atrans_flag_d,atrans_idx_d} = {atrans_flag_q,atrans_idx_q} + 1;
        end
    end

    always_comb begin
        atrans_sel_act = 1'b0;
        atrans_is_fence  = 1'b0;
        if (!atrans_is_empty && rs1_state_q[atrans_idx_q] && rs2_state_q[atrans_idx_q]) begin
            atrans_sel_act = 1'b1;
            atrans_is_fence = lsu_iq_q[atrans_idx_q].lsu_cmd.is_fence;    
        end
    end
    assign atrans_vld_o         = atrans_sel_act && !flush_i && !atrans_is_fence;
    assign atrans_iq_idx_o      = atrans_idx_q;
    assign atrans_rob_idx_o     = lsu_iq_q[atrans_idx_q].rob_idx;
    assign atrans_rs1_idx_o     = lsu_iq_q[atrans_idx_q].phy_rs1_idx;
    assign atrans_rs2_idx_o     = lsu_iq_q[atrans_idx_q].phy_rs2_idx;
    assign atrans_rs2_is_fp_o   = lsu_iq_q[atrans_idx_q].rs2_is_fp;
    assign atrans_imm_o         = lsu_iq_q[atrans_idx_q].lsu_cmd.imm;
    assign atrans_mem_op_o      = lsu_iq_q[atrans_idx_q].lsu_cmd.mem_op;
    assign atrans_size_o        = lsu_iq_q[atrans_idx_q].lsu_cmd.size;

    // write back write data and physical address
    always_comb begin : wdata_and_paddr
        wdata_queen_d = wdata_queen_q;   
        paddr_queen_d = paddr_queen_q;
        for (integer i=0; i<LSU_IQ_LEN; i=i+1) begin
            if (atrans_done_i && atrans_done_idx_i == i) begin
                wdata_queen_d[i] = atrans_wdata_i;
                paddr_queen_d[i] = atrans_paddr_i;
            end
        end
    end
//======================================================================================================================
// Select an instr to access d cache
//======================================================================================================================
    // select an instr to issue
    assign issue_is_empty = {atrans_flag_q,atrans_idx_q} == {del_flag_q,del_idx_q};
    always_comb begin
        issue_sel_act = 1'b0;
        if (!issue_is_empty && atrans_done_q[del_idx_q]) begin
            issue_sel_act = 1'b1;
        end
    end
    assign iq_issue_vld_o        = issue_sel_act && !flush_i;
    assign del_en = iq_issue_vld_o && iq_issue_rdy_i;   

    assign iq_issue_paddr_o      = paddr_queen_q[del_idx_q];       
    assign iq_issue_wdata_o      = wdata_queen_q[del_idx_q];      
    assign iq_issue_rdst_idx_o   = lsu_iq_q[del_idx_q].phy_rdst_idx;         
    assign iq_issue_rdst_is_fp_o = lsu_iq_q[del_idx_q].rdst_is_fp;           
    assign iq_issue_size_o       = lsu_iq_q[del_idx_q].lsu_cmd.size;     
    assign iq_issue_amo_opcode_o = lsu_iq_q[del_idx_q].lsu_cmd.amo_op;           
    assign iq_issue_mem_opcode_o = lsu_iq_q[del_idx_q].lsu_cmd.mem_op;           
    assign iq_issue_rob_idx_o    = lsu_iq_q[del_idx_q].rob_idx;        
    assign iq_issue_sign_ext_o   = lsu_iq_q[del_idx_q].lsu_cmd.sign_ext;         
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<LSU_IQ_LEN; i=i+1) begin
                lsu_iq_q[i]         <= lsu_packet_t'(0);
                paddr_queen_q[i]    <= '0;
                wdata_queen_q[i]    <= '0;
                atrans_done_q[i]    <= 1'b0;
                rs1_state_q[i]      <= 1'b0;
                rs2_state_q[i]      <= 1'b0;
            end
            {ins_flag_q,ins_idx_q}       <= '0;
            {del_flag_q,del_idx_q}       <= '0;
            {atrans_flag_q,atrans_idx_q} <= '0;
        end else begin
            for (integer i=0; i<LSU_IQ_LEN; i=i+1) begin
                lsu_iq_q[i]         <= lsu_iq_d[i];
                paddr_queen_q[i]    <= paddr_queen_d[i];
                wdata_queen_q[i]    <= wdata_queen_d[i];
                atrans_done_q[i]    <= atrans_done_d[i];
                rs1_state_q[i]      <= rs1_state_d[i]  ;
                rs2_state_q[i]      <= rs2_state_d[i]  ;
            end
            {ins_flag_q,ins_idx_q}       <= {ins_flag_d,ins_idx_d}      ;
            {del_flag_q,del_idx_q}       <= {del_flag_d,del_idx_d}      ;
            {atrans_flag_q,atrans_idx_q} <= {atrans_flag_d,atrans_idx_d};
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_lsu_iq
