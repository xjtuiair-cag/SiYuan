// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_plic.v
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

module sy_plic #(
    parameter int unsigned ADDR_WIDTH   = 32,
    parameter int unsigned DATA_WIDTH   = 32,
    parameter int unsigned MAX_PRI      = 7,
    parameter int unsigned SOURCE_NUM   = 30,
    parameter int unsigned TARGET_NUM   = 2
) (
    input  logic                        clk_i,       
    input  logic                        rst_i,      

    input  logic [SOURCE_NUM-1:0]       irq_sources_i,
    output logic [TARGET_NUM-1:0]       irq_target_o,
    // used to read/write register
    // A Channel
    input  logic                        inp_tl_A_valid_i,
    output logic                        inp_tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t        inp_tl_A_bits_i,
    // B Channel
    output logic                        inp_tl_B_valid_o,
    input  logic                        inp_tl_B_ready_i,
    output tl_pkg::B_chan_bits_t        inp_tl_B_bits_o,
    // C Channel
    input  logic                        inp_tl_C_valid_i,
    output logic                        inp_tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t        inp_tl_C_bits_i,
    // D Channel
    output logic                        inp_tl_D_valid_o,
    input  logic                        inp_tl_D_ready_i,
    output tl_pkg::D_chan_bits_t        inp_tl_D_bits_o,
    // E Channel
    input  logic                        inp_tl_E_valid_i,
    output logic                        inp_tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t        inp_tl_E_bits_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic         plic_penable;
    logic         plic_pwrite;
    logic [31:0]  plic_paddr;
    logic         plic_psel;
    logic [31:0]  plic_pwdata;
    logic [31:0]  plic_prdata;
    logic         plic_pready;
    logic         plic_pslverr;
    sy_pkg::reg_intf_resp_d32       plic_resp;
    sy_pkg::reg_intf_req_a32_d32    plic_req;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;
    TL2APB #(
        .APB_ADDR_WIDTH (ADDR_WIDTH),
        .APB_DATA_WIDTH (DATA_WIDTH)
    ) tl_2_apb_inst(
        .clk_i          (clk_i),           
        .rst_i          (rst_i),           

        .TL_A_valid_i   (inp_tl_A_valid_i),                   
        .TL_A_ready_o   (inp_tl_A_ready_o),                   
        .TL_A_bits_i    (inp_tl_A_bits_i ),                 

        .TL_D_valid_o   (inp_tl_D_valid_o),                   
        .TL_D_ready_i   (inp_tl_D_ready_i),                   
        .TL_D_bits_o    (inp_tl_D_bits_o ),                 

        .penable_o      (plic_penable ),               
        .pwrite_o       (plic_pwrite  ),              
        .paddr_o        (plic_paddr   ),             
        .psel_o         (plic_psel    ),            
        .pwdata_o       (plic_pwdata  ),              
        .prdata_i       (plic_prdata  ),              
        .pready_i       (plic_pready  ),              
        .pslverr_i      (plic_pslverr )
    );

    assign plic_req.addr  = plic_paddr;
    assign plic_req.write = plic_pwrite;
    assign plic_req.wdata = plic_pwdata;
    assign plic_req.wstrb = 4'hF;
    assign plic_req.valid = plic_penable && plic_psel;

    assign plic_prdata  = plic_resp.rdata;
    assign plic_pslverr = plic_resp.error;
    assign plic_pready  = plic_resp.ready;

    plic_top #(
      .N_SOURCE    ( SOURCE_NUM),
      .N_TARGET    ( TARGET_NUM),
      .MAX_PRIO    ( MAX_PRI)
    ) i_plic (
      .clk_i,
      .rst_ni        ( rst_i        ),
      .req_i         ( plic_req     ),
      .resp_o        ( plic_resp    ),
      .le_i          ( '0           ), // 0:level 1:edge
      .irq_sources_i ( irq_sources_i),
      .eip_targets_o ( irq_target_o )
    );

endmodule
