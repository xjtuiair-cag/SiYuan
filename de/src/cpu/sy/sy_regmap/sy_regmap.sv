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
    parameter CORE_NUM   = sy_soc_pkg::CORE_NUM,
    parameter BASE_ADDR  = 64'h61_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter integer IRQ_NUM = 1,
    parameter SOURCE     = 0
)(
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // used to read/write control register
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

    // regmap ctrl 
    output logic[CORE_NUM-1:0]          siyuan_call_o,
    output logic[CORE_NUM-1:0]          siyuan_invdc_o,
    output logic[CORE_NUM-1:0]          siyuan_invic_o,
    output logic[CORE_NUM-1:0]          siyuan_kill_o,
    input  logic[CORE_NUM-1:0]          siyuan_call_busy_i,
    input  logic[CORE_NUM-1:0]          siyuan_invdc_busy_i,
    input  logic[CORE_NUM-1:0]          siyuan_invic_busy_i,
    input  logic[CORE_NUM-1:0]          siyuan_kill_busy_i,
    output logic[CORE_NUM-1:0]          siyuan_fence_state_o,
    output logic[CORE_NUM-1:0]          siyuan_forbid_br_pred_o,
    output logic[CORE_NUM-1:0]          siyuan_avail_cores_o,
    output logic                        flush_L2_cache_en_o,                       
    output logic                        exe_region_ex_en_o,                      
    output logic                        inv_L2_cache_en_o,                       
    input  logic                        flush_L2_cache_busy_i,
    input  logic                        inv_L2_cache_busy_i,
    output logic[63:0]                  siyuan_init_pc_o,
    output logic[63:0]                  siyuan_ret_addr_o,

    output logic[IRQ_NUM-1:0]           siyuan_irq_o,

    output logic[31:0]                  ddr_base_addr_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam  SIYUAN_INF              = 12'h0;
    localparam  SIYUAN_CTRL             = 12'h4;
    localparam  SIYUAN_STATUS           = 12'h8;
    localparam  SIYUAN_AVAIL_CORES      = 12'hC;
    localparam  SIYUAN_ARG_00           = 12'h10;
    localparam  SIYUAN_ARG_01           = 12'h14;
    localparam  SIYUAN_ARG_02           = 12'h18;
    localparam  SIYUAN_ARG_03           = 12'h1C;
    localparam  SIYUAN_ARG_04           = 12'h20;
    localparam  SIYUAN_ARG_05           = 12'h24;
    localparam  SIYUAN_ARG_06           = 12'h28;
    localparam  SIYUAN_ARG_07           = 12'h2C;
    localparam  SIYUAN_ARG_08           = 12'h30;
    localparam  SIYUAN_ARG_09           = 12'h34;
    localparam  SIYUAN_ARG_0A           = 12'h38;
    localparam  SIYUAN_ARG_0B           = 12'h3C;
    localparam  SIYUAN_ARG_0C           = 12'h40;
    localparam  SIYUAN_ARG_0D           = 12'h44;
    localparam  SIYUAN_ARG_0E           = 12'h48;
    localparam  SIYUAN_ARG_0F           = 12'h4C;
    localparam  SIYUAN_ARG_10           = 12'h50;
    localparam  SIYUAN_ARG_11           = 12'h54;
    localparam  SIYUAN_ARG_12           = 12'h58;
    localparam  SIYUAN_ARG_13           = 12'h5C;
    localparam  SIYUAN_ARG_14           = 12'h60;
    localparam  SIYUAN_ARG_15           = 12'h64;
    localparam  SIYUAN_ARG_16           = 12'h68;
    localparam  SIYUAN_ARG_17           = 12'h6C;
    localparam  SIYUAN_ARG_18           = 12'h70;
    localparam  SIYUAN_ARG_19           = 12'h74;
    localparam  SIYUAN_ARG_1A           = 12'h78;
    localparam  SIYUAN_ARG_1B           = 12'h7C;
    localparam  SIYUAN_ARG_1C           = 12'h80;
    localparam  SIYUAN_ARG_1D           = 12'h84;
    localparam  SIYUAN_ARG_1E           = 12'h88;
    localparam  SIYUAN_ARG_1F           = 12'h8C;
    localparam  SIYUAN_INIT_PC          = 12'h90;
    localparam  SIYUAN_INIT_PC_HIGH     = 12'h94;
    localparam  SIYUAN_RET_ADDR         = 12'h98;
    localparam  SIYUAN_RET_ADDR_HIGH    = 12'h9C;
    localparam  SIYUAN_SIS              = 12'hA0;
    localparam  SIYUAN_SIC              = 12'hA4;
    localparam  SIYUAN_SI               = 12'hA8;
    localparam  SIYUAN_SIE              = 12'hAC;
    localparam  SIYUAN_SIM              = 12'hB0;
    localparam  SIYUAN_DDR_BASE         = 12'hB4;
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic                                   regmap_en;
    logic                                   regmap_we;
    logic [DATA_WIDTH-1:0]                  regmap_rdata;
    logic [ADDR_WIDTH-1:0]                  regmap_addr_raw;
    logic [11:0]                            regmap_addr;
    logic [DATA_WIDTH-1:0]                  regmap_wdata;
    logic [4:0]                             regmap_arg_off;

    logic [31:0]                            siyuan_inf;
    logic [31:0]                            siyuan_ctrl;
    logic [31:0]                            siyuan_status;
    logic [31:0]                            siyuan_init_pc;
    logic [31:0]                            siyuan_init_pc_h;
    logic [31:0]                            siyuan_ret_addr;
    logic [31:0]                            siyuan_ret_addr_h;
    logic [31:0][31:0]                      siyuan_arg;

    logic [31:0]                            siyuan_irq;
    logic [31:0]                            siyuan_irq_mask;
    logic                                   siyuan_irq_en; 

    logic [31:0]                            siyuan_ddr_base;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;

    TL2Reg #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       (inp_tl_A_valid_i),              
        .TL_A_ready_o       (inp_tl_A_ready_o),              
        .TL_A_bits_i        (inp_tl_A_bits_i ),            

        .TL_D_valid_o       (inp_tl_D_valid_o),              
        .TL_D_ready_i       (inp_tl_D_ready_i),              
        .TL_D_bits_o        (inp_tl_D_bits_o ),            

        .addr_o             ( regmap_addr_raw  ),
        .en_o               ( regmap_en        ),
        .we_o               ( regmap_we        ),
        .wdata_o            ( regmap_wdata     ),
        .rdata_i            ( regmap_rdata     )
    );
    assign regmap_addr = regmap_addr_raw;
    assign regmap_arg_off = regmap_addr[6:2] - SIYUAN_ARG_00[6:2];
//======================================================================================================================
// Regmap Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin 
        if(`DFF_IS_R(rst_i)) begin
            siyuan_inf          <= 32'h610A;
            siyuan_ctrl         <= 32'h0;
            siyuan_status       <= 32'h0;
            siyuan_init_pc      <= 32'h58000000; 
            // siyuan_init_pc      <= 32'h80000000;    
            siyuan_init_pc_h    <= 32'h00000000;    
            siyuan_ret_addr     <= 32'h00000000;    
            siyuan_ret_addr_h   <= 32'h00000000;    
            siyuan_arg          <= {32{32'h0}};
            siyuan_irq          <= 32'h0;
            siyuan_irq_mask     <= 32'h0;
            siyuan_irq_en       <= 1'b0;
            siyuan_ddr_base     <= 32'h0;
            siyuan_avail_cores_o<= 4'hF;
            regmap_rdata        <= 32'h0;

            siyuan_call_o        <=  4'b0;
            siyuan_invdc_o       <=  4'b0;
            siyuan_invic_o       <=  4'b0;
            siyuan_kill_o        <=  4'b0;
            siyuan_fence_state_o <=  4'b0;
            siyuan_forbid_br_pred_o <=  4'h0;
            flush_L2_cache_en_o  <=  1'b0;
            inv_L2_cache_en_o    <=  1'b0;
            exe_region_ex_en_o   <=  1'b1;
        end else begin
            siyuan_inf          <= siyuan_inf;
            // write 
            if (regmap_en && regmap_we) begin
                case(regmap_addr)
                    SIYUAN_INF:;    // read only
                    SIYUAN_STATUS:; // read only
                    SIYUAN_CTRL: begin
                        siyuan_call_o           <=  regmap_wdata[3:0];
                        siyuan_invdc_o          <=  regmap_wdata[7:4];
                        siyuan_invic_o          <=  regmap_wdata[11:8];
                        siyuan_kill_o           <=  regmap_wdata[15:12];
                        siyuan_fence_state_o    <=  regmap_wdata[19:16];
                        siyuan_forbid_br_pred_o <=  regmap_wdata[23:20];
                        flush_L2_cache_en_o     <=  regmap_wdata[24];
                        inv_L2_cache_en_o       <=  regmap_wdata[25];
                        exe_region_ex_en_o      <=  regmap_wdata[26];
                    end
                    SIYUAN_INIT_PC: begin
                        siyuan_init_pc <= regmap_wdata;
                    end
                    SIYUAN_INIT_PC_HIGH: begin
                        siyuan_init_pc_h <= regmap_wdata;
                    end
                    SIYUAN_RET_ADDR: begin
                        siyuan_ret_addr <= regmap_wdata;
                    end
                    SIYUAN_RET_ADDR_HIGH: begin
                        siyuan_ret_addr_h <= regmap_wdata;
                    end
                    SIYUAN_ARG_00,SIYUAN_ARG_01,SIYUAN_ARG_02,SIYUAN_ARG_03,SIYUAN_ARG_04,SIYUAN_ARG_05,SIYUAN_ARG_06,SIYUAN_ARG_07,
                    SIYUAN_ARG_08,SIYUAN_ARG_09,SIYUAN_ARG_0A,SIYUAN_ARG_0B,SIYUAN_ARG_0C,SIYUAN_ARG_0D,SIYUAN_ARG_0E,SIYUAN_ARG_0F,
                    SIYUAN_ARG_10,SIYUAN_ARG_11,SIYUAN_ARG_12,SIYUAN_ARG_13,SIYUAN_ARG_14,SIYUAN_ARG_15,SIYUAN_ARG_16,SIYUAN_ARG_17,
                    SIYUAN_ARG_18,SIYUAN_ARG_19,SIYUAN_ARG_1A,SIYUAN_ARG_1B,SIYUAN_ARG_1C,SIYUAN_ARG_1D,SIYUAN_ARG_1E,SIYUAN_ARG_1F: begin
                        siyuan_arg[regmap_arg_off[4:0]] <= regmap_wdata;
                    end
                    SIYUAN_SIS: begin
                        siyuan_irq <= siyuan_irq | regmap_wdata;
                    end
                    SIYUAN_SIC: begin
                        siyuan_irq <= siyuan_irq & ~regmap_wdata;
                    end 
                    SIYUAN_SIE: begin
                        siyuan_irq_en <= regmap_wdata[0];
                    end
                    SIYUAN_SIM: begin
                        siyuan_irq_mask <= regmap_wdata;
                    end
                    SIYUAN_DDR_BASE: begin
                        siyuan_ddr_base <= regmap_wdata;
                    end
                    SIYUAN_AVAIL_CORES: begin
                        siyuan_avail_cores_o <= regmap_wdata[3:0];
                    end
                    default: ;
                endcase
            end
            // read
            if (regmap_en && !regmap_we) begin
                case(regmap_addr) 
                    SIYUAN_INF: begin
                        regmap_rdata <= siyuan_inf;
                    end
                    SIYUAN_STATUS: begin
                        regmap_rdata <= {exe_region_ex_en_o,inv_L2_cache_busy_i,flush_L2_cache_busy_i,
                                         siyuan_forbid_br_pred_o,siyuan_fence_state_o,
                                         siyuan_kill_busy_i,siyuan_invic_busy_i,siyuan_invdc_busy_i,siyuan_call_busy_i}; 
                    end
                    SIYUAN_INIT_PC : begin
                        regmap_rdata <= siyuan_init_pc;
                    end
                    SIYUAN_INIT_PC_HIGH : begin
                        regmap_rdata <= siyuan_init_pc_h;
                    end
                    SIYUAN_RET_ADDR : begin
                        regmap_rdata <= siyuan_ret_addr;
                    end
                    SIYUAN_RET_ADDR_HIGH: begin
                        regmap_rdata <= siyuan_ret_addr_h;
                    end
                    SIYUAN_ARG_00,SIYUAN_ARG_01,SIYUAN_ARG_02,SIYUAN_ARG_03,SIYUAN_ARG_04,SIYUAN_ARG_05,SIYUAN_ARG_06,SIYUAN_ARG_07,
                    SIYUAN_ARG_08,SIYUAN_ARG_09,SIYUAN_ARG_0A,SIYUAN_ARG_0B,SIYUAN_ARG_0C,SIYUAN_ARG_0D,SIYUAN_ARG_0E,SIYUAN_ARG_0F,
                    SIYUAN_ARG_10,SIYUAN_ARG_11,SIYUAN_ARG_12,SIYUAN_ARG_13,SIYUAN_ARG_14,SIYUAN_ARG_15,SIYUAN_ARG_16,SIYUAN_ARG_17,
                    SIYUAN_ARG_18,SIYUAN_ARG_19,SIYUAN_ARG_1A,SIYUAN_ARG_1B,SIYUAN_ARG_1C,SIYUAN_ARG_1D,SIYUAN_ARG_1E,SIYUAN_ARG_1F: begin
                        regmap_rdata <= siyuan_arg[regmap_arg_off[4:0]];
                    end
                    SIYUAN_SI: begin 
                        regmap_rdata <= siyuan_irq_o;
                    end
                    SIYUAN_SIE: begin
                        regmap_rdata <= {31'h0,siyuan_irq_en};
                    end  
                    SIYUAN_SIM: begin
                        regmap_rdata <= siyuan_irq_mask;
                    end
                    SIYUAN_DDR_BASE: begin
                        regmap_rdata <= siyuan_ddr_base;
                    end
                    SIYUAN_AVAIL_CORES: begin
                        regmap_rdata <= {28'h0,siyuan_avail_cores_o};
                    end
                    default: begin
                        regmap_rdata <= 32'h0;
                    end
                endcase
            end
            if (|siyuan_call_busy_i) begin
                siyuan_call_o <= siyuan_call_o & ~siyuan_call_busy_i;
            end
            if (|siyuan_invdc_busy_i) begin
                siyuan_invdc_o <= siyuan_invdc_o & ~siyuan_invdc_busy_i;
            end
            if (|siyuan_invic_busy_i) begin
                siyuan_invic_o <= siyuan_invic_o & ~siyuan_invic_busy_i;
            end
            if (|siyuan_kill_busy_i) begin
                siyuan_kill_o <= siyuan_kill_o & ~siyuan_kill_busy_i;
            end
            if (flush_L2_cache_busy_i) begin
                flush_L2_cache_en_o <= 1'b0;
            end
            if (inv_L2_cache_busy_i) begin
                inv_L2_cache_en_o <= 1'b0;
            end
        end
    end

    assign siyuan_init_pc_o     = {siyuan_init_pc_h, siyuan_init_pc};
    assign siyuan_ret_addr_o    = {siyuan_ret_addr_h,siyuan_ret_addr};
    assign ddr_base_addr_o      = siyuan_ddr_base;
    assign siyuan_irq_o = siyuan_irq[IRQ_NUM-1:0] & (~siyuan_irq_mask) & {IRQ_NUM{siyuan_irq_en}};
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// (* mark_debug = "true" *) logic[31:0]     prb_regmap_init_pc;
// (* mark_debug = "true" *) logic[31:0]     prb_regmap_ret_addr;

// assign prb_regmap_init_pc   = siyuan_init_pc;
// assign prb_regmap_ret_addr  = siyuan_ret_addr;

// (* mark_debug = "true" *) logic         prb_regmap_en;
// (* mark_debug = "true" *) logic         prb_regmap_we;
// (* mark_debug = "true" *) logic[31:0]   prb_regmap_addr;
// (* mark_debug = "true" *) logic[31:0]   prb_regmap_rdata;
// (* mark_debug = "true" *) logic[31:0]   prb_regmap_wdata;

// assign prb_regmap_en    = regmap_en;
// assign prb_regmap_we    = regmap_we;
// assign prb_regmap_addr  = regmap_addr_raw;
// assign prb_regmap_rdata = regmap_rdata;
// assign prb_regmap_wdata = regmap_wdata;

// (* mark_debug = "true" *) logic         prb_regmap_L2_flush;
// (* mark_debug = "true" *) logic         prb_regmap_L2_flush_busy;
// assign prb_regmap_L2_flush  = flush_L2_cache_en_o;
// assign prb_regmap_L2_flush_busy = flush_L2_cache_busy_i;

endmodule