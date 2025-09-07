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

// most code of this file come from cva6 : https://github.com/openhwgroup/cva6  
module sy_ppl_csr_regfile 
    import sy_pkg::*;
#(
    parameter              HART_ID_WTH           = 1,
    parameter int unsigned ASID_WIDTH            = 1
) (
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      // HPU clock
    // -- <reset>
    input   logic                           rst_i,                      // HPU reset

    input   logic[AWTH-1:0]                 boot_addr_i,
    input   logic[HART_ID_WTH-1:0]          hart_id_i,
    input   logic                           debug_req_i,
    output  logic                           halt_o,

    // csr operation interface
    input   logic                           alu_csr__valid_i,
    input   lb_cmd_e                        alu_csr__cmd_i,
    input   logic[11:0]                     alu_csr__addr_i,
    input   logic[DWTH-1:0]                 alu_csr__wdata_i,
    output  logic[DWTH-1:0]                 csr_alu__rdata_o,
    input   exception_t                     alu_csr__ex_i,
    input   logic[AWTH-1:0]                 alu_csr__pc_i,
    input   logic[31:0]                     alu_csr__instr_i,
    input   logic                           alu_csr__write_fflags_i,
    input   logic                           alu_csr__dirty_fp_state_i,
    input   logic[4:0]                      alu_csr__fflags_i,     
    input   logic                           alu_csr__wfi_i,
    // from ctrl module
    input   logic                           alu_csr__mret_i,
    input   logic                           alu_csr__sret_i,
    input   logic                           alu_csr__dret_i,
    // to decode stage
    output  irq_ctrl_t                      csr_dec__irq_ctrl_o,
    // external interupts
    input   logic[1:0]                      irq_i , // external interrupts
    input   logic                           ipi_i,
    // timer interrupt
    input   logic                           timer_irq_i,    
    output  priv_lvl_t                      priv_lvl_o,

    //to ctrl module
    output  logic                           csr_ctrl__eret_o,
    output  logic[63:0]                     csr_ctrl__epc_o,
    output  logic                           csr_ctrl__ex_valid_o,
    output  logic[63:0]                     csr_ctrl__trap_vec_o,
    output  logic                           csr_ctrl__wfi_wakeup_o,
    output  logic                           csr_ctrl__set_debug_o,
    output  logic                           csr_ctrl__debug_mode_o,
    output  logic                           csr_ctrl__flush_o,
    //FPU 
    output  xs_t                            fs_o,
    output  logic[4:0]                      fflags_o,
    output  logic[2:0]                      frm_o,
    output  logic[6:0]                      fprec_o,
    // MMU
    output logic                            en_translation_o,           
    output logic                            en_ld_st_translation_o,     
    output priv_lvl_t                       ld_st_priv_lvl_o,           // Privilege level at which load and stores should happen
    output logic                            sum_o,
    output logic                            mxr_o,
    output logic [43:0]                     satp_ppn_o,
    output logic                            asid_o,
    // Virtualization Support
    output logic                            tvm_o,                      // trap virtual memory
    output logic                            tw_o,                       // timeout wait
    output logic                            tsr_o,                      // trap sret
    output logic                            debug_mode_o,               // we are in debug mode -> that will change some decoding
    // Caches
    output logic                            icache_en_o,                // L1 ICache Enable
    output logic                            dcache_en_o,                // L1 DCache Enable
    // Performance Counter
    output logic  [4:0]                     perf_addr_o,                // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
    output logic  [63:0]                    perf_data_o,                // write data to performance counter module
    input  logic  [63:0]                    perf_data_i,                // read data from performance counter module
    output logic                            perf_we_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    // internal signal to keep track of access exceptions
    logic               read_access_exception, update_access_exception, privilege_violation;
    logic               csr_we, csr_read;
    logic [63:0]        csr_wdata, csr_rdata;
    priv_lvl_t          trap_to_priv_lvl;
    // register for enabling load store address translation, this is critical, hence the register
    logic               en_ld_st_translation_d, en_ld_st_translation_q;
    logic               mprv;
    logic               mret;  // return from M-mode exception
    logic               sret;  // return from S-mode exception
    logic               dret;  // return from debug mode
    // CSR write causes us to mark the FPU state as dirty
    logic               dirty_fp_state_csr;
    status_rv64_t       mstatus_q,  mstatus_d;
    satp_t              satp_q, satp_d;
    dcsr_t              dcsr_q,     dcsr_d;
    csr_reg_t           csr_addr;
    csr_addr_t          csr_addr_decode;
    // privilege level register
    priv_lvl_t          priv_lvl_d, priv_lvl_q;
    // we are in debug
    logic               mtvec_rst_load_q;// used to determine whether we came out of reset

    logic               debug_mode_q, debug_mode_d;
    logic [63:0]        dpc_q,       dpc_d;
    logic [63:0]        dscratch0_q, dscratch0_d;
    logic [63:0]        dscratch1_q, dscratch1_d;
    logic [63:0]        mtvec_q,     mtvec_d;
    logic [63:0]        medeleg_q,   medeleg_d;
    logic [63:0]        mideleg_q,   mideleg_d;
    logic [63:0]        mip_q,       mip_d;
    logic [63:0]        mie_q,       mie_d;
    logic [63:0]        mscratch_q,  mscratch_d;
    logic [63:0]        mepc_q,      mepc_d;
    logic [63:0]        mcause_q,    mcause_d;
    logic [63:0]        mtval_q,     mtval_d;

    logic [63:0]        stvec_q,     stvec_d;
    logic [63:0]        sscratch_q,  sscratch_d;
    logic [63:0]        sepc_q,      sepc_d;
    logic [63:0]        scause_q,    scause_d;
    logic [63:0]        stval_q,     stval_d;
    logic [63:0]        dcache_q,    dcache_d;
    logic [63:0]        icache_q,    icache_d;


    logic [63:0]        cycle_q,     cycle_d;
    logic [63:0]        instret_q,   instret_d;

    fcsr_t              fcsr_q,      fcsr_d;

    exception_t         ex;
    logic[AWTH-1:0]     pc;

    logic               wfi_d, wfi_q;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign csr_addr = csr_reg_t'(alu_csr__addr_i);
    assign csr_addr_decode = csr_addr_t'(alu_csr__addr_i);
//======================================================================================================================
// CSR read logic
//======================================================================================================================
    always_comb begin: read_csr
        read_access_exception = 1'b0; 
        csr_rdata = '0;
        perf_addr_o = alu_csr__addr_i[4:0]; 
        if(csr_read) begin
            case(csr_addr)
                CSR_FFLAGS: begin
                    if(mstatus_q.fs == Off) begin
                        read_access_exception = 1'b1; 
                    end else begin
                        csr_rdata = {59'b0, fcsr_q.fflags};
                    end    
                end         
                CSR_FRM : begin
                    if(mstatus_q.fs == Off) begin
                        read_access_exception = 1'b1; 
                    end else begin
                        csr_rdata = {61'b0, fcsr_q.frm};
                    end    
                end     
                CSR_FCSR: begin
                    if(mstatus_q.fs == Off) begin
                        read_access_exception = 1'b1; 
                    end else begin
                        csr_rdata = {56'b0, fcsr_q.frm, fcsr_q.fflags};
                    end    
                end     
                CSR_FTRAN: begin
                    if(mstatus_q.fs == Off) begin
                        read_access_exception = 1'b1; 
                    end else begin
                        csr_rdata = {57'b0, fcsr_q.fprec}; 
                    end    
                end     
                // Supervisor Mode CSRs
                CSR_SSTATUS : begin
                    csr_rdata = mstatus_q & SMODE_STATUS_READ_MASK; 
                end        
                CSR_SIE :           csr_rdata = mie_q & mideleg_q;            
                CSR_SIP :           csr_rdata = mip_q & mideleg_q;            
                CSR_STVEC :         csr_rdata = stvec_q;          
                CSR_SCOUNTEREN :    csr_rdata = 64'b0; 
                CSR_SSCRATCH  :     csr_rdata = sscratch_q;      
                CSR_SEPC :          csr_rdata = sepc_q;          
                CSR_SCAUSE   :      csr_rdata = scause_q;      
                CSR_STVAL    :      csr_rdata = stval_q;      
                CSR_SATP     : begin
                    if(priv_lvl_o == PRIV_LVL_S && mstatus_q.tvm) begin
                        read_access_exception = 1'b1;
                    end else begin
                        csr_rdata = satp_q;
                    end
                end      
                // Machine Mode CSRs
                CSR_MSTATUS :       csr_rdata = mstatus_q;       
                CSR_MISA    :       csr_rdata = ISA_CODE;       
                CSR_MEDELEG :       csr_rdata = medeleg_q;       
                CSR_MIDELEG :       csr_rdata = mideleg_q;       
                CSR_MIE     :       csr_rdata = mie_q;       
                CSR_MTVEC   :       csr_rdata = mtvec_q;       
                CSR_MCOUNTEREN :    csr_rdata = 64'b0;    
                CSR_MSCRATCH:       csr_rdata = mscratch_q;       
                CSR_MEPC    :       csr_rdata = mepc_q;       
                CSR_MCAUSE  :       csr_rdata = mcause_q;       
                CSR_MTVAL   :       csr_rdata = mtval_q;       
                CSR_MIP     :       csr_rdata = mip_q;       
                CSR_MVENDORID:      csr_rdata = 64'b0; // not implemented
                CSR_MARCHID:        csr_rdata = SY_MARCHID;
                CSR_MIMPID:         csr_rdata = 64'b0; // not implemented
                CSR_MHARTID:        csr_rdata = hart_id_i;
                CSR_MCYCLE:         csr_rdata = cycle_q;
                CSR_MINSTRET:       csr_rdata = instret_q;
                // Counters and Timers
                CSR_ML1_ICACHE_MISS,
                CSR_ML1_DCACHE_MISS,
                CSR_MITLB_MISS,
                CSR_MDTLB_MISS,
                CSR_MLOAD,
                CSR_MSTORE,
                CSR_MEXCEPTION,
                CSR_MEXCEPTION_RET,
                CSR_MBRANCH_JUMP,
                CSR_MCALL,
                CSR_MRET,
                CSR_MMIS_PREDICT,
                CSR_MSB_FULL,
                CSR_MIF_EMPTY,
                CSR_MHPM_COUNTER_17,
                CSR_MHPM_COUNTER_18,
                CSR_MHPM_COUNTER_19,
                CSR_MHPM_COUNTER_20,
                CSR_MHPM_COUNTER_21,
                CSR_MHPM_COUNTER_22,
                CSR_MHPM_COUNTER_23,
                CSR_MHPM_COUNTER_24,
                CSR_MHPM_COUNTER_25,
                CSR_MHPM_COUNTER_26,
                CSR_MHPM_COUNTER_27,
                CSR_MHPM_COUNTER_28,
                CSR_MHPM_COUNTER_29,
                CSR_MHPM_COUNTER_30,
                CSR_MHPM_COUNTER_31: csr_rdata   = perf_data_i;
                // Cache Control (platform specifc)
                CSR_DCACHE     : csr_rdata = dcache_q;    
                CSR_ICACHE     : csr_rdata = icache_q;    
                // Triggers (not implemented)
                CSR_TSELECT :;       
                CSR_TDATA1  :;       
                CSR_TDATA2  :;       
                CSR_TDATA3  :;       
                // Debug CSR
                CSR_DCSR :         csr_rdata = {32'b0,dcsr_q};                          
                CSR_DPC  :         csr_rdata = dpc_q;
                CSR_DSCRATCH0 :    csr_rdata = dscratch0_q;      
                CSR_DSCRATCH1 :    csr_rdata = dscratch1_q;     
                default: read_access_exception = 1'b1;
            endcase
        end
    end
//======================================================================================================================
// CSR write logic
//======================================================================================================================
    logic[63:0] mask;
    always_comb begin: write_csr
        automatic satp_t satp;
        satp = satp_q;
        debug_mode_d = 1'b0;
        csr_ctrl__set_debug_o = 1'b0;
        instret_d = instret_q;
        cycle_d = cycle_q;
        if(!debug_mode_q) begin
            instret_d = instret_q + 1;
            cycle_d = cycle_q + 1;
        end

        update_access_exception = 1'b0;
        csr_ctrl__flush_o = 1'b0;

        perf_we_o = 1'b0;
        perf_data_o = 64'b0;
        fcsr_d = fcsr_q;
        priv_lvl_d = priv_lvl_q;
        // debug csr
        dcsr_d = dcsr_q; 
        dpc_d = dpc_q;
        dscratch0_d = dscratch0_q;
        dscratch1_d = dscratch1_q;
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
        if(mtvec_rst_load_q) begin
            mtvec_d = boot_addr_i + 'h40;
        end else begin
            mtvec_d = mtvec_q;
        end
        // cache csr
        dcache_d = dcache_q;
        icache_d = icache_q;

        csr_ctrl__eret_o = 1'b0;
        dirty_fp_state_csr = 1'b0;
        if(csr_we) begin
            case(csr_addr)
                // FPU csr
                CSR_FFLAGS: begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                    end else begin
                        dirty_fp_state_csr = 1'b1;
                        fcsr_d.fflags = csr_wdata[4:0];
                        csr_ctrl__flush_o = 1'b1;
                    end
                end
                CSR_FRM: begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                    end else begin
                        dirty_fp_state_csr = 1'b1;
                        fcsr_d.frm= csr_wdata[2:0];
                        csr_ctrl__flush_o = 1'b1;
                    end
                end
                CSR_FCSR: begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                    end else begin
                        dirty_fp_state_csr = 1'b1;
                        fcsr_d[7:0] = csr_wdata[7:0];
                        csr_ctrl__flush_o = 1'b1;
                    end
                end
                CSR_FTRAN: begin
                    if(mstatus_q.fs == Off) begin
                        update_access_exception = 1'b1;
                    end else begin
                        dirty_fp_state_csr = 1'b1;
                        fcsr_d.fprec = csr_wdata[6:0];
                        csr_ctrl__flush_o = 1'b1;
                    end   
                end
                // debug csr
                CSR_DCSR: begin
                    dcsr_d = csr_wdata[31:0];
                    dcsr_d.xdebugver = 4'h4;
                    dcsr_d.prv = priv_lvl_q;
                    dcsr_d.nmip = 1'b0;
                    dcsr_d.stopcount = 1'b0;
                    dcsr_d.stoptime = 1'b0;
                end
                CSR_DPC: begin
                    dpc_d = csr_wdata;
                end
                CSR_DSCRATCH0: begin
                    dscratch0_d = csr_wdata;
                end
                CSR_DSCRATCH1: begin
                    dscratch1_d = csr_wdata;
                end
                // trigger module csr(not implemented)
                CSR_TSELECT:; 
                CSR_TDATA1:;
                CSR_TDATA2: ;
                CSR_TDATA3: ;
                // s mode csr
                CSR_SSTATUS: begin
                    mask = SMODE_STATUS_WRITE_MASK;
                    mstatus_d = (mstatus_q & ~mask) | (csr_wdata & mask);
                    csr_ctrl__flush_o = 1'b1;
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
                    if(priv_lvl_o == PRIV_LVL_S && mstatus_q.tvm) begin
                        update_access_exception = 1'b1; 
                    end else begin
                        satp = satp_t'(csr_wdata);
                        satp.asid = satp.asid & {15'b0,1'b1}; // asid width = 1
                        if(satp.mode == MODE_OFF || satp.mode == MODE_SV39) 
                            satp_d = satp;
                        csr_ctrl__flush_o = 1'b1;
                    end
                end
                // m mode csr
                CSR_MSTATUS: begin
                    mstatus_d = csr_wdata;
                    mstatus_d.xs = Off;
                    mstatus_d.upie = 1'b0;
                    mstatus_d.uie = 1'b0;
                    csr_ctrl__flush_o = 1'b1;
                end
                CSR_MISA:;
                CSR_MEDELEG: begin
                    mask = (1 << INSTR_ADDR_MISALIGNED) |
                           (1 << BREAKPOINT) |
                           (1 << ENV_CALL_UMODE) |
                           (1 << INSTR_PAGE_FAULT) |
                           (1 << LOAD_PAGE_FAULT) |
                           (1 << STORE_PAGE_FAULT);
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
                CSR_MINSTRET: begin
                    instret_d = csr_wdata;
                end
                CSR_ML1_ICACHE_MISS,
                CSR_ML1_DCACHE_MISS,
                CSR_MITLB_MISS,
                CSR_MDTLB_MISS,
                CSR_MLOAD,
                CSR_MSTORE,
                CSR_MEXCEPTION,
                CSR_MEXCEPTION_RET,
                CSR_MBRANCH_JUMP,
                CSR_MCALL,
                CSR_MRET,
                CSR_MMIS_PREDICT,
                CSR_MSB_FULL,
                CSR_MIF_EMPTY,
                CSR_MHPM_COUNTER_17,
                CSR_MHPM_COUNTER_18,
                CSR_MHPM_COUNTER_19,
                CSR_MHPM_COUNTER_20,
                CSR_MHPM_COUNTER_21,
                CSR_MHPM_COUNTER_22,
                CSR_MHPM_COUNTER_23,
                CSR_MHPM_COUNTER_24,
                CSR_MHPM_COUNTER_25,
                CSR_MHPM_COUNTER_26,
                CSR_MHPM_COUNTER_27,
                CSR_MHPM_COUNTER_28,
                CSR_MHPM_COUNTER_29,
                CSR_MHPM_COUNTER_30,
                CSR_MHPM_COUNTER_31: begin
                    perf_data_o = csr_wdata;
                    perf_we_o   = 1'b1;
                end
                
                CSR_DCACHE: begin
                    dcache_d = csr_wdata[0];
                end
                CSR_ICACHE: begin
                    icache_d = csr_wdata[0];
                end
                default:update_access_exception=1'b1;
            endcase
        end

        // other logic
        mstatus_d.sxl = XLEN_64; // register length in s mode (can't changed)
        mstatus_d.uxl = XLEN_64; // register length in u mode (can't changed)     

        if(dirty_fp_state_csr || alu_csr__dirty_fp_state_i) begin
            mstatus_d.fs = is_Dirty;
        end
        mstatus_d.sd = (mstatus_q.fs == is_Dirty) || (mstatus_q.xs == is_Dirty);

        if(alu_csr__write_fflags_i) begin
            fcsr_d.fflags = alu_csr__fflags_i | fcsr_q.fflags;
        end

        // external interrupts
        mip_d[IRQ_M_EXT] = irq_i[0];
        mip_d[IRQ_M_SOFT] = ipi_i;
        mip_d[IRQ_M_TIMER] = timer_irq_i;
        // mip_d[IRQ_S_TIMER] = timer_irq_i;

        // handle exceptions
        trap_to_priv_lvl = PRIV_LVL_M;
        if(!debug_mode_q && ex.valid && ex.cause != DEBUG_REQUEST) begin
            csr_ctrl__flush_o = 1'b0;
            // cause[63] indicates interrupt or exception
            if((ex.cause[63] && mideleg_q[ex.cause[5:0]]) || 
                (!ex.cause[63] && medeleg_q[ex.cause[5:0]])) begin
                    // traps never transition from a more-privileged mode to a less privileged mode
                    // so if we are already in M mode, stay there
                    trap_to_priv_lvl = (priv_lvl_o == PRIV_LVL_M) ? PRIV_LVL_M : PRIV_LVL_S;
                end
            if(trap_to_priv_lvl == PRIV_LVL_S) begin
                mstatus_d.sie = 1'b0;
                mstatus_d.spie = mstatus_q.sie;
                // either u mode or s mode
                mstatus_d.spp = priv_lvl_q[0];
                scause_d = ex.cause;
                sepc_d = pc;
                stval_d = ex.tval;
            end else begin // M mode
                mstatus_d.mie = 1'b0; 
                mstatus_d.mpie = mstatus_q.mie;
                mstatus_d.mpp = priv_lvl_q;
                mcause_d = ex.cause;
                mepc_d = pc;
                mtval_d = ex.tval;
            end
            priv_lvl_d = trap_to_priv_lvl;
        end 

        // handle debug
        if(!debug_mode_q) begin
            dcsr_d.prv = priv_lvl_o;
            if(ex.valid && ex.cause == BREAKPOINT) begin
                unique case(priv_lvl_o)
                    PRIV_LVL_M: begin
                        csr_ctrl__set_debug_o = dcsr_q.ebreakm;
                        debug_mode_d = dcsr_q.ebreakm;
                    end
                    PRIV_LVL_S: begin
                        csr_ctrl__set_debug_o= dcsr_q.ebreaks;
                        debug_mode_d = dcsr_q.ebreaks;
                    end
                    PRIV_LVL_U: begin
                        csr_ctrl__set_debug_o= dcsr_q.ebreaku;
                        debug_mode_d = dcsr_q.ebreaku;
                    end
                    default:;
                endcase
                dpc_d = pc;
                dcsr_d.cause = dbg_pkg::CauseBreakpoint;
            end

            if(ex.valid && ex.cause == DEBUG_REQUEST) begin
                dpc_d = pc;
                debug_mode_d = 1'b1;
                csr_ctrl__set_debug_o = 1'b1;
                dcsr_d.cause = dbg_pkg::CauseRequest;
            end  
        end

        if(debug_mode_q && ex.valid && ex.cause == BREAKPOINT) begin
            csr_ctrl__set_debug_o = 1'b1;
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
        if(mret) begin
            csr_ctrl__eret_o = 1'b1; 
            mstatus_d.mie = mstatus_q.mpie;
            mstatus_d.mpie = 1'b1;         
            priv_lvl_d = mstatus_q.mpp;
            mstatus_d.mpp = PRIV_LVL_U;
        end
        if(sret) begin
            csr_ctrl__eret_o = 1'b1;
            mstatus_d.sie = mstatus_q.spie;
            mstatus_d.spie = 1'b1;
            priv_lvl_d = priv_lvl_t'({1'b0,mstatus_q.spp});
            mstatus_d.spp = 1'b0;
        end
        if(dret) begin
            csr_ctrl__eret_o = 1'b1;
            priv_lvl_d = priv_lvl_t'(dcsr_q.prv);
        end
    end
//======================================================================================================================
// CSR command generation logic
//======================================================================================================================
    always_comb begin: csr_cmd_gen
        csr_wdata = alu_csr__wdata_i;
        csr_we = 1'b0;
        csr_read = 1'b0;
        if(alu_csr__valid_i) begin
            csr_we = 1'b1;
            csr_read = 1'b1;
            case(alu_csr__cmd_i)
                LB_CMD_WR: begin
                    csr_wdata = alu_csr__wdata_i;
                end
                LB_CMD_SET: begin
                    csr_wdata = alu_csr__wdata_i | csr_rdata; 
                end
                LB_CMD_CLR: begin
                    csr_wdata = ~alu_csr__wdata_i & csr_rdata;
                end
                LB_CMD_READ: begin
                    csr_we = 1'b0; 
                end 
                default:;
            endcase
        end
        if(privilege_violation) begin
            csr_we = 1'b0; 
            csr_read = 1'b0;
        end
    end
//======================================================================================================================
// CSR privilege check
//======================================================================================================================
    always_comb begin: privilege_check
        privilege_violation = 1'b0;
        if(alu_csr__valid_i) begin
            if((csr_addr_decode.priv_lvl & priv_lvl_o) != csr_addr_decode.priv_lvl) begin
                privilege_violation = 1'b1; 
            end 
            if(alu_csr__addr_i[11:4] == 8'h7b && !debug_mode_q) begin
                privilege_violation = 1'b1; 
            end
        end        
    end
//======================================================================================================================
// Gen exception 
//======================================================================================================================
    always_comb begin: gen_ex
        ex.valid = 1'b0;
        ex.cause = '0;
        ex.tval = '0;
        pc = alu_csr__pc_i;
        if(update_access_exception || read_access_exception || privilege_violation) begin
            ex.valid = 1'b1;
            ex.cause = ILLEGAL_INSTR; 
            ex.tval = {32'b0, alu_csr__instr_i};
        end else if(alu_csr__ex_i.valid) begin
            ex = alu_csr__ex_i;
        end 
        // if(ex.valid) begin
        //     unique case(ex.cause)
        //         BREAKPOINT,ENV_CALL_MMODE,ENV_CALL_SMODE,ENV_CALL_UMODE: pc = alu_csr__pc_i;
        //         default: pc = alu_csr__pc_i;
        //     endcase
        // end
    end

//======================================================================================================================
// WFI CTRL
//======================================================================================================================
    // -------------------
    // Wait for Interrupt
    // -------------------
    always_comb begin : wfi_ctrl
        // wait for interrupt register
        wfi_d = wfi_q;
        // if there is any interrupt pending un-stall the core
        // also un-stall if we want to enter debug mode
        if (|mip_q || debug_req_i || irq_i[1]) begin
            wfi_d = 1'b0;
        // or alternatively if there is no exception pending and we are not in debug mode wait here
        // for the interrupt
        end else if (!debug_mode_q && alu_csr__wfi_i && !ex.valid) begin
            wfi_d = 1'b1;
        end
    end
//======================================================================================================================
// assignment
//======================================================================================================================
    assign mret = alu_csr__mret_i;
    assign sret = alu_csr__sret_i;
    assign dret = alu_csr__dret_i;

    assign csr_dec__irq_ctrl_o.mie = mie_q;
    assign csr_dec__irq_ctrl_o.mip = mip_q;
    assign csr_dec__irq_ctrl_o.sie = mstatus_q.sie;
    assign csr_dec__irq_ctrl_o.mideleg = mideleg_q;
    assign csr_dec__irq_ctrl_o.global_enable = !debug_mode_q & (~dcsr_q.step | dcsr_q.stepie)
                                                & ((mstatus_q.mie & (priv_lvl_o == PRIV_LVL_M)) | priv_lvl_o != PRIV_LVL_M);

    always_comb begin
       // When the SEIP bit is read with a CSRRW, CSRRS, or CSRRC instruction, the value
       // returned in the rd destination register contains the logical-OR of the software-writable
       // bit and the interrupt signal from the interrupt controller.
       csr_alu__rdata_o = csr_rdata;

       unique case (csr_addr)
           CSR_MIP: csr_alu__rdata_o = csr_rdata | (irq_i[1] << IRQ_S_EXT);
           // in supervisor mode we also need to check whether we delegated this bit
           CSR_SIP: begin
               csr_alu__rdata_o = csr_rdata | ((irq_i[1] & mideleg_q[IRQ_S_EXT]) << IRQ_S_EXT);
           end
           default:;
       endcase
    end

    // to ctrl module
    // assign csr_ctrl__wfi_wakeup_o = |mip_q || irq_i[1] || debug_req_i; 
    assign csr_ctrl__debug_mode_o = debug_mode_q;
    assign csr_ctrl__ex_valid_o = ex.valid;
    
    always_comb begin : gen_trap_vec
        csr_ctrl__trap_vec_o = {mtvec_q[63:2], 2'b0};
        if(trap_to_priv_lvl == PRIV_LVL_S) begin
            csr_ctrl__trap_vec_o = {stvec_q[63:2], 2'b0};
        end 
        if(debug_mode_q) begin
            csr_ctrl__trap_vec_o = SyDefaultConfig.DmBaseAddress + dbg_pkg::ExceptionAddress;
        end
        if((mtvec_q[0] || stvec_q[0]) && ex.cause[63]) begin
            csr_ctrl__trap_vec_o[7:2] = ex.cause[5:0];
        end
    end

    always_comb begin : gen_rtn_vec
        csr_ctrl__epc_o = mepc_q;
        if(sret) begin
            csr_ctrl__epc_o = sepc_q;
        end 
        if(dret) begin
            csr_ctrl__epc_o = dpc_q;
        end
    end

    // output some ctrl signals
    assign priv_lvl_o               = (debug_mode_q) ? PRIV_LVL_M : priv_lvl_q;
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
    assign icache_en_o              = icache_q[0] && (~debug_mode_q); 
    assign dcache_en_o              = dcache_q[0];
    assign mprv                     = (debug_mode_q && !dcsr_q.mprven) ? 1'b0 : mstatus_q.mprv;  

    assign fs_o = mstatus_q.fs;
    // assign fs_o = is_Dirty;

    assign debug_mode_o             = debug_mode_q;

    assign halt_o                   = wfi_q;
//======================================================================================================================
// registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            priv_lvl_q             <= PRIV_LVL_M;
            debug_mode_q           <= 1'b0;
            // floating-point registers
            fcsr_q                 <= 64'b0;
            // debug signals
            dcsr_q                 <= '0;
            dcsr_q.prv             <= PRIV_LVL_M;
            dpc_q                  <= 64'b0;
            dscratch0_q            <= 64'b0;
            dscratch1_q            <= 64'b0;
            // machine mode registers
            mstatus_q              <= 64'b0;
            // set to boot address + direct mode + 4 byte offset which is the initial trap
            mtvec_rst_load_q       <= 1'b1;
            mtvec_q                <= '0;
            medeleg_q              <= 64'b0;
            mideleg_q              <= 64'b0;
            mip_q                  <= 64'b0;
            mie_q                  <= 64'b0;
            mepc_q                 <= 64'b0;
            mcause_q               <= 64'b0;
            mscratch_q             <= 64'b0;
            mtval_q                <= 64'b0;
            dcache_q               <= 64'b1;
            icache_q               <= 64'b1;
            // supervisor mode registers
            sepc_q                 <= 64'b0;
            scause_q               <= 64'b0;
            stvec_q                <= 64'b0;
            sscratch_q             <= 64'b0;
            stval_q                <= 64'b0;
            satp_q                 <= 64'b0;
            // timer and counters
            cycle_q                <= 64'b0;
            instret_q              <= 64'b0;
            // aux registers
            en_ld_st_translation_q <= 1'b0;
            wfi_q                  <= 1'b0;
        end else begin
            priv_lvl_q             <= priv_lvl_d;
            debug_mode_q           <= debug_mode_d;
            // floating-point registers
            fcsr_q                 <= fcsr_d;
            // debug signals
            dcsr_q                 <= dcsr_d;
            dpc_q                  <= dpc_d;
            dscratch0_q            <= dscratch0_d;
            dscratch1_q            <= dscratch1_d;
            // machine mode registers
            mstatus_q              <= mstatus_d;
            mtvec_rst_load_q       <= 1'b0;
            mtvec_q                <= mtvec_d;
            medeleg_q              <= medeleg_d;
            mideleg_q              <= mideleg_d;
            mip_q                  <= mip_d;
            mie_q                  <= mie_d;
            mepc_q                 <= mepc_d;
            mcause_q               <= mcause_d;
            mscratch_q             <= mscratch_d;
            mtval_q                <= mtval_d;
            dcache_q               <= dcache_d;
            icache_q               <= icache_d;
            // supervisor mode registers
            sepc_q                 <= sepc_d;
            scause_q               <= scause_d;
            stvec_q                <= stvec_d;
            sscratch_q             <= sscratch_d;
            stval_q                <= stval_d;
            satp_q                 <= satp_d;
            // timer and counters
            cycle_q                <= cycle_d;
            instret_q              <= instret_d;
            // aux registers
            en_ld_st_translation_q <= en_ld_st_translation_d;
            // wait for interrupt
            wfi_q                  <= wfi_d;
        end 
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on

(* mark_debug = "true" *) logic prb_csr_wfi;
(* mark_debug = "true" *) logic prb_csr_wakeup;
(* mark_debug = "true" *) logic prb_csr_timer;
assign prb_csr_wfi = wfi_q;
assign prb_csr_wakeup = !wfi_q;
assign prb_csr_timer = timer_irq_i;

endmodule : sy_ppl_csr_regfile
