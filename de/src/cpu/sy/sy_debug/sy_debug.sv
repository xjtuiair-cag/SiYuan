// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_debug.v
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

module sy_debug
    import sy_pkg::*;
# (
    parameter HART_NUM = 1,
    parameter SOURCE = 0
)(
    input  logic                        clk_i,  // system clock     
    input  logic                        rst_i,  // system reset     
    // reset cpu
    input  logic                        cpu_rst_n,
    // JTAG interface
    input  logic                        tck,
    input  logic                        tms,
    input  logic                        trst_n,
    input  logic                        tdi,
    output logic                        tdo,        
    // reset
    output logic                        ndmreset,
    output logic[HART_NUM-1:0]          debug_req_irq,
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
    input  tl_pkg::E_chan_bits_t        inp_tl_E_bits_i,
    // used to access system bus
    // A Channel
    output logic                        oup_tl_A_valid_o,
    input  logic                        oup_tl_A_ready_i,
    output tl_pkg::A_chan_bits_t        oup_tl_A_bits_o,
    // B Channel
    input  logic                        oup_tl_B_valid_i,
    output logic                        oup_tl_B_ready_o,
    input  tl_pkg::B_chan_bits_t        oup_tl_B_bits_i,
    // C Channel
    output logic                        oup_tl_C_valid_o,
    input  logic                        oup_tl_C_ready_i,
    output tl_pkg::C_chan_bits_t        oup_tl_C_bits_o,
    // D Channel
    input  logic                        oup_tl_D_valid_i,
    output logic                        oup_tl_D_ready_o,
    input  tl_pkg::D_chan_bits_t        oup_tl_D_bits_i,
    // E Channel
    output logic                        oup_tl_E_valid_o,
    input  logic                        oup_tl_E_ready_i,
    output tl_pkg::E_chan_bits_t        oup_tl_E_bits_o

);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic                           debug_req_valid;
    logic                           debug_req_ready;
    dm::dmi_req_t                   debug_req;
    logic                           debug_resp_valid;
    logic                           debug_resp_ready;
    dm::dmi_resp_t                  debug_resp;

    logic                           dm_slave_en;
    logic                           dm_slave_we;
    logic [63:0]                    dm_slave_rdata;
    logic [63:0]                    dm_slave_addr;
    logic [63:0]                    dm_slave_wdata;
    logic [7:0]                     dm_slave_be;               

    logic                           dm_master_req;
    logic [64-1:0]                  dm_master_add;
    logic                           dm_master_we;
    logic [64-1:0]                  dm_master_wdata;
    logic [64/8-1:0]                dm_master_be;
    logic                           dm_master_gnt;
    logic                           dm_master_r_valid;
    logic [64-1:0]                  dm_master_r_rdata;
    logic                           dmactive;
//======================================================================================================================
// Instance
//======================================================================================================================
    // debug module interface
    dmi_jtag i_dmi_jtag (
        .clk_i                ( clk_i                ),
        .rst_ni               ( rst_i                ),
        .dmi_rst_no           (                      ), // keep open
        .testmode_i           ( 1'b0                 ),
        .dmi_req_valid_o      ( debug_req_valid      ),
        .dmi_req_ready_i      ( debug_req_ready      ),
        .dmi_req_o            ( debug_req            ),
        .dmi_resp_valid_i     ( debug_resp_valid     ),
        .dmi_resp_ready_o     ( debug_resp_ready     ),
        .dmi_resp_i           ( debug_resp           ),
        .tck_i                ( tck    ),
        .tms_i                ( tms    ),
        .trst_ni              ( trst_n ),
        .td_i                 ( tdi    ),
        .td_o                 ( tdo    ),
        .tdo_oe_o             (        )
    );

    // access debug module register
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;
    TL2Reg_be #(
        .ADDR_WIDTH ( 64),
        .DATA_WIDTH ( 64)
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( cpu_rst_n     ),
        .TL_A_valid_i       (inp_tl_A_valid_i ),              
        .TL_A_ready_o       (inp_tl_A_ready_o ),              
        .TL_A_bits_i        (inp_tl_A_bits_i  ),            

        .TL_D_valid_o       (inp_tl_D_valid_o ),              
        .TL_D_ready_i       (inp_tl_D_ready_i ),              
        .TL_D_bits_o        (inp_tl_D_bits_o  ),            

        .addr_o             ( dm_slave_addr      ),
        .en_o               ( dm_slave_en        ),
        .we_o               ( dm_slave_we        ),
        .wdata_o            ( dm_slave_wdata     ),
        .be_o               ( dm_slave_be        ),         
        .rdata_i            ( dm_slave_rdata     )
    );

    // debug module
    dm_top #(
        .NrHarts          ( HART_NUM          ),
        .BusWidth         ( 64                ),
        .SelectableHarts  ( {HART_NUM{1'b1}}  )
    ) i_dm_top (
        .clk_i            ( clk_i             ),
        .rst_ni           ( rst_i             ), // PoR
        .testmode_i       ( 1'b0              ),
        .ndmreset_o       ( ndmreset          ),
        .dmactive_o       ( dmactive          ), // active debug session
        .debug_req_o      ( debug_req_irq     ),
        .unavailable_i    ( '0                ),
        .hartinfo_i       ( {HART_NUM{sy_pkg::DebugHartInfo}} ),
        .slave_req_i      ( dm_slave_en       ),
        .slave_we_i       ( dm_slave_we       ),
        .slave_addr_i     ( dm_slave_addr     ),
        .slave_be_i       ( dm_slave_be       ),
        .slave_wdata_i    ( dm_slave_wdata    ),
        .slave_rdata_o    ( dm_slave_rdata    ),

        .master_req_o     ( dm_master_req     ),
        .master_add_o     ( dm_master_add     ),
        .master_we_o      ( dm_master_we      ),
        .master_wdata_o   ( dm_master_wdata   ),
        .master_be_o      ( dm_master_be      ),
        .master_gnt_i     ( dm_master_gnt     ),
        .master_r_valid_i ( dm_master_r_valid ),
        .master_r_rdata_i ( dm_master_r_rdata ),

        .dmi_rst_ni       ( rst_i             ),
        .dmi_req_valid_i  ( debug_req_valid   ),
        .dmi_req_ready_o  ( debug_req_ready   ),
        .dmi_req_i        ( debug_req         ),
        .dmi_resp_valid_o ( debug_resp_valid  ),
        .dmi_resp_ready_i ( debug_resp_ready  ),
        .dmi_resp_o       ( debug_resp        )
    );

    Reg2TL #(
        .ADDR_WIDTH (64),
        .DATA_WIDTH (64), 
        .SOURCE     (SOURCE)
    ) Reg2tl_inst(
        .clk_i             (clk_i),
        .rst_i             (cpu_rst_n),

        .TL_A_valid_o      (oup_tl_A_valid_o), 
        .TL_A_ready_i      (oup_tl_A_ready_i), 
        .TL_A_bits_o       (oup_tl_A_bits_o ),

        .TL_C_valid_o      (oup_tl_C_valid_o), 
        .TL_C_ready_i      (oup_tl_C_ready_i), 
        .TL_C_bits_o       (oup_tl_C_bits_o ),

        .TL_D_valid_i      (oup_tl_D_valid_i), 
        .TL_D_ready_o      (oup_tl_D_ready_o), 
        .TL_D_bits_i       (oup_tl_D_bits_i ),

        .req_i             (dm_master_req),
        .gnt_o             (dm_master_gnt),
        .we_i              (dm_master_we),
        .addr_i            (dm_master_add),
        .be_i              (dm_master_be),
        .wdata_i           (dm_master_wdata),
        .rdata_valid_o     (dm_master_r_valid),
        .rdata_o           (dm_master_r_rdata)
    );

    assign oup_tl_E_valid_o = 1'b0;
    assign oup_tl_E_bits_o  = tl_pkg::E_chan_bits_t'(0);
    assign oup_tl_B_ready_o = 1'b1;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

// (* mark_debug = "true" *) logic         prb_debug_A_valid;
// (* mark_debug = "true" *) logic         prb_debug_A_ready;
// (* mark_debug = "true" *) logic[31:0]   prb_debug_A_addr;
// (* mark_debug = "true" *) logic[63:0]   prb_debug_A_data;
// (* mark_debug = "true" *) logic[7:0]    prb_debug_A_mask;

// (* mark_debug = "true" *) logic         prb_debug_C_valid;
// (* mark_debug = "true" *) logic         prb_debug_C_ready;
// (* mark_debug = "true" *) logic[31:0]   prb_debug_C_addr;
// (* mark_debug = "true" *) logic[63:0]   prb_debug_C_data;

// (* mark_debug = "true" *) logic         prb_debug_D_valid;
// (* mark_debug = "true" *) logic         prb_debug_D_ready;
// (* mark_debug = "true" *) logic[63:0]   prb_debug_D_data;

// assign prb_debug_A_valid    = oup_tl_A_valid_o;
// assign prb_debug_A_ready    = oup_tl_A_ready_i;
// assign prb_debug_A_addr     = oup_tl_A_bits_o.address;
// assign prb_debug_A_data     = oup_tl_A_bits_o.data;
// assign prb_debug_A_mask     = oup_tl_A_bits_o.mask;

// assign prb_debug_C_valid    = oup_tl_C_valid_o;
// assign prb_debug_C_ready    = oup_tl_C_ready_i;
// assign prb_debug_C_addr     = oup_tl_C_bits_o.address;
// assign prb_debug_C_data     = oup_tl_C_bits_o.data;

// assign prb_debug_D_valid    = oup_tl_D_valid_i;
// assign prb_debug_D_ready    = oup_tl_D_ready_o;
// assign prb_debug_D_data     = oup_tl_D_bits_i.data;     


endmodule