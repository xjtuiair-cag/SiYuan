// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19/04/2017
// Description: Memory Management Unit for Ariane, contains TLB and
//              address translation unit. SV39 as defined in RISC-V
//              privilege specification 1.11-WIP


module cva6_mmu 
    import sy_pkg::*;
#(
      parameter int unsigned INSTR_TLB_ENTRIES     = 4,
      parameter int unsigned DATA_TLB_ENTRIES      = 4,
      parameter int unsigned ASID_WIDTH            = 1,
      parameter sy_cfg_t Cfg = SyDefaultConfig
) (
        input  logic                            clk_i,
        input  logic                            rst_ni,
        input  logic                            flush_i,

        input  logic                            exe_region_ex_en_i,
        input  logic                            enable_translation_i,
        input  logic                            en_ld_st_translation_i,   // enable virtual memory translation for load/stores

        output logic                            ptw_instr_active_o,
        // IF interface
        input  logic                            fet_req_i,
        input  logic [63:0]                     fet_vaddr_i,
        output logic                            fet_itlb_hit_o,
        output logic                            fet_valid_o,
        output logic [63:0]                     fet_paddr_o,            
        output exception_t                      fet_exception_o,
        // LSU interface
        // this is a more minimalistic interface because the actual addressing logic is handled
        // in the LSU as we distinguish load and stores, what we do here is simple address translation
        input  exception_t                      misaligned_ex_i,
        input  logic                            lsu_req_i,        // request address translation
        input  logic [63:0]                     lsu_vaddr_i,      // virtual address in
        input  logic                            lsu_is_store_i,   // the translation is requested by a store
        // if we need to walk the page table we can't grant in the same cycle
        // Cycle 0
        output logic                            lsu_dtlb_hit_o,   // sent in the same cycle as the request if translation hits in the DTLB
        // Cycle 1
        output logic                            lsu_valid_o,      // translation is valid
        output logic [63:0]                     lsu_paddr_o,      // translated address
        output exception_t                      lsu_exception_o,  // address translation threw an exception
        // General control signals
        input priv_lvl_t                        priv_lvl_i,
        input priv_lvl_t                        ld_st_priv_lvl_i,
        input logic                             sum_i,
        input logic                             mxr_i,
        // input logic flag_mprv_i,
        input logic [43:0]                      satp_ppn_i,
        input logic [ASID_WIDTH-1:0]            asid_i,
        input logic                             flush_tlb_i,
        // Performance counters
        output logic                            itlb_miss_o,
        output logic                            dtlb_miss_o,
        // PTW memory interface
        input  logic                            dmem_mmu__ctrl_idle_i,
        output logic                            mmu_dmem__req_o,
        input  logic                            dmem_mmu__rsp_i,
        output dcache_req_t                     mmu_dmem__req_bits_o,
        input  dcache_rsp_t                     dmem_mmu__rsp_bits_i  
);

    logic        iaccess_err;   // insufficient privilege to access this instruction page
    logic        daccess_err;   // insufficient privilege to access this data page
    logic        ptw_active;    // PTW is currently walking a page table
    logic        walking_instr; // PTW is walking because of an ITLB miss
    logic        ptw_error;     // PTW threw an exception

    logic [38:0] update_vaddr;
    tlb_update_t update_ptw_itlb, update_ptw_dtlb;

    logic        itlb_lu_access;
    pte_t        itlb_content;
    logic        itlb_is_2M;
    logic        itlb_is_1G;
    logic        itlb_lu_hit;

    logic        dtlb_lu_access;
    pte_t        dtlb_content;
    logic        dtlb_is_2M;
    logic        dtlb_is_1G;
    logic        dtlb_lu_hit;
    logic        ptw_instr_error_dly;
    // Assignments
    assign itlb_lu_access = fet_req_i;
    assign dtlb_lu_access = lsu_req_i;

    cva6_tlb #(
        .TLB_ENTRIES      ( INSTR_TLB_ENTRIES          ),
        .ASID_WIDTH       ( ASID_WIDTH                 )
    ) i_itlb (
        .clk_i            ( clk_i                      ),
        .rst_ni           ( rst_ni                     ),
        .flush_i          ( flush_tlb_i                ),

        .update_i         ( update_ptw_itlb            ),

        .lu_access_i      ( itlb_lu_access             ),
        .lu_asid_i        ( asid_i                     ),
        .lu_vaddr_i       ( fet_vaddr_i                ),        
        .lu_content_o     ( itlb_content               ),

        .lu_is_2M_o       ( itlb_is_2M                 ),
        .lu_is_1G_o       ( itlb_is_1G                 ),
        .lu_hit_o         ( itlb_lu_hit                )
    );

    cva6_tlb #(
        .TLB_ENTRIES     ( DATA_TLB_ENTRIES             ),
        .ASID_WIDTH      ( ASID_WIDTH                   )
    ) i_dtlb (
        .clk_i            ( clk_i                       ),
        .rst_ni           ( rst_ni                      ),
        .flush_i          ( flush_tlb_i                 ),

        .update_i         ( update_ptw_dtlb             ),

        .lu_access_i      ( dtlb_lu_access              ),
        .lu_asid_i        ( asid_i                      ),
        .lu_vaddr_i       ( lsu_vaddr_i                 ),
        .lu_content_o     ( dtlb_content                ),

        .lu_is_2M_o       ( dtlb_is_2M                  ),
        .lu_is_1G_o       ( dtlb_is_1G                  ),
        .lu_hit_o         ( dtlb_lu_hit                 )
    );


    cva6_ptw  #(
        .ASID_WIDTH             ( ASID_WIDTH            )
    ) i_ptw (
        .clk_i                  ( clk_i                 ),
        .rst_ni                 ( rst_ni                ),
        .flush_i                ( flush_i               ),
        .ptw_active_o           ( ptw_active            ),
        .walking_instr_o        ( walking_instr         ),
        .ptw_error_o            ( ptw_error             ),
        .enable_translation_i   ( enable_translation_i  ),

        .update_vaddr_o         ( update_vaddr          ),
        .itlb_update_o          ( update_ptw_itlb       ),
        .dtlb_update_o          ( update_ptw_dtlb       ),

        .itlb_access_i          ( itlb_lu_access        ),
        .itlb_hit_i             ( itlb_lu_hit           ),
        .itlb_vaddr_i           ( fet_vaddr_i           ),

        .dtlb_access_i          ( dtlb_lu_access        ),
        .dtlb_hit_i             ( dtlb_lu_hit           ),
        .dtlb_vaddr_i           ( lsu_vaddr_i           ),

        .dmem_mmu__ctrl_idle_i  (dmem_mmu__ctrl_idle_i),
        .mmu_dmem__req_o        (mmu_dmem__req_o     ),
        .dmem_mmu__rsp_i        (dmem_mmu__rsp_i     ),
        .mmu_dmem__req_bits_o   (mmu_dmem__req_bits_o),
        .dmem_mmu__rsp_bits_i   (dmem_mmu__rsp_bits_i),  
        .*
     );

    assign fet_itlb_hit_o = (enable_translation_i) ? itlb_lu_hit :  1'b1;
    assign ptw_instr_active_o = ptw_active && walking_instr;
    //-----------------------
    // Instruction Interface
    //-----------------------
    logic match_any_execute_region;
    logic         fet_valid_n;
    // logic [63:0]  fet_paddr_n;            
    exception_t   fet_exception_n;
 
    // The instruction interface is a simple request response interface
    always_comb begin : instr_interface
        // MMU disabled: just pass through
        fet_valid_n = fet_req_i;
        // fet_paddr_n = fet_vaddr_i; // play through in case we disabled address translation
        fet_paddr_o = fet_vaddr_i; // play through in case we disabled address translation
        // two potential exception sources:
        // 1. HPTW threw an exception -> signal with a page fault exception
        // 2. We got an access error because of insufficient permissions -> throw an access exception
        fet_exception_n = '0;
        // Check whether we are allowed to access this memory region from a fetch perspective
        iaccess_err   = fet_req_i && (((priv_lvl_i == PRIV_LVL_U) && ~itlb_content.u)
                                                 || ((priv_lvl_i == PRIV_LVL_S) && itlb_content.u));

        // MMU enabled: address from TLB, request delayed until hit. Error when TLB
        // hit and no access right or TLB hit and translated address not valid (e.g.
        // AXI decode error), or when PTW performs walk due to ITLB miss and raises
        // an error.
        if (enable_translation_i) begin
            // we work with SV39, so if VM is enabled, check that all bits [63:38] are equal
            if (fet_req_i && !((&fet_vaddr_i[63:38]) == 1'b1 || (|fet_vaddr_i[63:38]) == 1'b0)) begin
                fet_exception_n = {INSTR_ACCESS_FAULT, fet_vaddr_i, 1'b1};
            end

            fet_valid_n = 1'b0;

            // 4K page
            // fet_paddr_n = {itlb_content.ppn, fet_vaddr_i[11:0]};
            fet_paddr_o = {itlb_content.ppn, fet_vaddr_i[11:0]};
            // Mega page
            if (itlb_is_2M) begin
                // fet_paddr_n[20:12] = fet_vaddr_i[20:12];
                fet_paddr_o[20:12] = fet_vaddr_i[20:12];
            end
            // Giga page
            if (itlb_is_1G) begin
                // fet_paddr_n[29:12] = fet_vaddr_i[29:12];
                fet_paddr_o[29:12] = fet_vaddr_i[29:12];
            end

            // ---------
            // ITLB Hit
            // --------
            // if we hit the ITLB output the request signal immediately
            if (itlb_lu_hit) begin
                fet_valid_n = fet_req_i;
                // we got an access error
                if (iaccess_err) begin
                    // throw a page fault
                    fet_exception_n = {INSTR_PAGE_FAULT, fet_vaddr_i, 1'b1};
                end
            // ---------
            // ITLB Miss
            // ---------
            // watch out for exceptions happening during walking the page table
            end else if (ptw_active && walking_instr) begin
                // fet_valid_n = ptw_error;
                if (ptw_error) begin
                    fet_valid_n = fet_req_i;
                    fet_exception_n = {INSTR_PAGE_FAULT, {25'b0, update_vaddr}, 1'b1};
                end
            end
        end
        // // if it didn't match any execute region throw an `Instruction Access Fault`
        if (!match_any_execute_region && exe_region_ex_en_i) begin
          fet_exception_n = {INSTR_ACCESS_FAULT, fet_paddr_o, 1'b1};
        end
    end

    // check for execute flag on memory
    // assign match_any_execute_region = is_inside_execute_regions(Cfg, fet_paddr_n);
    assign match_any_execute_region = is_inside_execute_regions(Cfg, fet_paddr_o);

    //-----------------------
    // Data Interface
    //-----------------------
    logic [63:0] lsu_vaddr_n,     lsu_vaddr_q;
    pte_t dtlb_pte_n,      dtlb_pte_q;
    exception_t  misaligned_ex_n, misaligned_ex_q;
    logic        lsu_req_n,       lsu_req_q;
    logic        lsu_is_store_n,  lsu_is_store_q;
    logic        dtlb_hit_n,      dtlb_hit_q;
    logic        dtlb_is_2M_n,    dtlb_is_2M_q;
    logic        dtlb_is_1G_n,    dtlb_is_1G_q;
    logic [63:0] lsu_paddr_n;

    // check if we need to do translation or if we are always ready (e.g.: we are not translating anything)
    assign lsu_dtlb_hit_o = (en_ld_st_translation_i) ? dtlb_lu_hit :  1'b1;

    // always_comb begin
    //     lsu_paddr_n = lsu_vaddr_i;
    //     if (en_ld_st_translation_i) begin
    //         // 4K page
    //         lsu_paddr_n = {dtlb_content.ppn, lsu_vaddr_i[11:0]};
    //         // Mega page
    //         if (dtlb_is_2M_n) begin
    //           lsu_paddr_n[20:12] = lsu_vaddr_i[20:12];
    //         end
    //         // Giga page
    //         if (dtlb_is_1G_n) begin
    //             // lsu_paddr_o[29:12] = lsu_vaddr_q[29:12];
    //             lsu_paddr_n[29:12] = lsu_vaddr_i[29:12];
    //         end
    //     end
    // end
    // The data interface is simpler and only consists of a request/response interface
    always_comb begin : data_interface
        // save request and DTLB response
        lsu_vaddr_n           = lsu_vaddr_i;
        lsu_req_n             = lsu_req_i;
        misaligned_ex_n       = misaligned_ex_i;
        dtlb_pte_n            = dtlb_content;
        dtlb_hit_n            = dtlb_lu_hit;
        lsu_is_store_n        = lsu_is_store_i;
        dtlb_is_2M_n          = dtlb_is_2M;
        dtlb_is_1G_n          = dtlb_is_1G;

        // lsu_paddr_o           = lsu_vaddr_q;
        // lsu_paddr_n           = lsu_vaddr_n;
        lsu_paddr_o           = lsu_vaddr_n;
        lsu_valid_o           = lsu_req_q;
        lsu_exception_o       = misaligned_ex_q;
        // mute misaligned exceptions if there is no request otherwise they will throw accidental exceptions
        misaligned_ex_n.valid = misaligned_ex_i.valid & lsu_req_i;

        // Check if the User flag is set, then we may only access it in supervisor mode
        // if SUM is enabled
        daccess_err = (ld_st_priv_lvl_i == PRIV_LVL_S && !sum_i && dtlb_pte_q.u) || // SUM is not set and we are trying to access a user page in supervisor mode
                      (ld_st_priv_lvl_i == PRIV_LVL_U && !dtlb_pte_q.u);            // this is not a user page but we are in user mode and trying to access it
        // translation is enabled and no misaligned exception occurred
        if (en_ld_st_translation_i && !misaligned_ex_q.valid) begin
            lsu_valid_o = 1'b0;
            // 4K page
            // lsu_paddr_o = {dtlb_pte_q.ppn, lsu_vaddr_q[11:0]};
            // lsu_paddr_n = {dtlb_pte_n.ppn, lsu_vaddr_n[11:0]};
            lsu_paddr_o = {dtlb_pte_n.ppn, lsu_vaddr_n[11:0]};
            // Mega page
            // if (dtlb_is_2M_q) begin
            if (dtlb_is_2M_n) begin
            //   lsu_paddr_o[20:12] = lsu_vaddr_q[20:12];
            //   lsu_paddr_n[20:12] = lsu_vaddr_n[20:12];
              lsu_paddr_o[20:12] = lsu_vaddr_n[20:12];
            end
            // Giga page
            // if (dtlb_is_1G_q) begin
            if (dtlb_is_1G_n) begin
                // lsu_paddr_o[29:12] = lsu_vaddr_q[29:12];
                // lsu_paddr_n[29:12] = lsu_vaddr_n[29:12];
                lsu_paddr_o[29:12] = lsu_vaddr_n[29:12];
            end
            // ---------
            // DTLB Hit
            // --------
            if (dtlb_hit_q && lsu_req_q) begin
                lsu_valid_o = 1'b1;
                // this is a store
                if (lsu_is_store_q) begin
                    // check if the page is write-able and we are not violating privileges
                    // also check if the dirty flag is set
                    if (!dtlb_pte_q.w || daccess_err || !dtlb_pte_q.d) begin
                        lsu_exception_o = {STORE_PAGE_FAULT, lsu_vaddr_q, 1'b1};
                    end

                // this is a load, check for sufficient access privileges - throw a page fault if necessary
                end else if (daccess_err) begin
                    lsu_exception_o = {LOAD_PAGE_FAULT, lsu_vaddr_q, 1'b1};
                end
            end else

            // ---------
            // DTLB Miss
            // ---------
            // watch out for exceptions
            if (ptw_active && !walking_instr) begin
                // page table walker threw an exception
                if (ptw_error) begin
                    // an error makes the translation valid
                    lsu_valid_o = 1'b1;
                    // the page table walker can only throw page faults
                    if (lsu_is_store_q) begin
                        lsu_exception_o = {STORE_PAGE_FAULT, {25'b0, update_vaddr}, 1'b1};
                    end else begin
                        lsu_exception_o = {LOAD_PAGE_FAULT, {25'b0, update_vaddr}, 1'b1};
                    end
                end
            end
        end
    end
    // ----------
    // Registers
    // ----------
    always_ff @(`DFF_CR(clk_i,rst_ni)) begin
        if (`DFF_IS_R(rst_ni)) begin
            lsu_vaddr_q      <= `TCQ '0;
            lsu_req_q        <= `TCQ '0;
            misaligned_ex_q  <= `TCQ '0;
            dtlb_pte_q       <= `TCQ '0;
            dtlb_hit_q       <= `TCQ '0;
            lsu_is_store_q   <= `TCQ '0;
            dtlb_is_2M_q     <= `TCQ '0;
            dtlb_is_1G_q     <= `TCQ '0;
            // lsu_paddr_o      <= '0;
            fet_valid_o      <= `TCQ 1'b0;
            // fet_paddr_o      <= 64'b0;            
            fet_exception_o  <= `TCQ exception_t'(0);
        end else begin
            lsu_vaddr_q      <=  `TCQ lsu_vaddr_n;
            lsu_req_q        <=  `TCQ lsu_req_n;
            misaligned_ex_q  <=  `TCQ misaligned_ex_n;
            dtlb_pte_q       <=  `TCQ dtlb_pte_n;
            dtlb_hit_q       <=  `TCQ dtlb_hit_n;
            lsu_is_store_q   <=  `TCQ lsu_is_store_n;
            dtlb_is_2M_q     <=  `TCQ dtlb_is_2M_n;
            dtlb_is_1G_q     <=  `TCQ dtlb_is_1G_n;
            // lsu_paddr_o      <=  lsu_paddr_n;
            fet_valid_o      <=  `TCQ fet_valid_n;
            // fet_paddr_o      <=  fet_paddr_n;            
            fet_exception_o  <=  `TCQ fet_exception_n;
        end
    end

endmodule