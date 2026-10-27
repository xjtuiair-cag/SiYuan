// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_controller.v
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

module sd_controller
    import sy_pkg::*;
(
    // Clock and reset
    input  logic                        sys_clk,
    input  logic                        sys_rst,
    // SD interface
    input  logic                        sd_cd,
    output logic                        sd_clk,
    output logic                        sd_reset,
    input  logic [3:0]                  sd_dat_dat_i,
    output logic [3:0]                  sd_dat_out_o,
    output logic                        sd_dat_oe_o,
    input  logic                        sd_cmd_dat_i,
    output logic                        sd_cmd_out_o,
    output logic                        sd_cmd_oe_o,

    output logic                        init_done,
    output logic                        is_hcxc,     // output if the card is a SDHC/SDXC card

    // Request Slave
    input  logic [`SD_ADDR_WIDTH-1:0]   req_addr_sd, // addr in SD 
    input  logic [`SD_ADDR_WIDTH-1:0]   req_addr_dma, // addr in fake memory
    input  logic [`SD_ADDR_WIDTH-10:0]  req_blkcnt,
    input  logic                        req_wr, // HIGH write; LOW read.
    input  logic                        req_val,
    output logic                        req_rdy,
    output logic [`SD_ADDR_WIDTH-1:0]   req_addr_sd_f,
    output logic [`SD_ADDR_WIDTH-1:0]   req_addr_dma_f,

    // Response Master
    output logic                        resp_ok, // HIGH ok; LOW err.
    output logic                        resp_val,
    input  logic                        resp_rdy,
   
    // Core <-> Buffer
    input  logic [31:0]                 core_buffer_addr,
    input  logic                        core_buffer_ce,
    input  logic                        core_buffer_wr,
    input  logic [1:0]                  core_buffer_sz,
    input  logic [`NOC_DATA_BITS]       core_buffer_data,
    output logic [`NOC_DATA_BITS]       buffer_core_data,

    input  logic[31:0]                  slow_clk_divider,
    input  logic[31:0]                  fast_clk_divider,

    input  logic[31:0]                  power_stable_cnt,
    input  logic[31:0]                  acmd41_reissue_cnt,
    // init debug
    output logic [7:0]                  init_state,
    // init compact FSM output
    output logic [31:0]                 counter,
    output logic [42:0]                 init_fsm, // {adr, dat, we, stb, counter_en}
    // tran debug
    output logic [5:0]                  tran_state,
    // tran compact FSM output
    output logic [41:0]                 tran_fsm // {adr, dat, we, stb}
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    // Aggregated reset signal
    logic                rst;
    logic                cpu_clk_rst;
    logic                init_done_rst;
    logic                sd_clk_rst;
    logic                sd_soft_rst;
    logic[31:0]          sd_cd_dly;
    logic[31:0]          m_wb_dat_o;
    logic[31:0]          m_wb_dat_i;
    logic[7:0]           m_wb_adr_o;
    logic[3:0]           m_wb_sel_o;
    logic                m_wb_we_o;
    logic                m_wb_cyc_o;
    logic                m_wb_stb_o;
    logic                m_wb_ack_i;

    // Wishbone SD Controller <-> SD Buffer
    logic[31:0]          s_wb_dat_i;
    logic[31:0]          s_wb_dat_o;
    logic[31:0]          s_wb_adr_i;
    logic[3:0]           s_wb_sel_i;
    logic                s_wb_we_i;
    logic                s_wb_cyc_i;
    logic                s_wb_stb_i;
    logic                s_wb_ack_o;
    // SD Card Interface
    logic                sd_int_cmd;
    logic                sd_int_data;
    // Init <-> Wishbone SD Controller
    logic    [31:0]      m_wb_dat_o_init;
    logic    [7:0]       m_wb_adr_o_init;
    logic                m_wb_we_o_init;
    logic                m_wb_stb_o_init;
    // Transaction Manager <-> Wishbone SD Controller
    logic    [31:0]      m_wb_dat_o_tm;
    logic    [7:0]       m_wb_adr_o_tm;
    logic                m_wb_we_o_tm;
    logic                m_wb_stb_o_tm;
//======================================================================================================================
// Instance
//======================================================================================================================
    // remove jitter of sd detect signal
    always @(`DFF_CR(sys_clk,sys_rst)) begin
        if(`DFF_IS_R(sys_rst)) begin
            sd_cd_dly <= 32'h0;
        end else begin
            sd_cd_dly <= {sd_cd_dly[30:0], sd_cd};
        end
    end
    // low active
    assign rst = sys_rst & (!(|sd_cd_dly));

    // sync cpu clk reset
    sync_rstgen #(
        .RESET_VALUE ("LOW")
    ) cpu_clk_reset(
        .clk_i      (sys_clk),
        .rst_i      (rst),
        .rst_o      (cpu_clk_rst)
    );

    // sync cpu clk reset
    sync_rstgen #(
        .RESET_VALUE ("LOW")
    ) init_done_reset(
        .clk_i      (sys_clk),
        .rst_i      (cpu_clk_rst & init_done),
        .rst_o      (init_done_rst)
    );

    assign  m_wb_dat_o  =   init_done ? m_wb_dat_o_tm : m_wb_dat_o_init;
    assign  m_wb_adr_o  =   init_done ? m_wb_adr_o_tm : m_wb_adr_o_init;
    assign  m_wb_sel_o  =   4'hf;
    assign  m_wb_cyc_o  =   1'b1;
    assign  m_wb_we_o   =   init_done ? m_wb_we_o_tm : m_wb_we_o_init;
    assign  m_wb_stb_o  =   init_done ? m_wb_stb_o_tm : m_wb_stb_o_init;

    assign  sd_reset    =   sys_rst;


    sd_buffer sd_buffer_inst (
        .clk                    (sys_clk),
        .rst                    (init_done_rst),

        .s_wb_dat_i             (s_wb_dat_i),
        .s_wb_dat_o             (s_wb_dat_o),
        .s_wb_adr_i             (s_wb_adr_i),
        .s_wb_sel_i             (s_wb_sel_i),
        .s_wb_we_i              (s_wb_we_i),
        .s_wb_cyc_i             (s_wb_cyc_i),
        .s_wb_stb_i             (s_wb_stb_i),
        .s_wb_ack_o             (s_wb_ack_o),

        .buf_addr_i             (core_buffer_addr),
        .buf_data_i             (core_buffer_data),
        .buf_ce_i               (core_buffer_ce),
        .buf_we_i               (core_buffer_wr),
        .buf_data_sz            (core_buffer_sz),
        .buf_data_o             (buffer_core_data)
    );

    sd_init sd_init_inst (
        .clk                    (sys_clk),
        .rst                    (cpu_clk_rst),

        .m_wb_dat_o             (m_wb_dat_o_init),
        .m_wb_dat_i             (m_wb_dat_i),
        .m_wb_adr_o             (m_wb_adr_o_init),
        .m_wb_sel_o             (),
        .m_wb_we_o              (m_wb_we_o_init),
        .m_wb_cyc_o             (),
        .m_wb_stb_o             (m_wb_stb_o_init),
        .m_wb_ack_i             (m_wb_ack_i),

        .slow_clk_divider       (slow_clk_divider),
        .fast_clk_divider       (fast_clk_divider),

        .power_stable_cnt       (power_stable_cnt  ),
        .acmd41_reissue_cnt     (acmd41_reissue_cnt),

        .sd_int_cmd             (sd_int_cmd),
        .sd_int_data            (sd_int_data),

        .init_done              (init_done),
        .is_hcxc                (is_hcxc),
        .init_state             (init_state),
        // compact FSM output
        .counter                 (counter),
        .fsm                     (init_fsm) // {adr, dat, we, stb, counter_en}
    );

    sd_trans_manager sd_tm_inst (
        .clk                    (sys_clk),
        .rst                    (init_done_rst),

        .req_addr_sd            (req_addr_sd),
        .req_addr_dma           (req_addr_dma),
        .req_blkcnt             (req_blkcnt),
        .req_wr                 (req_wr),
        .req_val                (req_val),
        .req_rdy                (req_rdy),
        .req_addr_sd_f          (req_addr_sd_f),
        .req_addr_dma_f         (req_addr_dma_f),

        .resp_ok                (resp_ok),
        .resp_val               (resp_val),
        .resp_rdy               (resp_rdy),

        .m_wb_dat_o             (m_wb_dat_o_tm),
        .m_wb_dat_i             (m_wb_dat_i),
        .m_wb_adr_o             (m_wb_adr_o_tm),
        .m_wb_sel_o             (),
        .m_wb_we_o              (m_wb_we_o_tm),
        .m_wb_cyc_o             (),
        .m_wb_stb_o             (m_wb_stb_o_tm),
        .m_wb_ack_i             (m_wb_ack_i),

        .sd_int_cmd             (sd_int_cmd),
        .sd_int_data            (sd_int_data),
        .tran_state             (tran_state),
        // compact FSM output
        .fsm                    (tran_fsm) // {adr, dat, we, stb, counter_en}
    );

    sd_trans_ctrl sd_trans_ctrl_inst(
        .wb_clk_i               (sys_clk),
        .wb_rst_i               (cpu_clk_rst),

        .wb_dat_i               (m_wb_dat_o),
        .wb_dat_o               (m_wb_dat_i),
        .wb_adr_i               (m_wb_adr_o),
        .wb_sel_i               (m_wb_sel_o),
        .wb_we_i                (m_wb_we_o),
        .wb_cyc_i               (m_wb_cyc_o),
        .wb_stb_i               (m_wb_stb_o),
        .wb_ack_o               (m_wb_ack_i),

        .m_wb_dat_o			    (s_wb_dat_i),
        .m_wb_dat_i			    (s_wb_dat_o),
        .m_wb_adr_o			    (s_wb_adr_i), 
        .m_wb_sel_o			    (s_wb_sel_i), 
        .m_wb_we_o			    (s_wb_we_i),
        .m_wb_cyc_o			    (s_wb_cyc_i),
        .m_wb_stb_o			    (s_wb_stb_i), 
        .m_wb_ack_i			    (s_wb_ack_o),
        .m_wb_cti_o			    (), 
        .m_wb_bte_o			    (),


        .sd_clk_o               (sd_clk),
        .sd_cmd_dat_i			(sd_cmd_dat_i), 
        .sd_cmd_out_o			(sd_cmd_out_o), 
        .sd_cmd_oe_o			(sd_cmd_oe_o), 
        .sd_dat_dat_i			(sd_dat_dat_i), 
        .sd_dat_out_o			(sd_dat_out_o), 
        .sd_dat_oe_o			(sd_dat_oe_o), 

        .int_cmd				(sd_int_cmd), 
        .int_data				(sd_int_data)
    );

endmodule
