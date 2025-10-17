// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : fft_pkg.sv 
// DEPARTMENT : CAG of IAIR
// AUTHOR     : 
// AUTHOR'S EMAIL :
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

package fft_pkg;
    parameter ARC_BANK_NUM = 2;
    parameter ARC_BANK_WTH = $clog2(ARC_BANK_NUM);
    parameter BANK_NUM = 4;
    parameter BANK_WTH = $clog2(BANK_NUM);
    parameter WT_BANK_NUM = 2;
    parameter WT_BANK_WTH = $clog2(WT_BANK_NUM);
    parameter WT_BWTH = WT_BANK_WTH;

    parameter LM_AWTH = 9;
    parameter LM_DWTH = 3;                            // Bits of OCM data width
    parameter LM_BWTH = $clog2(BANK_NUM);             // Bits of OCM bank
    parameter LM_ADDR_WTH = LM_AWTH + LM_DWTH + LM_BWTH;

    parameter IQ_LEN = 16;   
    parameter IQ_WTH = $clog2(IQ_LEN);   

    parameter logic [10:0] MAX_LEN = 11'h400;  // 1024 elements
    parameter logic [3:0]  MAX_LEVEL = 4'd10;

    typedef enum logic[1:0] {  
        LOAD,
        STORE,
        EXE,
        FENCE
    } fft_op_e;

    typedef struct packed {
        fft_op_e                op;
        logic                   mode;
        logic                   load_wt;
        logic                   is_lds;
        logic [3:0]             tot_level;  
        logic [3:0]             cur_level;  
        logic [47:0]            addr;    
        logic [15:0]            reverse_base;
        logic [LM_AWTH-1:0]     rd_ocm_addr;    
        logic [LM_AWTH-1:0]     wr_ocm_addr; 
        logic [31:0]            stride; 
        logic                   rs1_idx;     
        logic                   rs2_idx;     
        logic                   rdst_idx;
        logic                   bank_idx;
        logic                   rs1_vld;
        logic                   rs2_vld;
        logic                   rdst_vld;
        logic [7:0]             instr_idx;     
    } iq_data_t;

    typedef struct packed {
        logic                       is_load;       
        logic                       load_wt;
        logic [3:0]                 tot_level;
        logic [10:0]                len;
        logic                       buf_idx;    
        logic                       wt_buf_idx;
        logic                       bank_idx; 
        logic [63:0]                base_addr;
        logic [LM_AWTH-1:0]         rd_ocm_addr;
        logic [LM_AWTH-1:0]         wr_ocm_addr;
        logic [31:0]                stride;
        logic                       mode; // 0 for reverse, 1 for increment
        logic [7:0]                 instr_idx;  
        logic [15:0]                reverse_base;
    } lsu_data_t;

    typedef struct packed {
        logic                       mode;// 0 for reverse, 1 for normal 
        logic [3:0]                 cur_level;
        logic [3:0]                 tot_level;
        logic                       buf_idx;    
        logic                       wt_buf_idx;
        logic                       bank_idx; 
        logic [10:0]                len;                   
        logic [LM_AWTH-1:0]         rd_ocm_addr;
        logic [LM_AWTH-1:0]         wr_ocm_addr;
        logic [7:0]                 instr_idx;
        logic                       beyond_max_level;
    } exe_data_t;


endpackage
