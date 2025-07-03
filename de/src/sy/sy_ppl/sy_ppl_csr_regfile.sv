// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_csr_regfile.v
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

module sy_ppl_csr_regfile
    import sy_pkg::*;
#(
    parameter int HART_ID_WTH = 1
)(
    // =====================================
    // [clock & reset & flush]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [hart info]
    input   logic[AWTH-1:0]                 boot_addr_i,
    input   logic[HART_ID_WTH-1:0]          hart_id_i,
    // =====================================
    // [intruppt signal]
    input   logic[1:0]                      irq_i , // external interrupts
    input   logic                           ipi_i,
    input   logic                           timer_irq_i,  // timer interrupt
    // =====================================
    // [to decocde stage]
    output  priv_lvl_t                      priv_lvl_o,
    output  xs_t                            fs_o,
    output  logic[2:0]                      frm_o,
    output  logic                           tvm_o,     // trap virtual memory
    output  logic                           tw_o,      // timeout wait
    output  logic                           tsr_o,     // trap sret
    // =====================================
    // [to fpu]
    output  logic[4:0]                      fflags_o,
    output  logic[6:0]                      fprec_o,
    // =====================================
    // to cache
    output  logic                           icache_en_o,  // L1 ICache Enable
    output  logic                           dcache_en_o,  // L1 DCache Enable
    // =====================================
    // to mmu
    output  priv_lvl_t                      ld_st_priv_lvl_o,
    output  logic                           en_translation_o,
    output  logic                           en_ld_st_translation_o,
    output  logic[43:0]                     satp_ppn_o,
    output  logic[ASID_WIDTH-1:0]           asid_o,
    output  logic                           sum_o,
    output  logic                           mxr_o,
    // =====================================
    // from rob 
    input   logic                           rob_csr__write_fflags_i,
    input   logic[4:0]                      rob_csr__fflags_i,
    input   logic                           rob_csr__dirty_fp_i,
    // =====================================
    // from ctrl module
    input   trap_t                          ctrl_csr__trap_i,
    input   logic                           ctrl_csr__mret_i,
    input   logic                           ctrl_csr__sret_i,
    input   logic                           ctrl_csr__dret_i,
    // =====================================
    // to ctrl module
    output  logic[AWTH-1:0]                 csr_ctrl__trap_vec_o,
    output  logic[AWTH-1:0]                 csr_ctrl__epc_o,
    output  intr_ctrl_t                     csr_ctrl__intr_o,
    output  logic                           csr_ctrl__wfi_wakeup_o,
    // -----
    // CSR interface
    // -- csr input interface
    input   csr_bus_req_t                   lsu_csr__bus_req_i,
    input   csr_bus_wr_t                    lsu_csr__bus_wr_i,
    output  csr_bus_rsp_t                   csr_lsu__bus_rsp_o
);

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    csr_addr_t                              raddr;
    logic[DWTH-1:0]                         mcycleh, mcycle;
    satp_t                                  satp_q, satp_d;
    priv_lvl_t                              priv_lvl_d, priv_lvl_q;

    status_rv64_t                           mstatus_q,  mstatus_d;
    logic [63:0]                            mtvec_q,     mtvec_d;
    logic [63:0]                            medeleg_q,   medeleg_d;
    logic [63:0]                            mideleg_q,   mideleg_d;
    csr_mip_t                               mip_q,       mip_d;
    csr_mie_t                               mie_q,       mie_d;
    logic [63:0]                            mscratch_q,  mscratch_d;
    logic [63:0]                            mepc_q,      mepc_d;
    csr_mcause_t                            mcause_q,    mcause_d;
    logic [63:0]                            mtval_q,     mtval_d;

    logic [63:0]                            stvec_q,     stvec_d;
    logic [63:0]                            sscratch_q,  sscratch_d;
    logic [63:0]                            sepc_q,      sepc_d;
    csr_mcause_t                            scause_q,    scause_d;
    logic [63:0]                            stval_q,     stval_d;
    logic [63:0]                            dcache_q,    dcache_d;
    logic [63:0]                            icache_q,    icache_d;
    fcsr_t                                  fcsr_q,      fcsr_d;

    logic [63:0]                            csr_wdata;
    logic [63:0]                            mask;
    priv_lvl_t                              trap_to_priv_lvl;

    logic                                   mprv;
    logic                                   en_ld_st_translation_d, en_ld_st_translation_q;

    logic                                   global_enable;
    logic                                   intr_en;
    logic                                   dirty_fp_state_csr;

    logic                                   privilege_violation;
    logic                                   read_access_exception; 
    logic                                   update_access_exception;
    logic                                   privilege_violation_reg;
    logic                                   read_access_exception_reg; 
    logic                                   update_access_exception_reg;
    logic                                   csr_query_en_reg;
    logic                                   is_wr_reg;   
    logic                                   is_rd_reg;      
    logic                                   need_flush;
    logic                                   need_flush_reg;
    logic[DWTH-1:0]                         csr_read_data;
    logic[DWTH-1:0]                         csr_read_data_reg;
    logic [63:0]                            cycle_q,     cycle_d;

//======================================================================================================================
// Instance
//======================================================================================================================

    // -- Read data select
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            update_access_exception_reg <= 1'b0;
            read_access_exception_reg <= 1'b0;
            privilege_violation_reg <= 1'b0;
            need_flush_reg <= 1'b0;
            csr_read_data_reg <= '0;
            csr_query_en_reg <= 1'b0;
            is_wr_reg <= 1'b0;
            is_rd_reg  <= 1'b0;
        end else begin
            update_access_exception_reg <= update_access_exception;
            read_access_exception_reg <= read_access_exception;
            privilege_violation_reg <= privilege_violation;
            need_flush_reg <= need_flush;
            csr_read_data_reg <= csr_read_data;
            csr_query_en_reg <= lsu_csr__bus_req_i.csr_query_en;
            is_wr_reg <= lsu_csr__bus_req_i.is_wr;
            is_rd_reg <= lsu_csr__bus_req_i.is_rd;
        end
    end

    assign csr_lsu__bus_rsp_o.rdata = csr_read_data_reg;
    assign csr_lsu__bus_rsp_o.excp_en = csr_query_en_reg && (privilege_violation_reg || (update_access_exception_reg && is_wr_reg) 
                    || (read_access_exception_reg && is_rd_reg));
    assign csr_lsu__bus_rsp_o.need_flush = csr_query_en_reg && need_flush_reg && is_wr_reg;

    always_comb begin
        update_access_exception = 1'b0;
        read_access_exception = 1'b0;
        csr_read_data = 0;
        need_flush = 1'b0;
        case(lsu_csr__bus_req_i.raddr)
                CSR_MHARTID    : csr_read_data = hart_id_i;
                CSR_MSTATUS    : begin
                    csr_read_data = mstatus_q;
                    need_flush = 1'b1;
                end
                CSR_MISA       : csr_read_data = ISA_CODE;
                CSR_MEDELEG    : csr_read_data = medeleg_q;
                CSR_MIDELEG    : csr_read_data = mideleg_q;
                CSR_MIE        : csr_read_data = mie_q;
                CSR_MTVEC      : csr_read_data = mtvec_q;
                CSR_MCOUNTEREN : csr_read_data = 64'b0;
                CSR_MSCRATCH   : csr_read_data = mscratch_q;
                CSR_MEPC       : begin 
                    csr_read_data = mepc_q;
                    need_flush = 1'b1;
                end
                CSR_MCAUSE     : csr_read_data = mcause_q;
                CSR_MTVAL      : csr_read_data = mtval_q;
                CSR_MIP        : csr_read_data = mip_q;
                CSR_SSTATUS    : begin
                    need_flush = 1'b1;
                    csr_read_data = mstatus_q & SMODE_STATUS_READ_MASK;
                end
                CSR_SIE        : csr_read_data = mie_q & mideleg_q;                
                CSR_STVEC      : csr_read_data = stvec_q;                
                CSR_SCOUNTEREN : csr_read_data = 64'b0;                
                CSR_SSCRATCH   : csr_read_data = sscratch_q;
                CSR_SEPC       : begin 
                    csr_read_data = sepc_q;
                    need_flush  = 1'b1;
                end
                CSR_SCAUSE     : csr_read_data = scause_q;
                CSR_STVAL      : csr_read_data = stval_q;
                CSR_SIP        : csr_read_data = mip_q & mideleg_q;
                CSR_SATP       : begin
                    if(priv_lvl_o == PRIV_LVL_S && mstatus_q.tvm) begin
                        update_access_exception = 1'b1;
                        read_access_exception = 1'b1;
                    end else begin
                        csr_read_data = satp_q;
                        need_flush = 1'b1;
                    end
                end
                // Floating-Point CSRs
                CSR_FFLAGS      : begin 
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                        read_access_exception = 1'b1;
                    end else begin
                        need_flush = 1'b1;
                        csr_read_data = {59'b0,fcsr_q.fflags};
                    end
                end
                CSR_FRM         : begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                        read_access_exception = 1'b1;
                    end else begin
                        need_flush = 1'b1;
                        csr_read_data = {61'b0,fcsr_q.frm};
                    end
                end
                CSR_FCSR        : begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                        read_access_exception = 1'b1;
                    end else begin
                        need_flush = 1'b1;
                        csr_read_data = {56'b0,fcsr_q.frm,fcsr_q.fflags};
                    end
                end
                CSR_FTRAN       : begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                        read_access_exception = 1'b1;
                    end else begin
                        need_flush = 1'b1;
                        csr_read_data = {57'b0,fcsr_q.fprec};
                    end
                end
                CSR_MCYCLE  : csr_read_data = cycle_q;
                CSR_DCACHE: csr_read_data = dcache_q; 
                CSR_ICACHE: csr_read_data = icache_q; 
                //Trace Register (RW)
                default:    begin
                    update_access_exception = 1'b1;
                    read_access_exception = 1'b1;
                    csr_read_data = '0;
                end
        endcase
    end
    // Write CSR
    assign csr_wdata = lsu_csr__bus_wr_i.wdata;
    always_comb begin: csr_write
        automatic satp_t satp;
        satp = satp_q;
        cycle_d = cycle_q + 1;
        fcsr_d = fcsr_q;
        priv_lvl_d = priv_lvl_q;
        // s mode csr   
        sepc_d = sepc_q;
        scause_d = scause_q;
        stvec_d = stvec_q;
        sscratch_d = sscratch_q;
        stval_d = stval_q;
        satp_d = satp_q;
        // m mode csr 
        mstatus_d = mstatus_q;
        medeleg_d = medeleg_q;
        mideleg_d = mideleg_q;
        mie_d = mie_q;
        mip_d = mip_q;
        mepc_d = mepc_q;
        mcause_d = mcause_q;
        mtval_d = mtval_q;
        mscratch_d = mscratch_q;
        mtvec_d = mtvec_q;
        // cache csr
        dcache_d = dcache_q;
        icache_d = icache_q;

        dirty_fp_state_csr = 1'b0;
        if(lsu_csr__bus_wr_i.wr_en) begin
            case(lsu_csr__bus_wr_i.waddr)
                // FPU csr
                CSR_FFLAGS: begin
                    dirty_fp_state_csr = 1'b1;
                    fcsr_d.fflags = csr_wdata[4:0];
                end
                CSR_FRM: begin
                    dirty_fp_state_csr = 1'b1;
                    fcsr_d.frm= csr_wdata[2:0];
                end
                CSR_FCSR: begin
                    dirty_fp_state_csr = 1'b1;
                    fcsr_d[7:0] = csr_wdata[7:0];
                end
                CSR_FTRAN: begin
                    dirty_fp_state_csr = 1'b1;
                    fcsr_d.fprec = csr_wdata[6:0];
                end
                // s mode csr
                CSR_SSTATUS: begin
                    mask = SMODE_STATUS_WRITE_MASK;
                    mstatus_d = (mstatus_q & ~mask) | (csr_wdata & mask);
                end
                CSR_SIE: begin
                    mie_d = (mie_q & ~mideleg_q) | (csr_wdata & mideleg_q);
                end
                CSR_SIP: begin
                    // only support software interrupt delegated
                    mask = MIP_SSIP & mideleg_q; 
                    mip_d = (mip_q & ~mask) | (csr_wdata & mask);
                end
                CSR_SCOUNTEREN:;
                CSR_STVEC: begin
                    stvec_d = {csr_wdata[63:2], 1'b0, csr_wdata[0]};
                end
                CSR_SSCRATCH: begin
                    sscratch_d = csr_wdata;
                end
                CSR_SEPC: begin
                    sepc_d = {csr_wdata[63:1], 1'b0};
                end
                CSR_SCAUSE: begin
                    scause_d = csr_wdata;
                end
                CSR_STVAL: begin
                    stval_d = csr_wdata;
                end
                CSR_SATP: begin
                    satp = satp_t'(csr_wdata);
                    satp.asid = satp.asid & {15'b0,1'b1}; // asid width = 1
                    if(satp.mode == MODE_OFF || satp.mode == MODE_SV39) 
                        satp_d = satp;
                end
                // m mode csr
                CSR_MSTATUS: begin
                    mstatus_d = csr_wdata;
                    mstatus_d.xs = Off;
                    mstatus_d.upie = 1'b0;
                    mstatus_d.uie = 1'b0;
                end
                CSR_MISA:;
                CSR_MEDELEG: begin
                    mask = (1 << INST_ADDR_MISALIGNED) |
                           (1 << BREAK_POINT) |
                           (1 << ENV_CALL_FROM_U_MODE) |
                           (1 << INST_PAGE_FAULT) |
                           (1 << LD_PAGE_FAULT) |
                           (1 << ST_AMO_PAGE_FAULT);
                    medeleg_d = (medeleg_q & ~mask) | (csr_wdata & mask);
                end
                CSR_MIDELEG: begin
                    mask = MIP_SSIP | MIP_STIP | MIP_SEIP; 
                    mideleg_d = (mideleg_q & ~mask) | (csr_wdata & mask);   
                end
                CSR_MIE: begin
                    mask = MIP_SSIP | MIP_STIP | MIP_SEIP | MIP_MSIP | MIP_MTIP;
                    mie_d = (mie_q & ~mask) | (csr_wdata & mask);
                end
                CSR_MTVEC: begin
                    mtvec_d = {csr_wdata[63:2], 1'b0, csr_wdata[0]};
                    if(csr_wdata[0]) begin
                        mtvec_d = {csr_wdata[63:8], 7'b0, csr_wdata[0]};
                    end 
                end
                CSR_MCOUNTEREN:;
                CSR_MSCRATCH: begin
                    mscratch_d = csr_wdata;
                end
                CSR_MEPC: begin
                    mepc_d = {csr_wdata[63:1], 1'b0};
                end
                CSR_MCAUSE: begin
                    mcause_d = csr_wdata;
                end
                CSR_MTVAL: begin
                    mtval_d = csr_wdata;
                end
                CSR_MIP: begin
                    mask = MIP_SSIP | MIP_STIP | MIP_SEIP;
                    mip_d = (mip_q & ~mask) | (csr_wdata & mask);
                end
                CSR_MCYCLE: begin
                    cycle_d = csr_wdata;
                end
                CSR_DCACHE: begin
                    dcache_d = csr_wdata[0];
                end
                CSR_ICACHE: begin
                    icache_d = csr_wdata[0];
                end
                default:;
            endcase
        end

        // other logic
        mstatus_d.sxl = XLEN_64; // register length in s mode (can't changed)
        mstatus_d.uxl = XLEN_64; // register length in u mode (can't changed)     

        if(dirty_fp_state_csr || rob_csr__dirty_fp_i) begin
            mstatus_d.fs = is_Dirty;
        end
        mstatus_d.sd = (mstatus_q.fs == is_Dirty) || (mstatus_q.xs == is_Dirty);

        if(rob_csr__write_fflags_i) begin
            fcsr_d.fflags = rob_csr__fflags_i | fcsr_q.fflags;
        end

        // external interrupts
        mip_d.MEIP = irq_i[0];
        mip_d.SEIP = irq_i[1];
        mip_d.MSIP = ipi_i;
        mip_d.MTIP = timer_irq_i;
        // mip_d.STIP = timer_irq_i;

        // handle exceptions
        trap_to_priv_lvl = PRIV_LVL_M;
        if(ctrl_csr__trap_i.valid && ctrl_csr__trap_i.excp_cause != DEBUG_REQUEST) begin
            // cause[63] indicates interrupt or exception
            if((ctrl_csr__trap_i.is_intr && mideleg_q[ctrl_csr__trap_i.intr_cause[5:0]]) || 
                (!ctrl_csr__trap_i.is_intr && medeleg_q[ctrl_csr__trap_i.excp_cause[5:0]])) begin
                    // traps never transition from a more-privileged mode to a less privileged mode
                    // so if we are already in M mode, stay there
                    trap_to_priv_lvl = (priv_lvl_o == PRIV_LVL_M) ? PRIV_LVL_M: PRIV_LVL_S;
                end
            if(trap_to_priv_lvl == PRIV_LVL_S) begin
                mstatus_d.sie = 1'b0;
                mstatus_d.spie = mstatus_q.sie;
                // either u mode or s mode
                mstatus_d.spp = priv_lvl_q[0];
                scause_d.is_intr = ctrl_csr__trap_i.is_intr;
                if(ctrl_csr__trap_i.is_intr) begin
                    scause_d.ecode.intr = ctrl_csr__trap_i.intr_cause;
                end else begin
                    scause_d.ecode.excp = ctrl_csr__trap_i.excp_cause;                   
                end
                sepc_d = ctrl_csr__trap_i.pc;
                stval_d = ctrl_csr__trap_i.tval;
            end else begin // M mode
                mstatus_d.mie = 1'b0; 
                mstatus_d.mpie = mstatus_q.mie;
                mstatus_d.mpp = priv_lvl_q;
                mcause_d.is_intr = ctrl_csr__trap_i.is_intr;
                if(ctrl_csr__trap_i.is_intr) begin
                    mcause_d.ecode.intr = ctrl_csr__trap_i.intr_cause;
                end else begin
                    mcause_d.ecode.excp = ctrl_csr__trap_i.excp_cause;                   
                end
                mepc_d = ctrl_csr__trap_i.pc;
                mtval_d = ctrl_csr__trap_i.tval;
            end
            priv_lvl_d = trap_to_priv_lvl;
        end 

        // modify privledge level
        if(mprv && satp_q.mode == MODE_SV39 && (mstatus_q.mpp != PRIV_LVL_M)) begin
            en_ld_st_translation_d = 1'b1;
        end else begin
            en_ld_st_translation_d = en_translation_o;
        end
        ld_st_priv_lvl_o = (mprv) ? mstatus_q.mpp : priv_lvl_o;
        en_ld_st_translation_o = en_ld_st_translation_q;

        // return from environment
        if(ctrl_csr__mret_i) begin
            // csr_ctrl__eret_o = 1'b1; 
            mstatus_d.mie = mstatus_q.mpie;
            mstatus_d.mpie = 1'b1;         
            priv_lvl_d = mstatus_q.mpp;
            mstatus_d.mpp = PRIV_LVL_U;
        end
        if(ctrl_csr__sret_i) begin
            // csr_ctrl__eret_o = 1'b1;
            mstatus_d.sie = mstatus_q.spie;
            mstatus_d.spie = 1'b1;
            priv_lvl_d = priv_lvl_t'({1'b0,mstatus_q.spp});
            mstatus_d.spp = 1'b0;
        end
        // if(ctrl_csr__dret_i) begin
        //     // csr_ctrl__eret_o = 1'b1;
        //     priv_lvl_d = pri_e'(dcsr_q.prv);
        // end
    end  
    

    always_comb begin : gen_trap_vec
        csr_ctrl__trap_vec_o = {mtvec_q[63:2], 2'b0};
        if(trap_to_priv_lvl == PRIV_LVL_S) begin
            csr_ctrl__trap_vec_o = {stvec_q[63:2], 2'b0};
        end 
        //if(ctrl_csr__debug_mode_i) begin
        //    csr_ctrl__trap_vec_o = HpuDefaultConfig.DmBaseAddress + dm::ExceptionAddress;
        //end
        if((mtvec_q[0] || stvec_q[0]) && ctrl_csr__trap_i.is_intr) begin
            csr_ctrl__trap_vec_o[7:2] = ctrl_csr__trap_i.intr_cause;
        end
    end

    always_comb begin : gen_rtn_vec
        csr_ctrl__epc_o = mepc_q;
        if(ctrl_csr__sret_i) begin
            csr_ctrl__epc_o = sepc_q;
        end 
        // if(ctrl_csr__dret_i) begin
        //     csr_ctrl__epc_o = dpc_q;
        // end
    end

//======================================================================================================================
// CSR exception gen
//======================================================================================================================
    always_comb begin: privilege_check
        privilege_violation = 1'b0;
        if((lsu_csr__bus_req_i.raddr[9:8] & priv_lvl_o) != lsu_csr__bus_req_i.raddr[9:8]) begin
            privilege_violation = 1'b1; 
        end 
        if(lsu_csr__bus_req_i.raddr[11:4] == 8'h7b) begin
            privilege_violation = 1'b1; 
        end
    end


    assign global_enable = ((mstatus_q.mie & (priv_lvl_o == PRIV_LVL_M)) | priv_lvl_o != PRIV_LVL_M);  
    always_comb begin: gen_intr
        csr_ctrl__intr_o.intr_en = 1'b0;     
        csr_ctrl__intr_o.intr_cause = SOFTWARE_U_MODE;     
        intr_en = 1'b0;
        if(mie_q.STIE && mip_q.STIP) begin
            csr_ctrl__intr_o.intr_cause = TIMER_S_MODE;
            intr_en = 1'b1;
        end
        if(mie_q.SSIE && mip_q.SSIP) begin
            csr_ctrl__intr_o.intr_cause = SOFTWARE_S_MODE;
            intr_en = 1'b1;
        end
        // if(mie_q.SEIE && (mip_q.SEIP || irq_i[1])) begin
        //     csr_ctrl__intr_o.intr_cause = EXT_S_MODE;
        //     intr_en = 1'b1;
        // end
        if(mie_q.SEIE && mip_q.SEIP) begin
            csr_ctrl__intr_o.intr_cause = EXT_S_MODE;
            intr_en = 1'b1;
        end
        if(mie_q.MTIE && mip_q.MTIP) begin
            csr_ctrl__intr_o.intr_cause = TIMER_M_MODE;
            intr_en = 1'b1;
        end
        if(mie_q.MSIE && mip_q.MSIP) begin
            csr_ctrl__intr_o.intr_cause = SOFTWARE_M_MODE;
            intr_en = 1'b1;
        end
        if(mie_q.MEIE && mip_q.MEIP) begin
            csr_ctrl__intr_o.intr_cause = EXT_M_MODE;
            intr_en = 1'b1;
        end

        if(intr_en && global_enable) begin
           if(mideleg_q[csr_ctrl__intr_o.intr_cause]) begin
                if((mstatus_q.sie && priv_lvl_o == PRIV_LVL_S) || priv_lvl_o == PRIV_LVL_U) begin
                   csr_ctrl__intr_o.intr_en = 1'b1; 
                end
           end else begin
                csr_ctrl__intr_o.intr_en = 1'b1;            
           end
        end
    end

    // output some ctrl signals
    assign csr_ctrl__wfi_wakeup_o   = |mip_q || irq_i[1];
    assign priv_lvl_o               = priv_lvl_q;
    assign fflags_o                 = fcsr_q.fflags;
    assign frm_o                    = fcsr_q.frm;
    assign fprec_o                  = fcsr_q.fprec;
    // to MMU           
    assign satp_ppn_o               = satp_q.ppn;
    assign asid_o                   = satp_q.asid[ASID_WIDTH-1:0];
    assign sum_o                    = mstatus_q.sum;
    assign en_translation_o         = (satp_q.mode == 4'h8 && priv_lvl_o != PRIV_LVL_M) ? 1'b1 : 1'b0;
    assign mxr_o                    = mstatus_q.mxr;
    assign tvm_o                    = mstatus_q.tvm;    
    assign tw_o                     = mstatus_q.tw;
    assign tsr_o                    = mstatus_q.tsr;
    assign icache_en_o              = icache_q[0]; 
    assign dcache_en_o              = dcache_q[0];
    // assign mprv                     = (debug_mode_q && !dcsr_q.mprven) ? 1'b0 : mstatus_q.mprv;  
    assign mprv                     = mstatus_q.mprv;  

    assign fs_o = mstatus_q.fs;

//======================================================================================================================
// registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i))begin
        if(`DFF_IS_R(rst_i)) begin
            priv_lvl_q             <= PRIV_LVL_M;
            // floating-point registers
            fcsr_q                 <= 64'b0;
            // machine mode registers
            mstatus_q              <= 64'b0;
            // set to boot address + direct mode + 4 byte offset which is the initial trap
            mtvec_q                <= boot_addr_i + 'h40;
            medeleg_q              <= 64'b0;
            mideleg_q              <= 64'b0;
            mip_q                  <= 64'b0;
            mie_q                  <= 64'b0;
            mepc_q                 <= 64'b0;
            mcause_q               <= 64'b0;
            mscratch_q             <= 64'b0;
            mtval_q                <= 64'b0;
            cycle_q                <= 64'b0;
            dcache_q               <= 64'b1;
            icache_q               <= 64'b1;
            // supervisor mode registers
            sepc_q                 <= 64'b0;
            scause_q               <= 64'b0;
            stvec_q                <= 64'b0;
            sscratch_q             <= 64'b0;
            stval_q                <= 64'b0;
            satp_q                 <= 64'b0;
            // aux registers
            en_ld_st_translation_q <= 1'b0;
        end else begin
            priv_lvl_q             <= priv_lvl_d;
            // floating-point registers
            fcsr_q                 <= fcsr_d;
            // machine mode registers
            mstatus_q              <= mstatus_d;
            mtvec_q                <= mtvec_d;
            medeleg_q              <= medeleg_d;
            mideleg_q              <= mideleg_d;
            mip_q                  <= mip_d;
            mie_q                  <= mie_d;
            mepc_q                 <= mepc_d;
            mcause_q               <= mcause_d;
            mscratch_q             <= mscratch_d;
            mtval_q                <= mtval_d;
            cycle_q                <= cycle_d;
            dcache_q               <= dcache_d;
            icache_q               <= icache_d;
            // supervisor mode registers
            sepc_q                 <= sepc_d;
            scause_q               <= scause_d;
            stvec_q                <= stvec_d;
            sscratch_q             <= sscratch_d;
            stval_q                <= stval_d;
            satp_q                 <= satp_d;
            // aux registers
            en_ld_st_translation_q <= en_ld_st_translation_d;
        end 
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
// (* mark_debug = "true" *) logic         prb_csr_intr_en;
// (* mark_debug = "true" *) intr_e        prb_csr_intr_cause;

// assign prb_csr_intr_en     = csr_ctrl__intr_o.intr_en;
// assign prb_csr_intr_cause  = csr_ctrl__intr_o.intr_cause;
endmodule : sy_ppl_csr_regfile
