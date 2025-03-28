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

    TL_BUS.Master                       master
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

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus (clk_i);

//======================================================================================================================
// Instance
//======================================================================================================================
    TL2APB #(
        .APB_ADDR_WIDTH (ADDR_WIDTH),
        .APB_DATA_WIDTH (DATA_WIDTH)
    ) tl_2_apb_inst(
        .clk_i          (clk_i),           
        .rst_i          (rst_i),           

        .TL_A_valid_i   (master.a_valid),                   
        .TL_A_ready_o   (master.a_ready),                   
        .TL_A_bits_i    (master.a_bits),                 

        .TL_D_valid_o   (master.d_valid),                   
        .TL_D_ready_i   (master.d_ready),                   
        .TL_D_bits_o    (master.d_bits),                 

        .penable_o      (plic_penable ),               
        .pwrite_o       (plic_pwrite  ),              
        .paddr_o        (plic_paddr   ),             
        .psel_o         (plic_psel    ),            
        .pwdata_o       (plic_pwdata  ),              
        .prdata_i       (plic_prdata  ),              
        .pready_i       (plic_pready  ),              
        .pslverr_i      (plic_pslverr )
    );

    apb_to_reg i_apb_to_reg (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_i        ),
        .penable_i ( plic_penable ),
        .pwrite_i  ( plic_pwrite  ),
        .paddr_i   ( plic_paddr   ),
        .psel_i    ( plic_psel    ),
        .pwdata_i  ( plic_pwdata  ),
        .prdata_o  ( plic_prdata  ),
        .pready_o  ( plic_pready  ),
        .pslverr_o ( plic_pslverr ),
        .reg_o     ( reg_bus      )
    );

    reg_intf::reg_intf_resp_d32 plic_resp;
    reg_intf::reg_intf_req_a32_d32 plic_req;

    assign plic_req.addr  = reg_bus.addr;
    assign plic_req.write = reg_bus.write;
    assign plic_req.wdata = reg_bus.wdata;
    assign plic_req.wstrb = reg_bus.wstrb;
    assign plic_req.valid = reg_bus.valid;

    assign reg_bus.rdata = plic_resp.rdata;
    assign reg_bus.error = plic_resp.error;
    assign reg_bus.ready = plic_resp.ready;

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
