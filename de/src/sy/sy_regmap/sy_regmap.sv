// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_regmap.v
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

module sy_regmap
    import sy_pkg::*;
# (
    parameter BASE_ADDR  = 64'h61_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter SOURCE     = 0
)(
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // used to read/write control register
    TL_BUS.Master                       master,

    // regmap ctrl 
    output logic                        flush_L2_cache_en_o,                       
    input  logic                        flush_L2_cache_done_i  
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam  FLUSH = BASE_ADDR + 64'h0;
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic                                   regmap_en;
    logic                                   regmap_we;
    logic [DATA_WIDTH-1:0]                  regmap_rdata;
    logic [ADDR_WIDTH-1:0]                  regmap_addr;
    logic [DATA_WIDTH-1:0]                  regmap_wdata;

    logic                                   flush_L2_en;
    logic                                   flush_L2_done;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign master.b_valid = 1'b0;
    TL2Reg #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       (master.a_valid ),              
        .TL_A_ready_o       (master.a_ready ),              
        .TL_A_bits_i        (master.a_bits  ),            

        .TL_D_valid_o       (master.d_valid ),              
        .TL_D_ready_i       (master.d_ready ),              
        .TL_D_bits_o        (master.d_bits  ),            

        .addr_o             ( regmap_addr      ),
        .en_o               ( regmap_en        ),
        .we_o               ( regmap_we        ),
        .wdata_o            ( regmap_wdata     ),
        .rdata_i            ( regmap_rdata     )
    );
//======================================================================================================================
// Regmap Registers
//======================================================================================================================

    always_ff @(`DFF_CR(clk_i,rst_i)) begin 
        if(`DFF_IS_R(rst_i)) begin
            flush_L2_en <= 1'b0;
            flush_L2_done <= 1'b0;
        end else begin
            // write 
            if (regmap_en && regmap_we) begin
                case(regmap_addr)
                    FLUSH: begin
                        flush_L2_en <= regmap_wdata[0];
                        flush_L2_done <= regmap_wdata[1];
                    end
                    default: ;
                endcase
            end
            // read
            if (regmap_en && !regmap_we) begin
               case(regmap_addr) 
                FLUSH: begin
                    regmap_rdata <= {flush_L2_done,flush_L2_en};
                end
               endcase
            end
            // L2 flush done
            if (flush_L2_cache_done_i) begin
                flush_L2_done <= 1'b1;
            end 
        end
    end

    assign flush_L2_cache_en_o = flush_L2_en;

endmodule