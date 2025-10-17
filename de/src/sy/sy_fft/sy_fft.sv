// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft.v
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

module sy_fft
    import fft_pkg::*;
#(
    parameter SOURCE = 0,
    parameter BASE_ADDR = 64'h4_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                                clk_i,           
    input  logic                                rst_i,           
    // TL bus, used to read/write regs
    TL_BUS.Master                               master,
    // Access Mem
    TL_BUS.Slave                                slave
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   flush;
    logic                                   ibuf_full;    

    logic                                   buf_ptr;
    logic                                   wt_buf_ptr;
    logic                                   bank_ptr;
    logic [IQ_WTH+1:0]                      iq_status;
    logic                                   ctrl_iq__vld;
    logic                                   iq_ctrl__rdy;
    iq_data_t                               ctrl_iq__data;

    logic                                   lsu_iq__awake_en;
    logic                                   lsu_iq__awake_rs2_en;
    logic                                   lsu_iq__awake_rs1_idx;
    logic                                   lsu_iq__awake_rs2_idx;
    logic [7:0]                             lsu_iq__awake_instr_idx;
    logic                                   exe_iq__awake_en;
    logic                                   exe_iq__awake_rs1_idx;
    logic                                   exe_iq__awake_rs2_idx;
    logic [7:0]                             exe_iq__awake_instr_idx;

    logic                                   iq_lsu__vld;
    logic                                   lsu_iq__rdy;
    lsu_data_t                              iq_lsu__data;
    logic                                   iq_exe__vld;
    logic                                   exe_iq__rdy;
    exe_data_t                              iq_exe__data;

    logic                                   lsu_wt_wr_en;
    logic[LM_ADDR_WTH-1:0]                  lsu_wt_addr;
    logic[63:0]                             lsu_wt_wr_data;            
    logic                                   lsu_lm_wr_en;        
    logic                                   lsu_lm_rd_en;        
    logic[LM_ADDR_WTH-1:0]                  lsu_lm_addr;         
    logic[1:0][63:0]                        lsu_lm_wr_data;      
    logic[1:0][63:0]                        lsu_lm_rd_data;

    logic                                   exe_lm_rd_en;       // Read valid signal 
    logic[1:0][LM_ADDR_WTH-1:0]             exe_lm_rd_addr;     // Read address 
    logic[1:0][63:0]                        exe_lm_rd_data;     // Read data 
    logic                                   exe_lm_wr_en;        // Write valid signal 
    logic[1:0][LM_ADDR_WTH-1:0]             exe_lm_wr_addr;      // Write address 
    logic[1:0][63:0]                        exe_lm_wr_data;      // Write data 
    logic                                   exe_wt_rd_en;       // Read valid signal 
    logic[LM_ADDR_WTH-1:0]                  exe_wt_rd_addr;     // Read address 
    logic[63:0]                             exe_wt_rd_data;    // Read data 
//======================================================================================================================
// Instance
//======================================================================================================================
    // not used
    assign slave.e_valid = '0;
    assign slave.e_bits = '0;
    assign slave.b_ready = '0;

    // Ctrl module
    sy_fft_ctrl fft_ctrl_inst(
        .clk_i              (clk_i),           
        .rst_i              (rst_i),           

        .master             (master), 
        .flush_o            (flush),
        // buf and bank pointer
        .buf_ptr_i          (buf_ptr),
        .wt_buf_ptr_i       (wt_buf_ptr),
        .bank_ptr_i         (bank_ptr),
        .iq_status_i        (iq_status),
        .lsu_status_i       (lsu_iq__rdy),
        .exe_status_i       (exe_iq__rdy),
        // insert instruction to IBUF
        .ctrl_iq__vld_o     (ctrl_iq__vld),
        .iq_ctrl__rdy_i     (iq_ctrl__rdy),
        .ctrl_iq__data_o    (ctrl_iq__data)
    );
    // Issue Queue
    sy_fft_iq fft_iq_inst (
        // =====================================
        // [clock & reset]
        // -- <clock>
        .clk_i              (clk_i),                      
        .rst_i              (rst_i),                      
        .flush_i            (flush),
        // to ctrl module
        .buf_ptr_o          (buf_ptr),
        .wt_buf_ptr_o       (wt_buf_ptr),
        .bank_ptr_o         (bank_ptr),
        .iq_status_o        (iq_status),

        .lsu_iq__awake_en_i         (lsu_iq__awake_en), 
        .lsu_iq__awake_rs2_en_i     (lsu_iq__awake_rs2_en),     
        .lsu_iq__awake_rs1_idx_i    (lsu_iq__awake_rs1_idx),      
        .lsu_iq__awake_rs2_idx_i    (lsu_iq__awake_rs2_idx),      
        .lsu_iq__awake_instr_idx_i  (lsu_iq__awake_instr_idx),        
        .exe_iq__awake_en_i         (exe_iq__awake_en), 
        .exe_iq__awake_rs1_idx_i    (exe_iq__awake_rs1_idx),      
        .exe_iq__awake_rs2_idx_i    (exe_iq__awake_rs2_idx),      
        .exe_iq__awake_instr_idx_i  (exe_iq__awake_instr_idx),        
   
        // =====================================
        // [From decode]
        .ctrl_iq__vld_i     (ctrl_iq__vld),          
        .iq_ctrl__rdy_o     (iq_ctrl__rdy),          
        .ctrl_iq__data_i    (ctrl_iq__data),
        // =====================================
        // [Issue]
        .iq_lsu__vld_o      (iq_lsu__vld ),
        .lsu_iq__rdy_i      (lsu_iq__rdy ),
        .iq_lsu__data_o     (iq_lsu__data),

        .iq_exe__vld_o      (iq_exe__vld),
        .exe_iq__rdy_i      (exe_iq__rdy),
        .iq_exe__data_o     (iq_exe__data)
    );
    sy_fft_lsu #(
        .SOURCE     (SOURCE)
    ) fft_lsu_inst(
        // clk rst and flush
        .clk_i              (clk_i  ),           
        .rst_i              (rst_i  ),          
        .flush_i            (flush  ),
        // =====================================
        // [instr from issue queue]
        .iq_lsu__vld_i      (iq_lsu__vld),
        .lsu_iq__rdy_o      (lsu_iq__rdy),
        .iq_lsu__data_i     (iq_lsu__data),

        .lsu_iq__awake_en_o         (lsu_iq__awake_en),           
        .lsu_iq__awake_rs2_en_o     (lsu_iq__awake_rs2_en),     
        .lsu_iq__awake_rs1_idx_o    (lsu_iq__awake_rs1_idx),      
        .lsu_iq__awake_rs2_idx_o    (lsu_iq__awake_rs2_idx),      
        .lsu_iq__awake_instr_idx_o  (lsu_iq__awake_instr_idx),        
        // =====================================
        // [TileLink Interface]
        // A channel
        .lsu_A_valid_o      (slave.a_valid),
        .lsu_A_ready_i      (slave.a_ready),
        .lsu_A_bits_o       (slave.a_bits),
        // C channel
        .lsu_C_valid_o      (slave.c_valid),
        .lsu_C_ready_i      (slave.c_ready),
        .lsu_C_bits_o       (slave.c_bits),
        // D channel
        .lsu_D_valid_i      (slave.d_valid),
        .lsu_D_ready_o      (slave.d_ready),
        .lsu_D_bits_i       (slave.d_bits),           
        // =====================================
        // [Interface with weight ram]
        .lsu_wt_wr_en_o     (lsu_wt_wr_en),
        .lsu_wt_addr_o      (lsu_wt_addr ),
        .lsu_wt_wr_data_o   (lsu_wt_wr_data),            
        // =====================================
        // [Interface with local mem]
        .lsu_lm_wr_en_o     (lsu_lm_wr_en),        
        .lsu_lm_rd_en_o     (lsu_lm_rd_en),        
        .lsu_lm_addr_o      (lsu_lm_addr ),         
        .lsu_lm_wr_data_o   (lsu_lm_wr_data),      
        .lsu_lm_rd_data_i   (lsu_lm_rd_data)   
    );

    sy_fft_exe fft_exe_inst(
        .clk_i              (clk_i  ),           
        .rst_i              (rst_i  ),           
        .flush_i            (flush  ),
        // from issue queue
        .iq_exe__vld_i      (iq_exe__vld ),
        .exe_iq__rdy_o      (exe_iq__rdy ),
        .iq_exe__data_i     (iq_exe__data),
        // free buf
        .exe_iq__awake_en_o         (exe_iq__awake_en), 
        .exe_iq__awake_rs1_idx_o    (exe_iq__awake_rs1_idx),    
        .exe_iq__awake_rs2_idx_o    (exe_iq__awake_rs2_idx),    
        .exe_iq__awake_instr_idx_o  (exe_iq__awake_instr_idx),      
        // interface with lm
        .exe_lm_rd_en_o     (exe_lm_rd_en  ),       // Read valid signal 
        .exe_lm_rd_addr_o   (exe_lm_rd_addr),     // Read address 
        .exe_lm_rd_data_i   (exe_lm_rd_data),     // Read data 

        .exe_lm_wr_en_o     (exe_lm_wr_en  ),        // Write valid signal 
        .exe_lm_wr_addr_o   (exe_lm_wr_addr),      // Write address 
        .exe_lm_wr_data_o   (exe_lm_wr_data),      // Write data 
        // interface with wt
        .exe_wt_rd_en_o     (exe_wt_rd_en  ),     // Read valid signal 
        .exe_wt_rd_addr_o   (exe_wt_rd_addr),     // Read address 
        .exe_wt_rd_data_i   (exe_wt_rd_data)      // Read data 
    );

    sy_fft_lm fft_lm_inst(
        .clk_i              (clk_i),           
        .rst_i              (rst_i),           
        // =====================================
        // -- exe read port
        .exe_lm_rd_en_i     (exe_lm_rd_en  ),       // Read valid signal 
        .exe_lm_rd_addr_i   (exe_lm_rd_addr),     // Read address 
        .exe_lm_rd_data_o   (exe_lm_rd_data),     // Read data 
        // -- exe write port
        .exe_lm_wr_en_i     (exe_lm_wr_en  ),        // Write valid signal 
        .exe_lm_wr_addr_i   (exe_lm_wr_addr),      // Write address 
        .exe_lm_wr_data_i   (exe_lm_wr_data),      // Write data 
        // -- lsu 
        .lsu_lm_wr_en_i     (lsu_lm_wr_en  ),        // Write valid signal 
        .lsu_lm_rd_en_i     (lsu_lm_rd_en  ),        // Read valid signal 
        .lsu_lm_addr_i      (lsu_lm_addr   ),         // Write address 
        .lsu_lm_wr_data_i   (lsu_lm_wr_data),      // Write data 
        .lsu_lm_rd_data_o   (lsu_lm_rd_data)    // Read data 
    );

    sy_fft_wt wt_inst(
        .clk_i              (clk_i),           
        .rst_i              (rst_i),           
        // =====================================
        // -- exe read port
        .exe_wt_rd_en_i     (exe_wt_rd_en  ),       // Read valid signal 
        .exe_wt_rd_addr_i   (exe_wt_rd_addr),     // Read address 
        .exe_wt_rd_data_o   (exe_wt_rd_data),     // Read data 
        // -- lsu 
        .lsu_wt_wr_en_i     (lsu_wt_wr_en  ),        // Write valid signal 
        .lsu_wt_addr_i      (lsu_wt_addr   ),         // Write address 
        .lsu_wt_wr_data_i   (lsu_wt_wr_data)    // Write data 
    );

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule 