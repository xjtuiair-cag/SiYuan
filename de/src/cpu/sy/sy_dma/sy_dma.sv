// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dma.v
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

module sy_dma 
    import sy_pkg::*;
# (
    parameter BASE_ADDR  = 32'h4182_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter SOURCE     = 0
)(
    input  logic                        clk_i,       
    input  logic                        rst_i,      

    output logic                        irq_o,
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
    localparam  SRC_BASE_ADDR       = BASE_ADDR + 32'h0;
    localparam  SRC_BASE_ADDRH      = BASE_ADDR + 32'h4;
    localparam  DES_BASE_ADDR       = BASE_ADDR + 32'h8;
    localparam  DES_BASE_ADDRH      = BASE_ADDR + 32'hC;
    localparam  DATA_VOLUME         = BASE_ADDR + 32'h10;
    localparam  BURST_LENGTH        = BASE_ADDR + 32'h14;
    localparam  TRANS_CTRL          = BASE_ADDR + 32'h18;
    localparam  TRANS_MODE          = BASE_ADDR + 32'h1C;
    localparam  STATUS              = BASE_ADDR + 32'h20;
    localparam  RD_PENDING_VOLUME   = BASE_ADDR + 32'h24;
    localparam  WR_PENDING_VOLUME   = BASE_ADDR + 32'h28;
    localparam  INTR_EN             = BASE_ADDR + 32'h2C;
    localparam  INTR_CLR            = BASE_ADDR + 32'h30;

    localparam  RD_DONE_LOC     = 0;
    localparam  WR_DONE_LOC     = 1;
    localparam  BUSY_LOC        = 2;
    localparam  RD_PENDING_LOC  = 3;
    localparam  WR_PENDING_LOC  = 4;

    localparam  ONE_TRANSFER    = 8;
    localparam  SOURCE_ID       = {SOURCE, 2'b0};
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    typedef enum logic[2:0] {READ_IDLE, READ_REQ, READ_FIFO_SWITCH, WAIT_READ, GRANT_ACK, RD_PENDING} read_state_e;
    typedef enum logic[2:0] {WRITE_IDLE, WRITE, WRITE_FIFO_SWITCH, SEND_DATA,WAIT_WRITE,WR_PENDING} write_state_e;
    typedef enum logic[0:0] {IDLE,BUSY} fifo_state_e;
    read_state_e    read_state_d, read_state_q;
    write_state_e   write_state_d, write_state_q;

    logic                                   dma_en;
    logic                                   dma_we;
    logic [ADDR_WIDTH-1:0]                  dma_addr;
    logic [DATA_WIDTH-1:0]                  dma_wdata;
    logic [DATA_WIDTH-1:0]                  dma_rdata;

    logic [DATA_WIDTH-1:0]                  dma_rdata_d,dma_rdata_q;
    logic [31:0]                            src_base_addr_d, src_base_addr_q;
    logic [31:0]                            src_base_addrh_d, src_base_addrh_q;
    logic [31:0]                            des_base_addr_d, des_base_addr_q;
    logic [31:0]                            des_base_addrh_d, des_base_addrh_q;
    logic [31:0]                            data_volume_d, data_volume_q;
    logic [7:0]                             rd_burst_len_d, rd_burst_len_q;
    logic [7:0]                             wr_burst_len_d, wr_burst_len_q;
    logic [31:0]                            rd_pending_volume_d, rd_pending_volume_q;
    logic [31:0]                            wr_pending_volume_d, wr_pending_volume_q;
    logic [31:0]                            trans_ctrl_d, trans_ctrl_q;
    logic                                   dma_start_d, dma_start_q;
    logic [31:0]                            trans_mode_d, trans_mode_q;
    logic [31:0]                            status_d, status_q;
    logic                                   intr_en_d, intr_en_q;
    logic                                   intr_d, intr_q;
    logic                                   intr_clr;
    logic                                   rd_reset_done,wr_reset_done;        
    logic                                   read_pending;
    logic                                   write_pending;
    logic                                   set_rd_pending;
    logic                                   set_wr_pending;
    logic[1:0]                              reset_d,reset_q;
    logic                                   rd_reset_done_d,rd_reset_done_q;
    logic                                   wr_reset_done_d,wr_reset_done_q;
    logic                                   read_burst_type; // 0 for increment, 1 for fixed
    logic                                   write_burst_type; // 0 for increment, 1 for fixed
    logic                                   read_en_realign;           
    logic                                   write_en_realign;           
    logic                                   rd_single_step;
    logic                                   wr_single_step;
    logic                                   rd_single_step_fix;
    logic                                   wr_single_step_fix;
    logic                                   rd_wr_seq;
    fifo_state_e[1:0]                       fifo_status_d,fifo_status_q;        
    logic                                   read_use_fifo_d,read_use_fifo_q;
    logic                                   write_use_fifo_d,write_use_fifo_q;

    logic [1:0]                             fifo_full;
    logic [1:0]                             fifo_afull;
    logic [1:0]                             fifo_empty;
    logic [1:0]                             fifo_push;
    logic [1:0]                             fifo_pop;
    logic [1:0][63:0]                       fifo_data_in;
    logic [1:0][63:0]                       fifo_data_out;
    logic [63:0]                            fifo_data_out_mux;
    logic [63:0]                            wdata;

    logic [39:0]                            read_addr_d, read_addr_q; 
    logic [39:0]                            write_addr_d, write_addr_q; 
    logic [39:0]                            release_addr_d, release_addr_q; 
    logic [31:0]                            left_read_data_d, left_read_data_q;
    logic [31:0]                            left_write_data_d, left_write_data_q;
    logic [7:0]                             read_trans_cnt_d, read_trans_cnt_q;
    logic [7:0]                             write_trans_cnt_d, write_trans_cnt_q;
    logic                                   read_ready, read_valid;
    logic                                   write_ready, write_valid;
    logic                                   set_rd_done;
    logic                                   set_wr_done;
    logic                                   set_busy;   
    logic                                   start_dma;     
    logic                                   src_cacheable;            
    logic                                   des_cacheable;
    logic [tl_pkg::SINK_WTH-1:0]            sink_d, sink_q;
    logic                                   lock_data,lock_data_dly;
    logic[63:0]                             send_data_d,send_data_q;
    logic                                   seq_ctrl_d,seq_ctrl_q;
    logic                                   clr_fifo;
    logic[31:0]                             rd_pending_cnt_d,rd_pending_cnt_q;
    logic[31:0]                             wr_pending_cnt_d,wr_pending_cnt_q;
    logic                                   first_write_d,first_write_q;    
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

        .addr_o             ( dma_addr      ),
        .en_o               ( dma_en        ),
        .we_o               ( dma_we        ),
        .wdata_o            ( dma_wdata     ),
        .rdata_i            ( dma_rdata     )
    );
    assign dma_rdata = dma_rdata_q;

    assign clr_fifo = rd_reset_done_q & wr_reset_done_q;
    // ping-pong buffer
    for (genvar i = 0; i < 2; i = i + 1) begin
        assign fifo_data_in[i] = oup_tl_D_bits_i.data;
        sy_dma_fifo fifo (
            .clk_i              (clk_i),                 
            .rst_i              (rst_i),                 
            .clr_i              (clr_fifo),    

            .full_o             (fifo_full[i]),                  
            .afull_o            (fifo_afull[i]),                  
            .empty_o            (fifo_empty[i]),                  

            .data_i             (fifo_data_in[i]),                  
            .data_o             (fifo_data_out[i]),                  
            .push_i             (fifo_push[i]),                  
            .pop_i              (fifo_pop[i])               
        );       
    end
    assign fifo_data_out_mux = fifo_data_out[write_use_fifo_q];
    assign wdata = fifo_data_out_mux;
//======================================================================================================================
// Control Register
//======================================================================================================================
    always_comb begin
        src_base_addr_d = src_base_addr_q;
        src_base_addrh_d = src_base_addrh_q;
        des_base_addr_d = des_base_addr_q;
        des_base_addrh_d = des_base_addrh_q;
        data_volume_d   = data_volume_q;
        rd_burst_len_d  = rd_burst_len_q;
        wr_burst_len_d  = wr_burst_len_q;
        dma_start_d     = dma_start_q;
        trans_mode_d    = trans_mode_q;
        reset_d         = reset_q;
        status_d        = status_q;
        rd_pending_volume_d   = rd_pending_volume_q;
        wr_pending_volume_d   = wr_pending_volume_q;
        intr_en_d       = intr_en_q;
        intr_d          = intr_q;
        intr_clr        = 1'b0;
        dma_rdata_d     = dma_rdata_q;
        if (dma_en) begin
            unique case (dma_addr)
                SRC_BASE_ADDR: begin
                    src_base_addr_d = dma_we ? dma_wdata : src_base_addr_q;
                    dma_rdata_d = src_base_addr_q;
                end
                SRC_BASE_ADDRH: begin
                    src_base_addrh_d = dma_we ? dma_wdata : src_base_addrh_q;
                    dma_rdata_d = src_base_addrh_q;
                end
                DES_BASE_ADDR: begin
                    des_base_addr_d = dma_we ? dma_wdata : des_base_addr_q;
                    dma_rdata_d = des_base_addr_q;
                end
                DES_BASE_ADDRH: begin
                    des_base_addrh_d = dma_we ? dma_wdata : des_base_addrh_q;
                    dma_rdata_d = des_base_addrh_q;
                end
                DATA_VOLUME: begin
                    data_volume_d = dma_we ? dma_wdata : data_volume_q;
                    dma_rdata_d = data_volume_q;
                end
                BURST_LENGTH: begin
                    rd_burst_len_d = dma_we ? dma_wdata[7:0]  : rd_burst_len_q;
                    wr_burst_len_d = dma_we ? dma_wdata[15:8] : wr_burst_len_q;
                    dma_rdata_d = {wr_burst_len_q,rd_burst_len_q};
                end
                TRANS_CTRL: begin
                    dma_start_d = dma_we ? dma_wdata[0] : dma_start_q;
                    reset_d     = dma_we ? dma_wdata[2:1] : reset_q;
                    // trans_ctrl_d = dma_we ? dma_wdata : trans_ctrl_q;
                    dma_rdata_d = {reset_q,dma_start_q};
                end
                TRANS_MODE: begin
                    trans_mode_d = dma_we ? dma_wdata : trans_mode_q;
                    dma_rdata_d = trans_mode_q;
                end
                STATUS: begin
                    status_d = dma_we ? dma_wdata : status_q;                   
                    dma_rdata_d = status_q;
                end
                RD_PENDING_VOLUME: begin
                    rd_pending_volume_d = dma_we ? dma_wdata : rd_pending_volume_q;
                    dma_rdata_d = rd_pending_volume_q;
                end
                WR_PENDING_VOLUME: begin
                    wr_pending_volume_d = dma_we ? dma_wdata : wr_pending_volume_q;
                    dma_rdata_d = wr_pending_volume_q;
                end
                INTR_EN: begin
                    intr_en_d = dma_we ? dma_wdata[0] : intr_en_q;
                    dma_rdata_d = {31'h0,intr_en_q};
                end
                INTR_CLR: begin
                    intr_clr = dma_we;
                end
                default: begin
                    dma_rdata_d = 32'h0;
                end
            endcase    
        end
        if (rd_reset_done || wr_reset_done) begin
            status_d[RD_DONE_LOC] = 1'b1;
            status_d[WR_DONE_LOC] = 1'b1;
            status_d[BUSY_LOC]    = 1'b0;
            dma_start_d = 1'b0;
        end
        // read data finish
        if (set_rd_done) begin
            status_d[RD_DONE_LOC] = 1'b1;           
        end
        // write data finish
        if (set_wr_done) begin
            status_d[WR_DONE_LOC] = 1'b1;
            status_d[BUSY_LOC]    = 1'b0;
            dma_start_d = 1'b0;
        end
        if (set_busy) begin
            status_d[BUSY_LOC]    = 1'b1;
        end
        if (rd_reset_done) begin
            reset_d[0] = 1'b0;
        end
        if (wr_reset_done) begin
            reset_d[1] = 1'b0;
        end
        if (set_rd_pending) begin
            status_d[RD_PENDING_LOC] = 1'b1;
        end 
        if (set_wr_pending) begin
            status_d[WR_PENDING_LOC] = 1'b1;
        end 
        // set and clear interrupt
        if (set_wr_done && intr_en_q) begin
            intr_d = 1'b1;
        end else if (intr_clr) begin
            intr_d = 1'b0;
        end
    end
    assign irq_o = intr_q;

    assign src_cacheable = is_cacheable({src_base_addrh_q,src_base_addr_q});
    assign des_cacheable = is_cacheable({des_base_addrh_q,des_base_addr_q});
    assign start_dma = dma_start_q;

    assign read_burst_type  = trans_mode_q[0];
    assign write_burst_type = trans_mode_q[1];
    assign rd_single_step   = trans_mode_q[2];
    assign wr_single_step   = trans_mode_q[3];
    assign rd_wr_seq        = trans_mode_q[4]; // make read and write sequential
    assign rd_single_step_fix = trans_mode_q[5];
    assign wr_single_step_fix = trans_mode_q[6];

    assign read_pending     = status_q[RD_PENDING_LOC];
    assign write_pending    = status_q[WR_PENDING_LOC];
//======================================================================================================================
// FSM
//======================================================================================================================
    always_comb begin : fsm
        // default assignment
        read_state_d        = read_state_q;
        write_state_d       = write_state_q;
        fifo_push           = 2'b0;
        fifo_pop            = 2'b0;

        read_addr_d         = read_addr_q;
        write_addr_d        = write_addr_q;
        left_read_data_d    = left_read_data_q;
        left_write_data_d   = left_write_data_q;
        read_trans_cnt_d    = read_trans_cnt_q;
        write_trans_cnt_d   = write_trans_cnt_q;
        read_use_fifo_d     = read_use_fifo_q;
        write_use_fifo_d    = write_use_fifo_q;
        fifo_status_d       = fifo_status_q;
        seq_ctrl_d          = seq_ctrl_q;
        rd_pending_cnt_d    = rd_pending_cnt_q;
        wr_pending_cnt_d    = wr_pending_cnt_q;
        first_write_d       = first_write_q;
        rd_reset_done_d     = rd_reset_done_q;
        wr_reset_done_d     = wr_reset_done_q;

        release_addr_d      = release_addr_q;
        oup_tl_A_valid_o    = 1'b0;
        oup_tl_C_valid_o    = 1'b0;
        oup_tl_E_valid_o    = 1'b0;

        read_ready          = 1'b0;
        write_ready         = 1'b0;

        set_rd_done         = 1'b0;
        set_wr_done         = 1'b0;
        set_busy            = 1'b0;

        lock_data           = 1'b0;
        rd_reset_done       = 1'b0;
        wr_reset_done       = 1'b0;
        set_rd_pending      = 1'b0;
        set_wr_pending      = 1'b0;

        // read logic 
        case (read_state_q)
            READ_IDLE: begin
                if (reset_q[0]) begin
                    rd_reset_done = 1'b1;
                    rd_reset_done_d = 1'b1;
                end else if (start_dma && write_state_q == WRITE_IDLE) begin
                    set_busy = 1'b1; // set busy in case new dma request comes
                    read_addr_d = {src_base_addrh_q[7:0],src_base_addr_q};
                    left_read_data_d = data_volume_q;
                    read_use_fifo_d = 1'b0; // fifo a is in read state
                    fifo_status_d[read_use_fifo_d] = BUSY; // fifo is busy which means it can not be used by write fsm
                    read_state_d = rd_single_step ? RD_PENDING : READ_REQ;
                    set_rd_pending = rd_single_step;
                    rd_pending_cnt_d = 0;
                    seq_ctrl_d = 1'b0;
                end
            end
            READ_REQ: begin
                // read data finish
                if (reset_q[0]) begin
                    read_state_d = READ_IDLE;
                    rd_reset_done = 1'b1;
                    rd_reset_done_d = 1'b1;
                    fifo_status_d[read_use_fifo_q] = IDLE;
                end else if (left_read_data_q == 0) begin
                    read_state_d = READ_IDLE;
                    fifo_status_d[read_use_fifo_q] = IDLE; // release fifo
                    seq_ctrl_d = 1'b1;
                    set_rd_done = 1'b1;
                    // set_rd_pending = rd_single_step;
                // fifo is full , we need to switch to another fifo
                end else if (fifo_full[read_use_fifo_q]) begin 
                    read_use_fifo_d = ~read_use_fifo_q;
                    fifo_status_d[read_use_fifo_q] = IDLE; // release fifo
                    read_state_d = READ_FIFO_SWITCH;
                    seq_ctrl_d = 1'b1;
                end else if (rd_pending_cnt_q == rd_pending_volume_q && rd_single_step) begin
                    read_state_d = RD_PENDING;   
                    set_rd_pending = 1'b1;
                    rd_pending_cnt_d = 0;
                // send read request
                end else begin
                    oup_tl_A_valid_o = 1'b1;
                    if (oup_tl_A_valid_o && oup_tl_A_ready_i) begin
                        read_trans_cnt_d = rd_burst_len_q;
                        read_state_d = WAIT_READ;
                    end
                end
            end
            READ_FIFO_SWITCH: begin
                if (reset_q[0]) begin
                    read_state_d = READ_IDLE;
                    rd_reset_done = 1'b1;
                    rd_reset_done_d = 1'b1;
                    fifo_status_d[read_use_fifo_q] = IDLE;
                // if another fifo is busy, wait until it is ready
                end else if (fifo_status_q[read_use_fifo_q] == BUSY || (seq_ctrl_q && rd_wr_seq)) begin
                    read_state_d = READ_FIFO_SWITCH;
                end else begin
                    fifo_status_d[read_use_fifo_q] = BUSY;
                    if (rd_pending_cnt_q == rd_pending_volume_q && rd_single_step) begin
                        read_state_d = RD_PENDING;   
                        set_rd_pending = 1'b1;
                        rd_pending_cnt_d = 0;   
                    end else begin
                        read_state_d = READ_REQ;
                    end
                end
            end
            WAIT_READ: begin
                read_ready = 1'b1;    
                if (read_valid && read_ready) begin
                    fifo_push[read_use_fifo_q] = 1'b1;
                    left_read_data_d = left_read_data_q - ONE_TRANSFER;
                    // increment read address or unchange
                    read_addr_d = read_burst_type ? read_addr_q : (read_addr_q + ONE_TRANSFER);
                    rd_pending_cnt_d = rd_pending_cnt_q + ONE_TRANSFER;
                    if (read_trans_cnt_q == 1) begin
                        // read_state_d = src_cacheable ? GRANT_ACK : (rd_single_step ? RD_PENDING: READ_REQ);
                        read_state_d = src_cacheable ? GRANT_ACK : READ_REQ;
                        // set_rd_pending = rd_single_step & !src_cacheable;
                    end else begin
                        read_trans_cnt_d = read_trans_cnt_q - 1; 
                    end
               end
            end
            GRANT_ACK: begin
                oup_tl_E_valid_o = 1'b1;
                if (oup_tl_E_ready_i) begin
                    // read_state_d = (rd_single_step ? RD_PENDING: READ_REQ);
                    read_state_d = READ_REQ;
                    // set_rd_pending = rd_single_step;
                end
            end
            RD_PENDING: begin 
                // pending bit will be clear by CPU
                if (!read_pending) begin
                    read_state_d = READ_REQ;
                    if (rd_single_step_fix) begin
                        read_addr_d = {src_base_addrh_q[7:0],src_base_addr_q};
                    end
                end
            end
           default : read_state_d = READ_IDLE;
        endcase
        // write logic 
        case (write_state_q)
            WRITE_IDLE: begin
                write_ready = 1'b1;
                if (reset_q[1]) begin
                    write_state_d = WRITE_IDLE;
                    wr_reset_done = 1'b1;
                    wr_reset_done_d = 1'b1;
                end else if (start_dma) begin
                    write_state_d       = WRITE_FIFO_SWITCH;
                    write_use_fifo_d    = 1'b0; // use fifo a
                    write_addr_d        = {des_base_addrh_q[7:0],des_base_addr_q};
                    left_write_data_d   = data_volume_q;
                    write_trans_cnt_d   = wr_burst_len_q;
                    release_addr_d      = {des_base_addrh_q[7:0],des_base_addr_q};
                    wr_pending_cnt_d    = 0;
                    first_write_d       = 1'b1;
                end 
            end
            WRITE: begin
                if (left_write_data_q == 0) begin
                    write_state_d     = WRITE_IDLE;
                    set_wr_done       = 1'b1;
                    // set_wr_pending = wr_single_step;
                    fifo_status_d[write_use_fifo_q] = IDLE;
                end else if (write_trans_cnt_q == 0) begin
                    write_state_d = WAIT_WRITE; 
                end else if (fifo_empty[write_use_fifo_q]) begin
                    write_state_d = WRITE_FIFO_SWITCH;
                    write_use_fifo_d = ~write_use_fifo_q;
                    fifo_status_d[write_use_fifo_q] = IDLE; // release fifo
                    seq_ctrl_d = 1'b0;
                end else if (wr_pending_cnt_q == wr_pending_volume_q && wr_single_step) begin
                    write_state_d = WR_PENDING;
                    set_wr_pending = 1'b1;   
                    wr_pending_cnt_d = 0;
                end else begin
                    fifo_pop[write_use_fifo_q] = 1'b1;
                    write_state_d = SEND_DATA; 
                    lock_data = 1'b1;
                end
            end
            WRITE_FIFO_SWITCH: begin
                if (reset_q[1]) begin
                    write_state_d = WRITE_IDLE;
                    wr_reset_done = 1'b1;
                    wr_reset_done_d = 1'b1;
                    fifo_status_d[write_use_fifo_q] = IDLE;
                // wait until another fifo is ready
                end else if (fifo_status_q[write_use_fifo_q] == BUSY || !seq_ctrl_q && rd_wr_seq) begin
                    write_state_d = WRITE_FIFO_SWITCH;
                end else begin
                    fifo_status_d[write_use_fifo_q] = BUSY; // use fifo
                    if (wr_single_step && (wr_pending_cnt_q == wr_pending_volume_q || first_write_q)) begin
                        write_state_d = WR_PENDING;
                        set_wr_pending = 1'b1;
                        wr_pending_cnt_d = 0;
                        first_write_d = 1'b0;
                    end else begin
                        write_state_d = WRITE;
                    end
                end
            end
            SEND_DATA : begin
                oup_tl_C_valid_o = 1'b1;        
                if (oup_tl_C_valid_o && oup_tl_C_ready_i) begin
                    // fifo_pop = 1'b1;    
                    left_write_data_d = left_write_data_q - ONE_TRANSFER;
                    write_addr_d = write_burst_type ? write_addr_q : (write_addr_q + ONE_TRANSFER);
                    wr_pending_cnt_d = wr_pending_cnt_q + ONE_TRANSFER;
                    write_trans_cnt_d = write_trans_cnt_q - 1;
                    write_state_d = WRITE;
                end
            end
            WAIT_WRITE : begin
                write_ready = 1'b1;    
                if (write_valid && write_ready) begin
                    write_state_d = WRITE;
                    write_trans_cnt_d = wr_burst_len_q;
                    release_addr_d = write_addr_q;
                    if (reset_q[1]) begin
                        write_state_d = WRITE_IDLE;
                        wr_reset_done = 1'b1;
                        wr_reset_done_d = 1'b1;
                        fifo_status_d[write_use_fifo_q] = IDLE;
                    end
                end
            end
            WR_PENDING: begin 
                // pending bit will be clear by CPU
                if (!write_pending) begin
                    write_state_d = WRITE;
                    if (wr_single_step_fix) begin
                        write_addr_d = {des_base_addrh_q[7:0],des_base_addr_q};
                    end
                end
            end
        endcase
        if (|reset_q) begin
            fifo_status_d[0] = IDLE;
            fifo_status_d[1] = IDLE;
        end
        if (clr_fifo) begin
            rd_reset_done_d = 1'b0;
            wr_reset_done_d = 1'b0;
        end
    end
//======================================================================================================================
// TileLink interface
//======================================================================================================================
    assign oup_tl_A_bits_o.opcode  = src_cacheable ? tl_pkg::AcquireBlock : tl_pkg::Get;
    assign oup_tl_A_bits_o.address = read_addr_q;
    assign oup_tl_A_bits_o.param   = tl_pkg::NtoB; //default value
    assign oup_tl_A_bits_o.size    = rd_burst_len_q - 1; 
    assign oup_tl_A_bits_o.source  = SOURCE_ID;
    assign oup_tl_A_bits_o.mask    = 8'hff;
    assign oup_tl_A_bits_o.data    = '0;
    assign oup_tl_A_bits_o.corrupt = '0;

    assign oup_tl_E_bits_o.sink    = sink_q;

    assign oup_tl_C_bits_o.opcode  = des_cacheable ? tl_pkg::ReleaseData : tl_pkg::PutFullData;
    assign oup_tl_C_bits_o.param   = tl_pkg::TtoB; //default value
    assign oup_tl_C_bits_o.size    = wr_burst_len_q - 1; 
    assign oup_tl_C_bits_o.source  = SOURCE_ID;
    assign oup_tl_C_bits_o.address = release_addr_q;
    assign oup_tl_C_bits_o.data    = send_data_d;
    assign oup_tl_C_bits_o.corrupt = '0;

    assign read_valid = oup_tl_D_valid_i && 
                    (oup_tl_D_bits_i.opcode == tl_pkg::GrantData || oup_tl_D_bits_i.opcode == tl_pkg::AccessAckData);
    assign write_valid = oup_tl_D_valid_i && 
                    (oup_tl_D_bits_i.opcode == tl_pkg::ReleaseAck || oup_tl_D_bits_i.opcode == tl_pkg::AccessAck);
    assign oup_tl_D_ready_o = read_ready || write_ready;


    assign send_data_d = lock_data_dly ? wdata : send_data_q;

    assign sink_d = oup_tl_D_valid_i && oup_tl_D_ready_o ? oup_tl_D_bits_i.sink : sink_q;

    // unused signal
    assign oup_tl_B_ready_o = 1'b1;
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            read_state_q        <= `TCQ READ_IDLE;
            write_state_q       <= `TCQ WRITE_IDLE;
            src_base_addr_q     <= `TCQ '0;
            des_base_addr_q     <= `TCQ '0;
            src_base_addrh_q    <= `TCQ '0;
            des_base_addrh_q    <= `TCQ '0;
            data_volume_q       <= `TCQ '0;
            rd_burst_len_q      <= `TCQ '0;
            wr_burst_len_q      <= `TCQ '0;
            dma_start_q         <= `TCQ '0;
            trans_mode_q        <= `TCQ '0;
            reset_q             <= `TCQ '0;
            status_q            <= `TCQ '0;
            fifo_status_q       <= `TCQ {IDLE, IDLE};
            read_use_fifo_q     <= `TCQ '0;
            write_use_fifo_q    <= `TCQ '0;
            read_addr_q         <= `TCQ '0;
            write_addr_q        <= `TCQ '0;
            left_read_data_q    <= `TCQ '0;
            left_write_data_q   <= `TCQ '0;
            read_trans_cnt_q    <= `TCQ '0;
            write_trans_cnt_q   <= `TCQ '0;
            release_addr_q      <= `TCQ '0;
            send_data_q         <= `TCQ '0;
            lock_data_dly       <= `TCQ '0;
            seq_ctrl_q          <= `TCQ 1'b0;
            sink_q              <= `TCQ tl_pkg::SINK_WTH'(0);
            rd_pending_volume_q <= `TCQ '0;
            rd_pending_cnt_q    <= `TCQ '0;
            wr_pending_volume_q <= `TCQ '0;
            wr_pending_cnt_q    <= `TCQ '0;
            first_write_q       <= `TCQ 1'b0;
            dma_rdata_q         <= `TCQ '0;
            intr_en_q           <= `TCQ 1'b0;
            intr_q              <= `TCQ 1'b0;
            rd_reset_done_q     <= `TCQ 1'b0;
            wr_reset_done_q     <= `TCQ 1'b0;
        end else begin
            read_state_q        <= `TCQ read_state_d     ;
            write_state_q       <= `TCQ write_state_d    ;
            src_base_addr_q     <= `TCQ src_base_addr_d  ;
            des_base_addr_q     <= `TCQ des_base_addr_d  ;
            src_base_addrh_q    <= `TCQ src_base_addrh_d ;
            des_base_addrh_q    <= `TCQ des_base_addrh_d ;
            data_volume_q       <= `TCQ data_volume_d    ;
            rd_burst_len_q      <= `TCQ rd_burst_len_d   ;
            wr_burst_len_q      <= `TCQ wr_burst_len_d   ;
            dma_start_q         <= `TCQ dma_start_d      ;
            reset_q             <= `TCQ reset_d          ;
            status_q            <= `TCQ status_d         ;
            fifo_status_q       <= `TCQ fifo_status_d    ;
            read_use_fifo_q     <= `TCQ read_use_fifo_d  ;
            write_use_fifo_q    <= `TCQ write_use_fifo_d ;
            read_addr_q         <= `TCQ read_addr_d      ;
            write_addr_q        <= `TCQ write_addr_d     ;
            left_read_data_q    <= `TCQ left_read_data_d ;
            left_write_data_q   <= `TCQ left_write_data_d;
            read_trans_cnt_q    <= `TCQ read_trans_cnt_d ;
            write_trans_cnt_q   <= `TCQ write_trans_cnt_d;
            release_addr_q      <= `TCQ release_addr_d   ;
            send_data_q         <= `TCQ send_data_d      ;
            trans_mode_q        <= `TCQ trans_mode_d     ;
            lock_data_dly       <= `TCQ lock_data        ;
            seq_ctrl_q          <= `TCQ seq_ctrl_d       ;
            sink_q              <= `TCQ sink_d           ;
            rd_pending_volume_q <= `TCQ rd_pending_volume_d;
            rd_pending_cnt_q    <= `TCQ rd_pending_cnt_d   ;
            wr_pending_volume_q <= `TCQ wr_pending_volume_d;
            wr_pending_cnt_q    <= `TCQ wr_pending_cnt_d   ;
            first_write_q       <= `TCQ first_write_d      ;
            dma_rdata_q         <= `TCQ dma_rdata_d;
            intr_en_q           <= `TCQ intr_en_d;
            intr_q              <= `TCQ intr_d;
            rd_reset_done_q     <= `TCQ rd_reset_done_d;
            wr_reset_done_q     <= `TCQ wr_reset_done_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
// (* mark_debug = "true" *) read_state_e  prb_dma_rd_state;
// (* mark_debug = "true" *) write_state_e prb_dma_wr_state;

// assign prb_dma_rd_state = read_state_q;
// assign prb_dma_wr_state = write_state_q;

// (* mark_debug = "true" *) logic         prb_dma_A_valid;
// (* mark_debug = "true" *) logic         prb_dma_A_ready;
// (* mark_debug = "true" *) logic[31:0]   prb_dma_A_addr;

// (* mark_debug = "true" *) logic         prb_dma_D_valid;
// (* mark_debug = "true" *) logic         prb_dma_D_ready;
// (* mark_debug = "true" *) logic[63:0]   prb_dma_D_data;

// (* mark_debug = "true" *) logic         prb_dma_C_valid;
// (* mark_debug = "true" *) logic         prb_dma_C_ready;
// (* mark_debug = "true" *) logic[31:0]   prb_dma_C_addr;
// (* mark_debug = "true" *) logic[63:0]   prb_dma_C_data;

// assign prb_dma_A_valid  = oup_tl_A_valid_o;
// assign prb_dma_A_ready  = oup_tl_A_ready_i;
// assign prb_dma_A_addr   = oup_tl_A_bits_o.address;

// assign prb_dma_D_valid  = oup_tl_D_valid_i;
// assign prb_dma_D_ready  = oup_tl_D_ready_o;
// assign prb_dma_D_data   = oup_tl_D_bits_i.data;

// assign prb_dma_C_valid  = oup_tl_C_valid_o;
// assign prb_dma_C_ready  = oup_tl_C_ready_i;
// assign prb_dma_C_addr   = oup_tl_C_bits_o.address;
// assign prb_dma_C_data   = oup_tl_C_bits_o.data;

endmodule