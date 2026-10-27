// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ethernet.v
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

module sy_ethernet
    import sy_pkg::*;
# (
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64
)(
    input  logic                        clk_i,       
    input  logic                        clk_200M_i,
    input  logic                        rst_ni,           
    // Ethernet
    input  logic                        eth_clk_i       ,
    input  wire                         eth_rxck        ,
    input  wire                         eth_rxctl       ,
    input  wire [3:0]                   eth_rxd         ,
    output wire                         eth_txck        ,
    output wire                         eth_txctl       ,
    output wire [3:0]                   eth_txd         ,
    output wire                         eth_rst_n       ,
    input  logic                        phy_tx_clk_i    , // 125 MHz Clock

    inout  wire                         eth_mdio,
    output logic                        eth_mdc,    

    output logic                        eth_irq_o,
    // used to read/write control register
    TL_BUS.Master                       master
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic                                   eth_en;
    logic                                   eth_we;
    logic [63:0]                            eth_addr;
    logic [7:0]                             eth_be;
    logic [63:0]                            eth_rdata;
    logic [63:0]                            eth_wdata;

    logic                                   eth_mdio_i;                
    logic                                   eth_mdio_o;                
    logic                                   eth_mdio_oe;                
    logic                                   eth_pme_n;              
//======================================================================================================================
// Instance
//======================================================================================================================
    assign master.b_valid = 1'b0;
    TL2Reg_be #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_ni         ),
        .TL_A_valid_i       (master.a_valid ),              
        .TL_A_ready_o       (master.a_ready ),              
        .TL_A_bits_i        (master.a_bits  ),            

        .TL_D_valid_o       (master.d_valid ),              
        .TL_D_ready_i       (master.d_ready ),              
        .TL_D_bits_o        (master.d_bits  ),            

        .addr_o             ( eth_addr      ),
        .en_o               ( eth_en        ),
        .we_o               ( eth_we        ),
        .wdata_o            ( eth_wdata     ),
        .be_o               ( eth_be        ),
        .rdata_i            ( eth_rdata     )
    );

    framing_top eth_rgmii (
       .msoc_clk(clk_i),
       .core_lsu_addr(eth_addr[14:0]),
       .core_lsu_wdata(eth_wrdata),
       .core_lsu_be(eth_be),
       .ce_d(eth_en),
       .we_d(eth_en & eth_we),
       .framing_sel(eth_en),
       .framing_rdata(eth_rdata),
       .rst_int(!rst_ni),
       .clk_int(phy_tx_clk_i), // 125 MHz in-phase
       .clk90_int(eth_clk_i),    // 125 MHz quadrature
       .clk_200_int(clk_200M_i),
       /*
        * Ethernet: 1000BASE-T RGMII
        */
       .phy_rx_clk(eth_rxck),
       .phy_rxd(eth_rxd),
       .phy_rx_ctl(eth_rxctl),
       .phy_tx_clk(eth_txck),
       .phy_txd(eth_txd),
       .phy_tx_ctl(eth_txctl),
       .phy_reset_n(eth_rst_n),
       .phy_int_n(eth_int_n),
       .phy_pme_n(eth_pme_n),
       .phy_mdc(eth_mdc),
       .phy_mdio_i(eth_mdio_i),
       .phy_mdio_o(eth_mdio_o),
       .phy_mdio_oe(eth_mdio_oe),
       .eth_irq(eth_irq_o)
    );


    IOBUF #(
       .DRIVE(12), // Specify the output drive strength
       .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE"
       .IOSTANDARD("DEFAULT"), // Specify the I/O standard
       .SLEW("SLOW") // Specify the output slew rate
    ) IOBUF_inst (
       .O(eth_mdio_i),     // Buffer output
       .IO(eth_mdio),   // Buffer inout port (connect directly to top-level port)
       .I(eth_mdio_o),     // Buffer input
       .T(~eth_mdio_oe)      // 3-state enable input, high=input, low=output
    );
endmodule