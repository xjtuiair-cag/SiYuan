// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_npu_core.v
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

module sy_npu_core #(
    parameter int unsigned ADDR_WIDTH   = 64,
    parameter int unsigned DATA_WIDTH   = 64
) (
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // AXI4 TO DDR 
    output  logic                       axi_aw_valid_o,
    input   logic                       axi_aw_ready_i,         
    output  axi_pkg::aw_chan_t          axi_aw_bits_o,
    output  logic                       axi_ar_valid_o,
    input   logic                       axi_ar_ready_i,         
    output  axi_pkg::ar_chan_t          axi_ar_bits_o,
    output  logic                       axi_w_valid_o,
    input   logic                       axi_w_ready_i,         
    output  axi_pkg::w_chan_t           axi_w_bits_o,
    input   logic                       axi_r_valid_i,
    output  logic                       axi_r_ready_o,
    input   axi_pkg::r_chan_t           axi_r_bits_i, 
    input   logic                       axi_b_valid_i,
    output  logic                       axi_b_ready_o,
    input   axi_pkg::b_chan_t           axi_b_bits_i,

    TL_BUS.Master                       npu_reg 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[2:0] {IDLE, READ_1,READ_2,WRITE_1,WRITE_2,WRITE_3, RESP} state_e;
    state_e                           state_d, state_q;
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic [ADDR_WIDTH-1:0]      address;
    logic                       en;
    logic                       we;
    logic [DATA_WIDTH-1:0]      wdata;
    logic [DATA_WIDTH-1:0]      rdata;

    logic [28:0]                npu_core_axi_araddr  ; 
    logic                       npu_core_axi_arready ;
    logic                       npu_core_axi_arvalid ;
    logic [28:0]                npu_core_axi_awaddr  ; 
    logic                       npu_core_axi_awready ;
    logic                       npu_core_axi_awvalid ; 
    logic [127:0]               npu_core_axi_rdata   ;
    logic [5:0]                 npu_core_axi_rid     ;
    logic                       npu_core_axi_rlast   ;
    logic                       npu_core_axi_rready  ;
    logic                       npu_core_axi_rvalid  ;
    logic [127:0]               npu_core_axi_wdata   ;   
    logic                       npu_core_axi_wlast   ;
    logic                       npu_core_axi_wready  ;
    logic                       npu_core_axi_wvalid  ;

    logic [31:0]                npu_base_addr;

    logic [DATA_WIDTH-1:0]      rdata_1_d, rdata_1_q; 
    logic [DATA_WIDTH-1:0]      rdata_2_d, rdata_2_q; 
    logic [127:0]               wdata_d, wdata_q;
    logic                       wlast_d, wlast_q;

//======================================================================================================================
// Instance
//======================================================================================================================
    assign npu_reg.b_valid = 1'b0;
    TL2Reg #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       (npu_reg.a_valid ),              
        .TL_A_ready_o       (npu_reg.a_ready ),              
        .TL_A_bits_i        (npu_reg.a_bits  ),            

        .TL_D_valid_o       (npu_reg.d_valid ),              
        .TL_D_ready_i       (npu_reg.d_ready ),              
        .TL_D_bits_o        (npu_reg.d_bits  ),            

        .addr_o             ( address       ),
        .en_o               ( en            ),
        .we_o               ( we            ),
        .wdata_o            ( wdata         ),
        .rdata_i            ( rdata         )
    );

    assign rdata[63:32] = 32'h0;
    pl_top npu_core(
        // clock & reset
        .rst_n                   (rst_i),       
        .clk_100m                (clk_i),          

        .ps_rvram__addr_i        (address[11:0]),                  
        .ps_rvram__din_i         (wdata[31:0]),                 
        .ps_rvram__dout_o        (rdata[31:0]),                  
        .ps_rvram__en_i          (en),                
        .ps_rvram__rst_i         (!rst_i),                 
        .ps_rvram__we_i          (we),                

        .axi_ddr_araddr          (npu_core_axi_araddr  ),                    
        .axi_ddr_arready         (npu_core_axi_arready ),                   
        .axi_ddr_arvalid         (npu_core_axi_arvalid ),                   
        .axi_ddr_awaddr          (npu_core_axi_awaddr  ),                    
        .axi_ddr_awready         (npu_core_axi_awready ),                   
        .axi_ddr_awvalid         (npu_core_axi_awvalid ),                    
        .axi_ddr_rdata           (npu_core_axi_rdata   ),                   
        .axi_ddr_rid             (npu_core_axi_rid     ),                   
        .axi_ddr_rlast           (npu_core_axi_rlast   ),                   
        .axi_ddr_rready          (npu_core_axi_rready  ),                   
        .axi_ddr_rvalid          (npu_core_axi_rvalid  ),                   
        .axi_ddr_wdata           (npu_core_axi_wdata   ),                      
        .axi_ddr_wlast           (npu_core_axi_wlast   ),                   
        .axi_ddr_wready          (npu_core_axi_wready  ),                   
        .axi_ddr_wvalid          (npu_core_axi_wvalid  ),                   
    
        .ps_ddr_intf_base_addr_o (npu_base_addr)      
    );

    // trans 128 bit data width to 64 bit
    // address read channel
    assign axi_ar_bits_o.addr   = npu_core_axi_araddr + npu_base_addr;
    assign axi_ar_bits_o.id     = '0;
    assign axi_ar_bits_o.len    = 8'd7;      
    assign axi_ar_bits_o.size   = 3'b011;       
    assign axi_ar_bits_o.burst  = axi_pkg::BURST_INCR;        
    assign axi_ar_bits_o.lock   = '0;       
    assign axi_ar_bits_o.cache  = '0;        
    assign axi_ar_bits_o.prot   = 3'b1;       
    assign axi_ar_bits_o.qos    = '0;      
    // address write channel
    assign axi_aw_bits_o.addr   = npu_core_axi_awaddr + npu_base_addr;          
    assign axi_aw_bits_o.id     = '0;        
    assign axi_aw_bits_o.len    = 8'd7;         
    assign axi_aw_bits_o.size   = 3'b011;          
    assign axi_aw_bits_o.burst  = axi_pkg::BURST_INCR;           
    assign axi_aw_bits_o.lock   = '0;          
    assign axi_aw_bits_o.cache  = '0;           
    assign axi_aw_bits_o.prot   = 3'b1;
    assign axi_aw_bits_o.qos    = '0;         
    // write data channel
    assign axi_w_bits_o.strb = 8'hff;
    assign axi_w_bits_o.data = (state_q == WRITE_2) ? wdata_q[63:0] : wdata_q[127:64];

    assign npu_core_axi_rdata  = {rdata_2_d,rdata_1_d};
    assign npu_core_axi_rid    = '0;

    always_comb begin : FSM 
        state_d   = state_q;

        npu_core_axi_arready    = 1'b0;
        npu_core_axi_awready    = 1'b0;
        npu_core_axi_rvalid     = 1'b0;
        npu_core_axi_rlast      = 1'b0;
        npu_core_axi_wready     = 1'b0;

        axi_ar_valid_o          = 1'b0;
        axi_aw_valid_o          = 1'b0;
        axi_w_valid_o           = 1'b0;
        axi_r_ready_o           = 1'b0;
        axi_b_ready_o           = 1'b0;
        axi_w_bits_o.last       = 1'b0;

        rdata_1_d = rdata_1_q;
        rdata_2_d = rdata_2_q;
        wlast_d   = wlast_q;
        wdata_d   = wdata_q;

        unique case(state_q)
          IDLE : begin 
            if (npu_core_axi_arvalid) begin
                axi_ar_valid_o = 1'b1;
                npu_core_axi_arready = axi_ar_ready_i;
                if (axi_ar_ready_i) begin
                    state_d = READ_1;
                end
            end else if (npu_core_axi_awvalid) begin
                axi_aw_valid_o = 1'b1;
                npu_core_axi_awready = axi_aw_ready_i;
                if (axi_aw_ready_i) begin
                    state_d = WRITE_1;
                end
            end
          end
          READ_1: begin
            axi_r_ready_o = 1'b1;
            if (axi_r_valid_i) begin
                rdata_1_d = axi_r_bits_i.data;     
                state_d = READ_2;
            end
          end
          READ_2: begin
            rdata_2_d = axi_r_bits_i.data;
            axi_r_ready_o = npu_core_axi_rready;
            npu_core_axi_rvalid = axi_r_valid_i;
            if (axi_r_valid_i && axi_r_ready_o && axi_r_bits_i.last) begin
                npu_core_axi_rlast = 1'b1;
                state_d = IDLE;
            end else if (axi_r_valid_i && axi_r_ready_o) begin
                state_d = READ_1;
            end
          end
          WRITE_1 : begin
            npu_core_axi_wready = 1'b1;
            if (npu_core_axi_wvalid) begin
                wdata_d = npu_core_axi_wdata;
                wlast_d = npu_core_axi_wlast;
                state_d = WRITE_2;
            end
          end
          WRITE_2 : begin
            axi_w_valid_o = 1'b1;
            if (axi_w_ready_i) begin
                state_d = WRITE_3;
            end
          end
          WRITE_3 : begin
            axi_w_valid_o = 1'b1;
            axi_w_bits_o.last = wlast_q;
            if (axi_w_ready_i && wlast_q) begin
                state_d = RESP;
            end else if (axi_w_ready_i) begin
                state_d = WRITE_1;
            end
          end
          RESP : begin
            axi_b_ready_o = 1'b1;
            if (axi_b_valid_i) begin
                state_d = IDLE;
            end
          end
          default : state_d = IDLE;
        endcase
    end


  always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
      if(!rst_i) begin
        state_q <= IDLE;
        wlast_q <= 1'b0;
        wdata_q <= '0;
        rdata_1_q <= '0;
        rdata_2_q <= '0;
      end else begin
        state_q <= state_d;
        wlast_q <= wlast_d;
        wdata_q <= wdata_d;
        rdata_1_q <= rdata_1_d;
        rdata_2_q <= rdata_2_d;
      end
  end
endmodule