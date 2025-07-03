// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu_ctrl.sv
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

module sy_ppl_lsu_ctrl
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush_i]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From Issue Queen]
    input   logic                           iq_issue_vld_i,
    output  logic                           iq_issue_rdy_o,
    input   logic[AWTH-1:0]                 iq_issue_paddr_i,
    input   logic[DWTH-1:0]                 iq_issue_wdata_i,
    input   logic[PHY_REG_WTH-1:0]          iq_issue_rdst_idx_i,
    input   logic                           iq_issue_rdst_is_fp_i,
    input   size_e                          iq_issue_size_i,
    input   amo_opcode_e                    iq_issue_amo_opcode_i,
    input   mem_opcode_e                    iq_issue_mem_opcode_i,
    input   logic[ROB_WTH-1:0]              iq_issue_rob_idx_i,
    input   logic                           iq_issue_sign_ext_i,
    // =====================================
    // [To D cache]
    output  logic                           lsu_dcache__vld_o,
    input   logic                           dcache_lsu__rdy_i,
    output  dcache_req_t                    lsu_dcache__req_o,    
    input   dcache_rsp_t                    dcache_lsu__rsp_i,  
    // =====================================
    // [Write Back to GPR Reg]
    output  logic                           gpr_wr_we_o,
    output  logic[PHY_REG_WTH-1:0]          gpr_wr_idx_o,
    output  logic[DWTH-1:0]                 gpr_wr_data_o,
    // =====================================
    // [Write Back to FPR Reg]
    output  logic                           fpr_wr_we_o,
    output  logic[PHY_REG_WTH-1:0]          fpr_wr_idx_o,
    output  logic[DWTH-1:0]                 fpr_wr_data_o,
    // =====================================
    // [Awake TO FPU/IMU]
    output  logic                           lsu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          lsu_awake_idx_o,
    output  logic                           lsu_awake_is_fp_o,    
    // =====================================
    // [Commit to ROB] 
    output  logic                           lsu_rob__commit_vld_o,
    output  logic[ROB_WTH-1:0]              lsu_rob__commit_idx_o,
    input   logic                           rob_lsu__retire_en_i,
    output  logic                           lsu_ctrl__sq_retire_empty_o 
);

//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   st1_stall;
    logic                                   st1_act_unkilled;
    logic                                   st1_act;
    logic                                   st1_avail;
    logic                                   st1_accpt;
    logic                                   st2_act;  
    logic[AWTH-1:0]                         st1_paddr;
    logic[DWTH-1:0]                         st1_wdata;
    logic[PHY_REG_WTH-1:0]                  st1_rdst_idx;
    logic                                   st1_rdst_is_fp;
    size_e                                  st1_size;
    amo_opcode_e                            st1_amo_opcode;
    mem_opcode_e                            st1_mem_opcode;
    logic[ROB_WTH-1:0]                      st1_rob_idx;
    logic                                   st1_sign_ext;
    logic[2:0]                              offset;
    logic                                   sbuf_vld;        
    logic                                   sbuf_rdy;
    logic[AWTH-1:0]                         sbuf_paddr;
    logic[DWTH-1:0]                         sbuf_wdata;
    logic[7:0]                              sbuf_wstrb;
    logic[DWTH-1:0]                         wr_data;        
    logic[7:0]                              st1_be;
    logic                                   lookup_vld;
    logic[31:0]                             lookup_paddr;
    logic                                   lookup_flag;
    logic[SBUF_WTH-1:0]                     lookup_idx;
    logic[7:0]                              lookup_be;
    logic[DWTH-1:0]                         lookup_data;
    logic                                   lookup_stall;         
    logic                                   sbuf_dcache_we_vld;
    logic                                   sbuf_dcache_we_rdy;                   
    logic[31:0]                             sbuf_dcache_addr;
    logic[DWTH-1:0]                         sbuf_dcache_wdata;
    logic[7:0]                              sbuf_dcache_be;
    logic                                   sbuf_dcache_cacheable;
    logic[DCACHE_WAY_NUM-1:0]               sbuf_dcache_way_en;        
    amo_opcode_e                            sbuf_dcache_amo_op;
    logic                                   sbuf_ins_flag;
    logic[SBUF_WTH-1:0]                     sbuf_ins_idx;
    logic[SBUF_WTH-1:0]                     sbuf_del_idx;
    logic                                   sbuf_empty;
    logic                                   dcache_sbuf_vld;        
    logic[DCACHE_WAY_NUM-1:0]               dcache_sbuf_way;
    logic[SBUF_WTH-1:0]                     dcache_sbuf_idx;
    amo_opcode_e                            dcache_sbuf_amo;
    logic[DWTH-1:0]                         dcache_sbuf_rdata;

    logic[DWTH-1:0]                         rdata,rdata_sr;
    logic[2:0]                              wb_offset;
    size_e                                  wb_size; 
    logic                                   wb_sign_ext;  
    logic[DWTH-1:0]                         wb_dmem_rdata;
    logic                                   wb_rdst_is_fp;        
    logic                                   stall;
    logic                                   cacheable;
    logic                                   need_wr_sbuf;
    logic                                   non_cacheable_commit;    
    logic                                   fence_commit;    
    logic                                   fence_stall;                         
    logic                                   lr_stall;                         
    logic                                   sc_stall;                         
    logic                                   amo_stall;                         
    logic                                   non_cache_stall;
    logic                                   commit_ahead; 
    logic                                   dcache_idle;
    logic                                   is_store;
    logic                                   is_load;
    logic                                   is_amo;
    logic                                   is_fence;    
    logic                                   is_lr;                  
    logic                                   is_sc;                  
    logic                                   lr_lock;
    logic                                   sc_lock;
    logic                                   amo_lock;
    logic                                   non_cache_lock;                 
    logic                                   unlock_non_cache;
    logic[63:0]                             delay_chain;    

    logic                                   in_dram; 
    logic                                   in_plic; 
    logic                                   in_clint; 
    logic                                   in_rom; 
    logic                                   in_uart;         
    logic                                   in_gpio;
    logic                                   in_spi;     
    logic                                   in_dma;
    logic                                   addr_is_legal; 
    logic                                   sbuf_specu_slot_full;
    assign in_dram   = (st1_paddr >= sy_soc_pkg::DRAM_START)  && (st1_paddr  < sy_soc_pkg::DRAM_END);
    assign in_plic   = (st1_paddr >= sy_soc_pkg::PLIC_START)  && (st1_paddr  < sy_soc_pkg::PLIC_END);
    assign in_clint  = (st1_paddr >= sy_soc_pkg::CLINT_START) && (st1_paddr  < sy_soc_pkg::CLINT_END);
    assign in_rom    = (st1_paddr >= sy_soc_pkg::ROM_START)   && (st1_paddr  < sy_soc_pkg::ROM_END);
    assign in_uart   = (st1_paddr >= sy_soc_pkg::UART_START)  && (st1_paddr  < sy_soc_pkg::UART_END);
    assign in_gpio   = (st1_paddr >= sy_soc_pkg::GPIO_START)  && (st1_paddr  < sy_soc_pkg::GPIO_END);
    assign in_spi    = (st1_paddr >= sy_soc_pkg::SPI_START)   && (st1_paddr  < sy_soc_pkg::SPI_END);
    assign in_dma    = (st1_paddr >= sy_soc_pkg::DMA_START)   && (st1_paddr  < sy_soc_pkg::DMA_END);

    assign addr_is_legal = in_dram || in_plic || in_clint || in_rom || in_uart || in_gpio || in_spi || in_dma;
//======================================================================================================================
// Stage 1 : send index to D cache
//======================================================================================================================
    assign st1_stall = stall; 
    assign st1_kill  = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            st1_act_unkilled <= `TCQ 1'b0;
        end else begin
            st1_act_unkilled <= `TCQ st1_accpt ? iq_issue_vld_i : st1_act;
        end
    end

    assign st1_act   = st1_act_unkilled && !st1_kill;
    assign st1_avail = st1_act && !st1_stall;
    assign st1_accpt = !st1_act || st1_avail;
    assign iq_issue_rdy_o = st1_accpt;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            st1_paddr         <= `TCQ '0;    
            st1_wdata         <= `TCQ '0;    
            st1_rdst_idx      <= `TCQ '0;       
            st1_rdst_is_fp    <= `TCQ '0;         
            st1_size          <= `TCQ size_e'(0);   
            st1_amo_opcode    <= `TCQ amo_opcode_e'(0);         
            st1_mem_opcode    <= `TCQ mem_opcode_e'(0);         
            st1_rob_idx       <= `TCQ '0;      
            st1_sign_ext      <= `TCQ '0;       
        end else begin
            if (st1_accpt) begin
                st1_paddr         <= `TCQ iq_issue_paddr_i     ;    
                st1_wdata         <= `TCQ iq_issue_wdata_i     ;    
                st1_rdst_idx      <= `TCQ iq_issue_rdst_idx_i  ;       
                st1_rdst_is_fp    <= `TCQ iq_issue_rdst_is_fp_i;         
                st1_size          <= `TCQ iq_issue_size_i      ;   
                st1_amo_opcode    <= `TCQ iq_issue_amo_opcode_i;         
                st1_mem_opcode    <= `TCQ iq_issue_mem_opcode_i;         
                st1_rob_idx       <= `TCQ iq_issue_rob_idx_i   ;      
                st1_sign_ext      <= `TCQ iq_issue_sign_ext_i  ;       
            end
        end
    end
    
    // always_ff @(`DFF_CR(clk_i, rst_i)) begin 
    //     if (`DFF_IS_R(rst_i)) begin
    //         delay_chain <= '0;
    //     end else begin
    //         if (flush_i) begin
    //             delay_chain <= '0;
    //         end else begin
    //             delay_chain <= {delay_chain[62:0],dcache_lsu__rsp_i.valid && !dcache_lsu__rsp_i.cacheable};
    //         end
    //     end
    // end
    // assign unlock_non_cache = delay_chain[63];
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            // lr_lock <= '0;
            // sc_lock <= '0;
            amo_lock <= '0;
            non_cache_lock <= '0;
        end else begin
            if (flush_i) begin
                // lr_lock <= '0;
                // sc_lock <= '0;
                amo_lock <= '0;
                non_cache_lock <= '0;
            end else if (st1_avail) begin
                // lr_lock <= is_lr;
                // sc_lock <= is_sc;
                amo_lock        <= is_amo;
                non_cache_lock  <= !cacheable && !is_fence;
            end else if (dcache_lsu__rsp_i.valid) begin
                if (dcache_lsu__rsp_i.is_amo ) begin
                    amo_lock <= '0;
                end 
                if (!dcache_lsu__rsp_i.cacheable) begin
                    non_cache_lock <= '0;
                end
            end
            // if (unlock_non_cache) begin
            //     non_cache_lock <= '0;
            // end
        end
    end

    assign is_store  = (st1_mem_opcode == MEM_OP_STORE || st1_mem_opcode == MEM_OP_ST_FP); 
    assign is_load   = (st1_mem_opcode == MEM_OP_LOAD  || st1_mem_opcode == MEM_OP_LD_FP);
    assign is_amo    = (st1_mem_opcode == MEM_OP_AMO   || st1_mem_opcode == MEM_OP_LR || st1_mem_opcode == MEM_OP_SC);
    assign is_fence  = (st1_mem_opcode == MEM_OP_FENCE);
    assign is_lr     = (st1_mem_opcode == MEM_OP_LR); 
    assign is_sc     = (st1_mem_opcode == MEM_OP_SC); 
    assign need_wr_sbuf = is_store || (is_amo && st1_mem_opcode != MEM_OP_LR);

    assign cacheable = is_cacheable({st1_paddr[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB], {DCACHE_TAG_LSB{1'b0}}});
    assign non_cacheable_commit = st1_avail && is_store && !cacheable;
    assign fence_commit = st1_avail && is_fence;
    // if this is fence , stall untill mshr is empty and store buffer is empty 
    assign dcache_idle = dcache_lsu__rsp_i.mshr_empty && dcache_lsu__rsp_i.st1_idle;
    assign fence_stall = is_fence && (!sbuf_empty || !dcache_idle); // TODO 
    // assign lr_stall    = is_lr    && (!sbuf_empty || !dcache_idle); // TODO 
    // assign sc_stall    = is_sc    && (!sbuf_empty || !dcache_idle); // TODO 
    assign amo_stall   = is_amo   && (!sbuf_empty || !dcache_idle); // TODO 
    assign non_cache_stall = !cacheable && !is_fence && (!sbuf_empty || !dcache_idle);
    always_comb begin : stall_condition
        stall = 1'b0;
        // Store Buffer need to write data to D cache
        if (sbuf_dcache_we_vld) begin
            stall = 1'b1;
        // D cache refuse request
        end else if (lsu_dcache__vld_o && !dcache_lsu__rdy_i) begin
            stall = 1'b1;
        // store instr which access non-cacheable memory will not be sent to D cache until it retire
        // it will commit to ROB directly, so we need to check if D cache occupy commit bus
        end else if (is_store && !cacheable && dcache_lsu__rsp_i.valid) begin
            stall = 1'b1;
        end else if (lookup_stall) begin
            stall = 1'b1;
        end
        // Store Buffer has not enough space
        if (need_wr_sbuf && !sbuf_rdy) begin
            stall = 1'b1;
        end
        if (need_wr_sbuf && sbuf_specu_slot_full) begin
            stall = 1'b1;
        end
        if (!addr_is_legal && !is_fence) begin
            stall = 1'b1;
        end
        if (fence_stall || amo_stall || non_cache_stall) begin
            stall = 1'b1;
        end
        if (amo_lock || non_cache_lock) begin
            stall = 1'b1;
        end
    end
    always_comb begin : dcache_req
        lsu_dcache__vld_o = 1'b0;
        // Store Buffer need to write data to D cache
        if (sbuf_dcache_we_vld) begin
            lsu_dcache__vld_o = 1'b1;
        // Stage 1 has active request
        end else if (st1_act) begin
            lsu_dcache__vld_o = 1'b1;
            // without enough space in Store Buffer
            if (need_wr_sbuf && !sbuf_rdy) begin
                lsu_dcache__vld_o = 1'b0;
            end else if (need_wr_sbuf && sbuf_specu_slot_full) begin
                lsu_dcache__vld_o = 1'b0;
            // instruction that access non-cacheable memory
            end else if (is_store && !cacheable) begin 
                lsu_dcache__vld_o = 1'b0;
            end else if (lookup_stall) begin
                lsu_dcache__vld_o = 1'b0;
            end else if (!addr_is_legal) begin
                lsu_dcache__vld_o = 1'b0;
            end else if (is_fence) begin
                lsu_dcache__vld_o = 1'b0;
            end else if (amo_stall || amo_lock || non_cache_stall || non_cache_lock) begin
                lsu_dcache__vld_o = 1'b0;
            end
        end
    end

    assign offset   = st1_paddr[2:0]; 
    assign wr_data  = st1_wdata << (8*offset);
    assign st1_be   = (st1_size == SIZE_BYTE) ? (8'h1 << offset) : 
                      (st1_size == SIZE_HALF) ? (8'h3 << offset) : 
                      (st1_size == SIZE_WORD) ? (8'hF << offset) : 8'hFF;

    assign lsu_dcache__req_o.paddr         = sbuf_dcache_we_vld ? sbuf_dcache_addr : st1_paddr;
    assign lsu_dcache__req_o.cacheable     = sbuf_dcache_we_vld ? sbuf_dcache_cacheable : cacheable;

    assign lsu_dcache__req_o.size          = st1_size;
    assign lsu_dcache__req_o.is_store      = sbuf_dcache_we_vld ? 1'b1 : is_store;  
    assign lsu_dcache__req_o.is_load       = sbuf_dcache_we_vld ? 1'b0 : is_load;  
    assign lsu_dcache__req_o.is_amo        = sbuf_dcache_we_vld ? 1'b0 : is_amo;
    assign lsu_dcache__req_o.rob_idx       = st1_rob_idx;
    assign lsu_dcache__req_o.rdst_idx      = st1_rdst_idx;
    assign lsu_dcache__req_o.rdst_is_fp    = st1_rdst_is_fp;
    assign lsu_dcache__req_o.amo_op        = sbuf_dcache_we_vld ? sbuf_dcache_amo_op : st1_amo_opcode;
    assign lsu_dcache__req_o.sbuf_idx      = sbuf_dcache_we_vld ? sbuf_del_idx : sbuf_ins_idx;
    assign lsu_dcache__req_o.sign_ext      = st1_sign_ext;

    assign lsu_dcache__req_o.data          = sbuf_dcache_we_vld ? sbuf_dcache_wdata : lookup_data;
    assign lsu_dcache__req_o.be            = sbuf_dcache_we_vld ? sbuf_dcache_be : st1_be;
    assign lsu_dcache__req_o.lookup_be     = lookup_be;
    assign lsu_dcache__req_o.we            = sbuf_dcache_we_vld;
    assign lsu_dcache__req_o.way_en        = sbuf_dcache_we_vld ? sbuf_dcache_way_en : {DCACHE_WAY_NUM{1'b1}};
//======================================================================================================================
// commit to ROB and write back to register file
//======================================================================================================================
    assign wb_offset     = dcache_lsu__rsp_i.offset;
    assign wb_size       = dcache_lsu__rsp_i.size;
    assign wb_sign_ext   = dcache_lsu__rsp_i.sign_ext;
    assign wb_rdst_is_fp = dcache_lsu__rsp_i.rdst_is_fp;
    always_comb begin
        rdata_sr = dcache_lsu__rsp_i.rdata >> (8*wb_offset);
        case(wb_size)
            SIZE_BYTE: begin wb_dmem_rdata = {wb_sign_ext ? {56{rdata_sr[7]}}  : 56'h0, rdata_sr[7:0]}; end
            SIZE_HALF: begin wb_dmem_rdata = {wb_sign_ext ? {48{rdata_sr[15]}} : 48'h0, rdata_sr[15:0]}; end
            SIZE_WORD: begin wb_dmem_rdata = {wb_sign_ext ? (wb_rdst_is_fp ? {32{1'b1}} : {32{rdata_sr[31]}}) : 32'h0, rdata_sr[31:0]}; end
            default:   begin wb_dmem_rdata = dcache_lsu__rsp_i.rdata; end
        endcase
    end    

    always_ff @(posedge clk_i) begin
        // commit to ROB 
        lsu_rob__commit_vld_o <= non_cacheable_commit || fence_commit || dcache_lsu__rsp_i.valid && !(!dcache_lsu__rsp_i.cacheable && dcache_lsu__rsp_i.is_store); // TODO
        lsu_rob__commit_idx_o <= (non_cacheable_commit || fence_commit)? st1_rob_idx : dcache_lsu__rsp_i.rob_idx;
        // write back to register file
        gpr_wr_we_o     <= dcache_lsu__rsp_i.valid && (dcache_lsu__rsp_i.is_load || dcache_lsu__rsp_i.is_amo) && !dcache_lsu__rsp_i.rdst_is_fp;
        gpr_wr_idx_o    <= dcache_lsu__rsp_i.rdst_idx;
        gpr_wr_data_o   <= wb_dmem_rdata;
        fpr_wr_we_o     <= dcache_lsu__rsp_i.valid && (dcache_lsu__rsp_i.is_load || dcache_lsu__rsp_i.is_amo) &&  dcache_lsu__rsp_i.rdst_is_fp;
        fpr_wr_idx_o    <= dcache_lsu__rsp_i.rdst_idx;
        fpr_wr_data_o   <= wb_dmem_rdata;
    end
    assign lsu_awake_vld_o = gpr_wr_we_o || fpr_wr_we_o;
    assign lsu_awake_idx_o = gpr_wr_idx_o;
    assign lsu_awake_is_fp_o = gpr_wr_we_o ? 1'b0 : 1'b1;
//======================================================================================================================
// Store Buffer
//======================================================================================================================
    assign sbuf_vld     = st1_avail && need_wr_sbuf;        
    assign sbuf_paddr   = st1_paddr;
    assign sbuf_wdata   = wr_data;
    assign sbuf_wstrb   = st1_be;

    assign lookup_paddr = st1_paddr; 

    assign dcache_sbuf_vld   = dcache_lsu__rsp_i.valid && (dcache_lsu__rsp_i.is_store || dcache_lsu__rsp_i.is_amo && dcache_lsu__rsp_i.amo_op != AMO_LR); 
    assign dcache_sbuf_way   = dcache_lsu__rsp_i.way_en; 
    assign dcache_sbuf_idx   = dcache_lsu__rsp_i.sbuf_idx; 
    assign dcache_sbuf_amo   = dcache_lsu__rsp_i.amo_op; 
    assign dcache_sbuf_rdata = dcache_lsu__rsp_i.rdata; 

    assign sbuf_dcache_we_rdy = dcache_lsu__rdy_i;
    sy_ppl_lsu_sbuf store_buffer_inst(
        .clk_i                      (clk_i),                     
        .rst_i                      (rst_i),                     
        .flush_i                    (flush_i), 

        .sbuf_ins_idx_o             (sbuf_ins_idx  ),
        .sbuf_del_idx_o             (sbuf_del_idx  ),
        .sbuf_empty_o               (sbuf_empty),
        .sbuf_retire_empty_o        (lsu_ctrl__sq_retire_empty_o),
        .sbuf_specu_slot_full_o     (sbuf_specu_slot_full),

        .sbuf_vld_i                 (sbuf_vld   ),            
        .sbuf_rdy_o                 (sbuf_rdy   ),    
        .sbuf_paddr_i               (sbuf_paddr ),      
        .sbuf_wdata_i               (sbuf_wdata ),      
        .sbuf_wstrb_i               (sbuf_wstrb ),      
        .sbuf_size_i                (st1_size   ),
        .sbuf_cacheable_i           (cacheable  ),  
        .sbuf_is_amo_i              (is_amo      ), 

        .dcache_sbuf_vld_i          (dcache_sbuf_vld   ),            
        .dcache_sbuf_way_i          (dcache_sbuf_way   ),    
        .dcache_sbuf_idx_i          (dcache_sbuf_idx   ),    
        .dcache_sbuf_amo_i          (dcache_sbuf_amo   ),    
        .dcache_sbuf_rdata_i        (dcache_sbuf_rdata ),      

        .lookup_paddr_i             (lookup_paddr),                      
        .lookup_be_o                (lookup_be   ),     
        .lookup_data_o              (lookup_data ),       
        .lookup_stall_o             (lookup_stall ),

        .sbuf_dcache_we_vld_o       (sbuf_dcache_we_vld),         
        .sbuf_dcache_we_rdy_i       (sbuf_dcache_we_rdy),                            
        .sbuf_dcache_addr_o         (sbuf_dcache_addr  ),       
        .sbuf_dcache_wdata_o        (sbuf_dcache_wdata ),        
        .sbuf_dcache_be_o           (sbuf_dcache_be    ),     
        .sbuf_dcache_cacheable_o    (sbuf_dcache_cacheable),
        .sbuf_dcache_way_en_o       (sbuf_dcache_way_en),
        .sbuf_dcache_amo_op_o       (sbuf_dcache_amo_op),   

        .rob_lsu__retire_en_i       (rob_lsu__retire_en_i)              
    );


(* mark_debug = "true" *) logic              prb_lsu_ctrl_act;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_stall;
(* mark_debug = "true" *) logic[63:0]        prb_lsu_ctrl_addr;
(* mark_debug = "true" *) logic[ROB_WTH-1:0] prb_lsu_ctrl_rob_idx;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_dcache_vld;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_dcache_rdy;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_is_fence;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_fence_commit;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_fence_stall;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_amo_lock;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_noncache_lock;
(* mark_debug = "true" *) logic              prb_lsu_ctrl_addr_legal;

(* mark_debug = "true" *) logic              prb_lsu_sbuf_empty;
(* mark_debug = "true" *) logic              prb_lsu_sbuf_we_vld;
(* mark_debug = "true" *) logic              prb_lsu_sbuf_we_rdy;
(* mark_debug = "true" *) logic              prb_lsu_sbuf_we_cacheable;
(* mark_debug = "true" *) logic[7:0]         prb_lsu_sbuf_we_be;
(* mark_debug = "true" *) logic[63:0]        prb_lsu_sbuf_we_wdata;
(* mark_debug = "true" *) logic[31:0]        prb_lsu_sbuf_we_addr;
(* mark_debug = "true" *) logic[63:0]        prb_lsu_load_data;
(* mark_debug = "true" *) logic              prb_lsu_load_valid;
assign prb_lsu_load_data  = dcache_lsu__rsp_i.rdata;
assign prb_lsu_load_valid = dcache_lsu__rsp_i.valid;

assign prb_lsu_ctrl_act     = st1_act;
assign prb_lsu_ctrl_stall   = st1_stall;
assign prb_lsu_ctrl_addr    = st1_paddr;
assign prb_lsu_ctrl_rob_idx = st1_rob_idx;
assign prb_lsu_ctrl_dcache_vld = lsu_dcache__vld_o;
assign prb_lsu_ctrl_dcache_rdy = dcache_lsu__rdy_i;
assign prb_lsu_ctrl_is_fence = is_fence;
assign prb_lsu_ctrl_fence_stall = fence_stall;
assign prb_lsu_ctrl_fence_commit = fence_commit;
assign prb_lsu_ctrl_amo_lock = amo_lock;
assign prb_lsu_ctrl_noncache_lock = non_cache_lock;
assign prb_lsu_ctrl_addr_legal = addr_is_legal;


assign prb_lsu_sbuf_empty   = lsu_ctrl__sq_retire_empty_o;
assign prb_lsu_sbuf_we_vld  = sbuf_dcache_we_vld;
assign prb_lsu_sbuf_we_rdy  = sbuf_dcache_we_rdy;
assign prb_lsu_sbuf_we_cacheable = sbuf_dcache_cacheable;
assign prb_lsu_sbuf_we_be = sbuf_dcache_be;
assign prb_lsu_sbuf_we_wdata = sbuf_dcache_wdata;
assign prb_lsu_sbuf_we_addr = sbuf_dcache_addr;
//======================================================================================================================
// just for simulation
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
//======================================================================================================================
// probe signals
//======================================================================================================================

endmodule : sy_ppl_lsu_ctrl
