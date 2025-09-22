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
    parameter BASE_ADDR  = 64'h3_0000,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter SOURCE     = 0
)(
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // used to read/write control register
    TL_BUS.Master                       master, 
    // read data
    TL_BUS.Slave                        slave 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam  SRC_BASE_ADDR   = BASE_ADDR + 64'h0;
    localparam  DES_BASE_ADDR   = BASE_ADDR + 64'h8;
    localparam  DATA_VOLUME     = BASE_ADDR + 64'h10;
    localparam  BURST_LENGTH    = BASE_ADDR + 64'h18;
    localparam  TRANS_CTRL      = BASE_ADDR + 64'h1C;
    localparam  TRANS_MODE      = BASE_ADDR + 64'h20;
    localparam  STATUS          = BASE_ADDR + 64'h24;

    localparam  DONE_LOC        = 0;
    localparam  BUSY_LOC        = 1;
    localparam  RD_PENDING_LOC  = 2;
    localparam  WR_PENDING_LOC  = 3;

    localparam  ONE_TRANSFER    = 8;
    localparam  SOURCE_ID       = {SOURCE, 1'b0};
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
    logic [DATA_WIDTH-1:0]                  dma_rdata;
    logic [ADDR_WIDTH-1:0]                  dma_addr;
    logic [DATA_WIDTH-1:0]                  dma_wdata;

    logic [31:0]                            src_base_addr_d, src_base_addr_q;
    logic [31:0]                            des_base_addr_d, des_base_addr_q;
    logic [31:0]                            data_volume_d, data_volume_q;
    logic [7:0]                             rd_burst_len_d, rd_burst_len_q;
    logic [7:0]                             wr_burst_len_d, wr_burst_len_q;
    logic [31:0]                            trans_ctrl_d, trans_ctrl_q;
    logic                                   dma_start_d, dma_start_q;
    logic [31:0]                            trans_mode_d, trans_mode_q;
    logic [31:0]                            status_d, status_q;
    logic                                   rd_reset_done,wr_reset_done;        
    logic                                   read_pending;
    logic                                   write_pending;
    logic                                   set_rd_pending;
    logic                                   set_wr_pending;
    logic[1:0]                              reset_d,reset_q;
    logic                                   read_burst_type; // 0 for increment, 1 for fixed
    logic                                   write_burst_type; // 0 for increment, 1 for fixed
    logic                                   read_en_realign;           
    logic                                   write_en_realign;           
    logic                                   rd_single_step;
    logic                                   wr_single_step;
    fifo_state_e[1:0]                       fifo_status_d,fifo_status_q;        
    logic                                   read_use_fifo_d,read_use_fifo_q;
    logic                                   write_use_fifo_d,write_use_fifo_q;

    logic [1:0]                             fifo_full;
    logic [1:0]                             fifo_afull;
    logic [1:0]                             fifo_empty;
    logic [1:0]                             fifo_push;
    logic [1:0]                             fifo_pop;
    logic [1:0][DATA_WIDTH-1:0]             fifo_data_in;
    logic [1:0][DATA_WIDTH-1:0]             fifo_data_out;
    logic [DATA_WIDTH-1:0]                  fifo_data_out_mux;
    logic [DATA_WIDTH-1:0]                  rdata_realign;
    logic [DATA_WIDTH-1:0]                  wdata_realign;
    logic [DATA_WIDTH-1:0]                  wdata;

    logic [ADDR_WIDTH-1:0]                  read_addr_d, read_addr_q; 
    logic [ADDR_WIDTH-1:0]                  write_addr_d, write_addr_q; 
    logic [ADDR_WIDTH-1:0]                  release_addr_d, release_addr_q; 
    logic [31:0]                            left_read_data_d, left_read_data_q;
    logic [31:0]                            left_write_data_d, left_write_data_q;
    logic [7:0]                             read_trans_cnt_d, read_trans_cnt_q;
    logic [7:0]                             write_trans_cnt_d, write_trans_cnt_q;
    logic                                   read_ready, read_valid;
    logic                                   write_ready, write_valid;
    logic                                   set_done;
    logic                                   set_busy;   
    logic                                   start_dma;     
    logic                                   src_cacheable;            
    logic                                   des_cacheable;
    logic [tl_pkg::SINK_WTH-1:0]            sink_d, sink_q;
    logic                                   lock_data,lock_data_dly;
    logic[DATA_WIDTH-1:0]                   send_data_d,send_data_q;
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

        .addr_o             ( dma_addr      ),
        .en_o               ( dma_en        ),
        .we_o               ( dma_we        ),
        .wdata_o            ( dma_wdata     ),
        .rdata_i            ( dma_rdata     )
    );

    // ping-pong buffer
    for (genvar i = 0; i < 2; i = i + 1) begin
        assign fifo_data_in[i] = read_en_realign ? rdata_realign : slave.d_bits.data;
        sy_dma_fifo fifo (
            .clk_i              (clk_i),                 
            .rst_i              (rst_i),                 
            .clr_i              (|reset_q),    

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
    assign rdata_realign = {slave.d_bits.data[39:32],slave.d_bits.data[47:40],slave.d_bits.data[55:48],slave.d_bits.data[63:56],
                            slave.d_bits.data[7:0],  slave.d_bits.data[15:8], slave.d_bits.data[23:16],slave.d_bits.data[31:24]};
    assign wdata_realign = {fifo_data_out_mux[39:32],
                            fifo_data_out_mux[47:40],
                            fifo_data_out_mux[55:48],
                            fifo_data_out_mux[63:56],
                            fifo_data_out_mux[7:0],  
                            fifo_data_out_mux[15:8], 
                            fifo_data_out_mux[23:16],
                            fifo_data_out_mux[31:24]};
    assign wdata = write_en_realign ? wdata_realign : fifo_data_out_mux;
//======================================================================================================================
// Control Register
//======================================================================================================================
    always_comb begin
        src_base_addr_d = src_base_addr_q;
        des_base_addr_d = des_base_addr_q;
        data_volume_d   = data_volume_q;
        rd_burst_len_d  = rd_burst_len_q;
        wr_burst_len_d  = wr_burst_len_q;
        dma_start_d     = dma_start_q;
        trans_mode_d    = trans_mode_q;
        reset_d         = reset_q;
        status_d        = status_q;
        dma_rdata       = '0;
        if (dma_en) begin
            unique case (dma_addr)
                SRC_BASE_ADDR: begin
                    src_base_addr_d = dma_we ? dma_wdata : src_base_addr_q;
                    dma_rdata = src_base_addr_q;
                end
                DES_BASE_ADDR: begin
                    des_base_addr_d = dma_we ? dma_wdata : des_base_addr_q;
                    dma_rdata = des_base_addr_q;
                end
                DATA_VOLUME: begin
                    data_volume_d = dma_we ? dma_wdata : data_volume_q;
                    dma_rdata = data_volume_q;
                end
                BURST_LENGTH: begin
                    rd_burst_len_d = dma_we ? dma_wdata[7:0]  : rd_burst_len_q;
                    wr_burst_len_d = dma_we ? dma_wdata[15:8] : wr_burst_len_q;
                    dma_rdata = {wr_burst_len_q,rd_burst_len_q};
                end
                TRANS_CTRL: begin
                    dma_start_d = dma_we ? dma_wdata[0] : dma_start_q;
                    reset_d     = dma_we ? dma_wdata[2:1] : reset_q;
                    // trans_ctrl_d = dma_we ? dma_wdata : trans_ctrl_q;
                    dma_rdata = {reset_q,dma_start_q};
                end
                TRANS_MODE: begin
                    trans_mode_d = dma_we ? dma_wdata : trans_mode_q;
                    dma_rdata = trans_mode_q;
                end
                STATUS: begin
                    status_d = dma_we ? dma_wdata : status_q;                   
                    dma_rdata = status_q;
                end
                default: ;
            endcase    
        end
        if (set_done || rd_reset_done || wr_reset_done) begin
            status_d[DONE_LOC]    = 1'b1;
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
    end

    assign src_cacheable = is_cacheable(src_base_addr_q);
    assign des_cacheable = is_cacheable(des_base_addr_q);
    assign start_dma = dma_start_q;
    assign read_en_realign  = trans_mode_q[0];
    assign write_en_realign = trans_mode_q[1];
    assign read_burst_type  = trans_mode_q[2];
    assign write_burst_type = trans_mode_q[3];
    assign rd_single_step   = trans_mode_q[4];
    assign wr_single_step   = trans_mode_q[5];
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

        release_addr_d      = release_addr_q;
        slave.a_valid       = 1'b0;
        slave.c_valid       = 1'b0;
        slave.e_valid       = 1'b0;

        read_ready          = 1'b0;
        write_ready         = 1'b0;

        set_done            = 1'b0;
        set_busy            = 1'b0;

        lock_data           = 1'b0;
        rd_reset_done       = 1'b0;
        wr_reset_done       = 1'b0;
        set_rd_pending      = 1'b0;
        set_wr_pending      = 1'b0;
        // read logic 
        case (read_state_q)
            READ_IDLE: begin
                if (reset_q) begin
                    rd_reset_done = 1'b1;
                end else if (start_dma && write_state_q == WRITE_IDLE) begin
                    set_busy = 1'b1; // set busy in case new dma request comes
                    read_addr_d = src_base_addr_q;
                    left_read_data_d = data_volume_q;
                    read_use_fifo_d = 1'b0; // fifo a is in read state
                    fifo_status_d[read_use_fifo_d] = BUSY; // fifo is busy which means it can not be used by write fsm
                    read_state_d = rd_single_step ? RD_PENDING : READ_REQ;
                    set_rd_pending = rd_single_step;
                end
            end
            READ_REQ: begin
                // read data finish
                if (reset_q) begin
                    read_state_d = READ_IDLE;
                    rd_reset_done = 1'b1;
                end else if (left_read_data_q == 0) begin
                    read_state_d = READ_IDLE;
                    fifo_status_d[read_use_fifo_q] = IDLE; // release fifo
                // fifo is full , we need to switch to another fifo
                end else if (fifo_full[read_use_fifo_q]) begin 
                    read_use_fifo_d = ~read_use_fifo_q;
                    fifo_status_d[read_use_fifo_q] = IDLE; // release fifo
                    read_state_d = READ_FIFO_SWITCH;
                // send read request
                end else begin
                    slave.a_valid = 1'b1;
                    if (slave.a_valid && slave.a_ready) begin
                        read_trans_cnt_d = rd_burst_len_q;
                        read_state_d = WAIT_READ;
                    end
                end
            end
            READ_FIFO_SWITCH: begin
                if (reset_q) begin
                    read_state_d = READ_IDLE;
                    rd_reset_done = 1'b1;
                // if another fifo is busy, wait until it is ready
                end else if (fifo_status_q[read_use_fifo_q] == BUSY) begin
                    read_state_d = READ_FIFO_SWITCH;
                end else begin
                    fifo_status_d[read_use_fifo_q] = BUSY;
                    read_state_d = READ_REQ;
                end
            end
            WAIT_READ: begin
                read_ready = 1'b1;    
                if (read_valid && read_ready) begin
                    fifo_push[read_use_fifo_q] = 1'b1;
                    left_read_data_d = left_read_data_q - ONE_TRANSFER;
                    // increment read address or unchange
                    read_addr_d = read_burst_type ? read_addr_q : (read_addr_q + ONE_TRANSFER);
                    if (read_trans_cnt_q == 1) begin
                        read_state_d = src_cacheable ? GRANT_ACK : (rd_single_step ? RD_PENDING: READ_REQ);
                        set_rd_pending = rd_single_step & !src_cacheable;
                    end else begin
                        read_trans_cnt_d = read_trans_cnt_q - 1; 
                    end
               end
            end
            GRANT_ACK: begin
                slave.e_valid = 1'b1;
                if (slave.e_ready) begin
                    read_state_d = (rd_single_step ? RD_PENDING: READ_REQ);
                    set_rd_pending = rd_single_step;
                end
            end
            RD_PENDING: begin 
                // pending bit will be clear by CPU
                if (!read_pending) begin
                    read_state_d = READ_REQ;
                end
            end
           default : read_state_d = READ_IDLE;
        endcase
        // write logic 
        case (write_state_q)
            WRITE_IDLE: begin
                if (reset_q) begin
                    write_state_d = WRITE_IDLE;
                    wr_reset_done = 1'b1;
                end else if (start_dma) begin
                    write_state_d       = WRITE_FIFO_SWITCH;
                    write_use_fifo_d    = 1'b0; // use fifo a
                    write_addr_d        = des_base_addr_q;
                    left_write_data_d   = data_volume_q;
                    write_trans_cnt_d   = wr_burst_len_q;
                    release_addr_d      = des_base_addr_q;
                end 
            end
            WRITE: begin
                if (reset_q) begin
                    write_state_d = WRITE_IDLE;
                    wr_reset_done = 1'b1;
                end else if (left_write_data_q == 0) begin
                    write_state_d     = WRITE_IDLE;
                    set_done          = 1'b1;
                    fifo_status_d[write_use_fifo_q] = IDLE;
                end else if (write_trans_cnt_q == 0) begin
                    write_state_d = WAIT_WRITE; 
                end else if (fifo_empty[write_use_fifo_q]) begin
                    write_state_d = WRITE_FIFO_SWITCH;
                    write_use_fifo_d = ~write_use_fifo_q;
                    fifo_status_d[write_use_fifo_q] = IDLE; // release fifo
                end else begin
                    fifo_pop[write_use_fifo_q] = 1'b1;
                    write_state_d = SEND_DATA; 
                    lock_data = 1'b1;
                end
            end
            WRITE_FIFO_SWITCH: begin
                if (reset_q) begin
                    write_state_d = WRITE_IDLE;
                    wr_reset_done = 1'b1;
                // wait until another fifo is ready
                end else if (fifo_status_q[write_use_fifo_q] == BUSY) begin
                    write_state_d = WRITE_FIFO_SWITCH;
                end else begin
                    write_state_d = wr_single_step ? WR_PENDING : WRITE;   
                    set_wr_pending = wr_single_step;
                    fifo_status_d[write_use_fifo_q] = BUSY; // use fifo
                end
            end
            SEND_DATA : begin
                slave.c_valid = 1'b1;        
                if (slave.c_valid && slave.c_ready) begin
                    // fifo_pop = 1'b1;    
                    left_write_data_d = left_write_data_q - ONE_TRANSFER;
                    write_addr_d = write_burst_type ? write_addr_q : (write_addr_q + ONE_TRANSFER);
                    write_trans_cnt_d = write_trans_cnt_q - 1;
                    write_state_d = WRITE;
                end
            end
            WAIT_WRITE : begin
                write_ready = 1'b1;    
                if (write_valid && write_ready) begin
                    write_state_d = wr_single_step ? WR_PENDING : WRITE;
                    set_wr_pending = wr_single_step;
                    write_trans_cnt_d = wr_burst_len_q;
                    release_addr_d = write_addr_q;
                end
            end
            WR_PENDING: begin 
                // pending bit will be clear by CPU
                if (!write_pending) begin
                    write_state_d = WRITE;
                end
            end
        endcase
    end
//======================================================================================================================
// TileLink interface
//======================================================================================================================
    assign slave.a_bits.opcode  = src_cacheable ? tl_pkg::AcquireBlock : tl_pkg::Get;
    assign slave.a_bits.address = read_addr_q;
    assign slave.a_bits.param   = tl_pkg::NtoB; //default value
    assign slave.a_bits.size    = rd_burst_len_q - 1; 
    assign slave.a_bits.source  = SOURCE_ID;
    assign slave.a_bits.mask    = 8'hff;
    assign slave.a_bits.data    = '0;
    assign slave.a_bits.corrupt = '0;

    assign slave.e_bits.sink    = sink_q;

    assign slave.c_bits.opcode  = des_cacheable ? tl_pkg::ReleaseData : tl_pkg::PutFullData;
    assign slave.c_bits.param   = tl_pkg::TtoB; //default value
    assign slave.c_bits.size    = wr_burst_len_q - 1; 
    assign slave.c_bits.source  = SOURCE_ID;
    assign slave.c_bits.address = release_addr_q;
    assign slave.c_bits.data    = send_data_d;
    assign slave.c_bits.corrupt = '0;

    assign read_valid = slave.d_valid && (slave.d_bits.opcode inside {tl_pkg::GrantData, tl_pkg::AccessAckData});
    assign write_valid = slave.d_valid && (slave.d_bits.opcode inside {tl_pkg::ReleaseAck, tl_pkg::AccessAck});
    assign slave.d_ready = read_ready || write_ready;


    assign send_data_d = lock_data_dly ? wdata : send_data_q;

    assign sink_d = slave.d_valid && slave.d_ready ? slave.d_bits.sink : sink_q;
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            read_state_q        <= READ_IDLE;
            write_state_q       <= WRITE_IDLE;
            src_base_addr_q     <= '0;
            des_base_addr_q     <= '0;
            data_volume_q       <= '0;
            rd_burst_len_q      <= '0;
            wr_burst_len_q      <= '0;
            dma_start_q         <= '0;
            trans_mode_q        <= '0;
            reset_q             <= '0;
            status_q            <= '0;
            fifo_status_q       <= {IDLE, IDLE};
            read_use_fifo_q     <= '0;
            write_use_fifo_q    <= '0;
            read_addr_q         <= '0;
            write_addr_q        <= '0;
            left_read_data_q    <= '0;
            left_write_data_q   <= '0;
            read_trans_cnt_q    <= '0;
            write_trans_cnt_q   <= '0;
            release_addr_q      <= '0;
            send_data_q         <= '0;
            lock_data_dly       <= '0;
        end else begin
            read_state_q        <= read_state_d     ;
            write_state_q       <= write_state_d    ;
            src_base_addr_q     <= src_base_addr_d  ;
            des_base_addr_q     <= des_base_addr_d  ;
            data_volume_q       <= data_volume_d    ;
            rd_burst_len_q      <= rd_burst_len_d   ;
            wr_burst_len_q      <= wr_burst_len_d   ;
            dma_start_q         <= dma_start_d      ;
            reset_q             <= reset_d          ;
            status_q            <= status_d         ;
            fifo_status_q       <= fifo_status_d    ;
            read_use_fifo_q     <= read_use_fifo_d  ;
            write_use_fifo_q    <= write_use_fifo_d ;
            read_addr_q         <= read_addr_d      ;
            write_addr_q        <= write_addr_d     ;
            left_read_data_q    <= left_read_data_d ;
            left_write_data_q   <= left_write_data_d;
            read_trans_cnt_q    <= read_trans_cnt_d ;
            write_trans_cnt_q   <= write_trans_cnt_d;
            release_addr_q      <= release_addr_d   ;
            send_data_q         <= send_data_d      ;
            trans_mode_q        <= trans_mode_d     ;
            lock_data_dly       <= lock_data        ;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
(* mark_debug = "true" *) logic       prb_dma_a_valid;
(* mark_debug = "true" *) logic       prb_dma_a_ready;
(* mark_debug = "true" *) logic[31:0] prb_dma_a_addr;

(* mark_debug = "true" *) logic       prb_dma_d_valid;
(* mark_debug = "true" *) logic       prb_dma_d_ready;
(* mark_debug = "true" *) logic[63:0] prb_dma_d_data;

(* mark_debug = "true" *) logic       prb_dma_c_valid;
(* mark_debug = "true" *) logic       prb_dma_c_ready;
(* mark_debug = "true" *) logic[63:0] prb_dma_c_data;

assign prb_dma_a_valid  = slave.a_valid;
assign prb_dma_a_ready  = slave.a_ready;
assign prb_dma_a_addr   = slave.a_bits.address;

assign prb_dma_d_valid  = slave.d_valid;
assign prb_dma_d_ready  = slave.d_ready;
assign prb_dma_d_data   = slave.d_bits.data;

assign prb_dma_c_valid  = slave.c_valid;
assign prb_dma_c_ready  = slave.c_ready;
assign prb_dma_c_data   = slave.c_bits.data;

(* mark_debug = "true" *) read_state_e  prb_dma_rd_state;
(* mark_debug = "true" *) write_state_e prb_dma_wr_state;

assign prb_dma_rd_state = read_state_q;
assign prb_dma_wr_state = write_state_q;

endmodule