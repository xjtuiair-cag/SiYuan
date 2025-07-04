// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_csr_iq.v
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

module sy_ppl_csr_iq
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
    input   logic                           dis_csr__vld_i,          
    output  logic                           csr_dis__rdy_o,          
    input   csr_packet_t                    dis_csr__packet_i,
    // =====================================
    // [Issue]
    output  logic                           issue_vld_o,
    output  logic[CSR_IQ_WTH-1:0]           issue_idx_o,
    input   logic                           issue_rdy_i,
    output  csr_packet_t                    issue_packet_o,
    // =====================================
    // [Write data]
    input   logic                           csr_wr_en_i,
    input   logic[CSR_IQ_WTH-1:0]           csr_wr_idx_i,
    input   logic[DWTH-1:0]                 csr_wdata_i,
    // =====================================
    // [Write to CSR regfile]
    output  csr_bus_wr_t                    csr_regfile_wr_o,
    // =====================================
    // [From ROB]
    input   logic                           rob_csr__retire_i,
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
    typedef struct packed {
        logic[CSR_IQ_WTH-1:0]               idx;
        logic                               en; 
    } raw_t; // read after write dependency
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    csr_packet_t [CSR_IQ_LEN-1:0]           csr_iq_d,csr_iq_q;
    logic[CSR_IQ_LEN-1:0][DWTH-1:0]         csr_wdata_d,csr_wdata_q;
    raw_t[CSR_IQ_LEN-1:0]                   raw_depdcy_d, raw_depdcy_q;     
    logic[CSR_IQ_LEN-1:0]                   rs1_state_d,rs1_state_q;
    logic[CSR_IQ_WTH-1:0]                   ins_idx_d, ins_idx_q;
    logic[CSR_IQ_WTH-1:0]                   issue_idx_d, issue_idx_q;
    logic[CSR_IQ_WTH-1:0]                   del_idx_d, del_idx_q;
    logic                                   ins_flag_d, ins_flag_q;             
    logic                                   issue_flag_d, issue_flag_q;   
    logic                                   del_flag_d, del_flag_q;             
    logic                                   ins_en;               
    logic                                   del_en;   
    logic                                   iq_is_full;
    logic                                   iq_is_empty;
    logic                                   issue_empty;        
    logic                                   sel_act;        
    logic[CSR_IQ_WTH-1:0]                   sel_idx;        
    logic                                   raw_exist; // read after write dependency  
    logic[CSR_IQ_WTH-1:0]                   raw_iq_idx;   
    logic                                   release_raw; // read after write dependency  
    logic[CSR_IQ_WTH-1:0]                   release_raw_idx;   
//======================================================================================================================
// Issue Queue
//======================================================================================================================
    // assign iq_is_full = (cnt_q == CSR_IQ_LEN);
    assign iq_is_full = {~del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign iq_is_empty= { del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign issue_empty= { issue_flag_q,issue_idx_q} == {ins_flag_q,ins_idx_q}; // there is no instr will be issue
    assign csr_dis__rdy_o = ~iq_is_full;
    assign ins_en = dis_csr__vld_i && csr_dis__rdy_o;
    // insert new instr to issue queue
    always_comb begin : rs_state
        for (integer i=0; i<CSR_IQ_LEN; i=i+1) begin
            // awake
            if (i == ins_idx_q && ins_en) begin
                rs1_state_d[i] = dis_csr__packet_i.rs1_state;
           end else begin
                rs1_state_d[i] = rs1_state_q[i];
                if (alu_awake_vld_i && alu_awake_idx_i == csr_iq_q[i].phy_rs1_idx || 
                    csr_awake_vld_i && csr_awake_idx_i == csr_iq_q[i].phy_rs1_idx || 
                    lsu_awake_vld_i && lsu_awake_idx_i == csr_iq_q[i].phy_rs1_idx && !lsu_awake_is_fp_i || 
                    mdu_awake_vld_i && mdu_awake_idx_i == csr_iq_q[i].phy_rs1_idx || 
                    fpu_awake_vld_i && fpu_awake_idx_i == csr_iq_q[i].phy_rs1_idx && !fpu_awake_is_fp_i
                   ) begin
                    rs1_state_d[i] = 1'b1;        
                end
           end
        end 
    end 
    // look up Issue Queue to check RAW dependency
    always_comb begin : dependency_check
        raw_exist = 1'b0;
        raw_iq_idx = '0;
        for (integer i=0; i<(CSR_IQ_LEN*2); i=i+1) begin
            if (i >= {1'b0, del_idx_q} && i < {del_flag_q ^ ins_flag_q, ins_idx_q} 
            &&  dis_csr__packet_i.csr_cmd.csr_addr == csr_iq_q[i[CSR_IQ_WTH-1:0]].csr_cmd.csr_addr
            &&  dis_csr__packet_i.csr_cmd.csr_rd_en &&  csr_iq_q[i[CSR_IQ_WTH-1:0]].csr_cmd.csr_wr_en 
            &&  !(release_raw && release_raw_idx == i[CSR_IQ_WTH-1:0]))  begin
                raw_exist = 1'b1;
                raw_iq_idx = i[CSR_IQ_WTH-1:0];
            end
        end
    end
    always_comb begin : raw_dpendency
        for (integer i=0; i<CSR_IQ_LEN; i=i+1) begin
            raw_depdcy_d[i] = raw_depdcy_q[i];
            if (ins_en && i == ins_idx_q) begin
                raw_depdcy_d[i].en = raw_exist;
                raw_depdcy_d[i].idx = raw_iq_idx;
            end else if (release_raw && raw_depdcy_q[i].idx == release_raw_idx) begin
                raw_depdcy_d[i].en = 1'b0;               
            end
        end
    end

    always_comb begin : iq_gen
        for (integer i=CSR_IQ_LEN-1; i>=0; i=i-1) begin
            csr_iq_d[i] = csr_iq_q[i];
            if (i == ins_idx_q && ins_en) begin
                csr_iq_d[i] = dis_csr__packet_i; // insert new instr
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

    always_comb begin : issue_idx
        {issue_flag_d,issue_idx_d} = {issue_flag_q,issue_idx_q};
        if (flush_i) begin
            {issue_flag_d,issue_idx_d} = '0;
        end else if (issue_vld_o && issue_rdy_i) begin  // don't change
            {issue_flag_d,issue_idx_d} = {issue_flag_q,issue_idx_q} + 1;
        end
    end

//======================================================================================================================
// Select an instr
//======================================================================================================================
    // select an instr to issue
    always_comb begin
        sel_act = 1'b0;
        if (!issue_empty && rs1_state_q[issue_idx_q] && !raw_depdcy_q[issue_idx_q].en) begin
            sel_act = 1'b1;
        end
    end
    assign issue_vld_o    = sel_act && !flush_i;
    assign issue_packet_o = csr_iq_q[issue_idx_q];
    assign issue_idx_o    = issue_idx_q;
//======================================================================================================================
// write to CSR Regfile
//======================================================================================================================
    always_comb begin : wdata
        for (integer i=0; i<CSR_IQ_LEN; i=i+1) begin
            csr_wdata_d[i] = csr_wdata_q[i];
            if (csr_wr_en_i && csr_wr_idx_i == i) begin
                csr_wdata_d[i] = csr_wdata_i;
            end
        end
    end
    assign del_en = rob_csr__retire_i;  // retire from rob

    assign csr_regfile_wr_o.wr_en = del_en && csr_iq_q[del_idx_q].csr_cmd.csr_wr_en;
    assign csr_regfile_wr_o.waddr = csr_iq_q[del_idx_q].csr_cmd.csr_addr;
    assign csr_regfile_wr_o.wdata = csr_wdata_q[del_idx_q];

    assign release_raw = csr_regfile_wr_o.wr_en;
    assign release_raw_idx = del_idx_q;
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<CSR_IQ_LEN; i=i+1) begin
                csr_iq_q[i]     <= csr_packet_t'(0);
                csr_wdata_q[i]  <= '0;
                rs1_state_q[i]  <= 1'b0;
                raw_depdcy_q[i] <= raw_t'(0);
            end
            {ins_flag_q,ins_idx_q}      <= '0;
            {del_flag_q,del_idx_q}      <= '0;
            {issue_flag_q,issue_idx_q}  <= '0;
        end else begin
            for (integer i=0; i<CSR_IQ_LEN; i=i+1) begin
                csr_iq_q[i]     <= csr_iq_d[i];
                csr_wdata_q[i]  <= csr_wdata_d[i];
                rs1_state_q[i]  <= rs1_state_d[i];
                raw_depdcy_q[i] <= raw_depdcy_d[i];
            end
            {ins_flag_q,ins_idx_q}      <= {ins_flag_d,ins_idx_d}     ;
            {del_flag_q,del_idx_q}      <= {del_flag_d,del_idx_d}     ;
            {issue_flag_q,issue_idx_q}  <= {issue_flag_d,issue_idx_d} ;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_csr_iq
