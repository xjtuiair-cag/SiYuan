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

    localparam  START_LOC       = 0;
    localparam  DONE_LOC        = 1;
    localparam  BUSY_LOC        = 2;

    localparam  ONE_TRANSFER    = 8;
    localparam  SOURCE_ID       = {SOURCE, 1'b0};
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    typedef enum logic[2:0] {READ_IDLE, WRITE_SPI, WAIT, READ_REQ, WAIT_READ, GRANT_ACK} read_state_e;
    typedef enum logic[1:0] {WRITE_IDLE, WRITE,SEND_DATA,WAIT_WRITE} write_state_e;
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
    logic [7:0]                             burst_len_d, burst_len_q;
    logic [31:0]                            trans_ctrl_d, trans_ctrl_q;
    logic                                   trans_mode_d, trans_mode_q;

    logic                                   fifo_full;
    logic                                   fifo_afull;
    logic                                   fifo_empty;
    logic                                   fifo_push;
    logic                                   fifo_pop;
    logic [DATA_WIDTH-1:0]                  fifo_data_in;
    logic [DATA_WIDTH-1:0]                  fifo_data_out;

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
    logic[7:0]                              load_data_be_d,load_data_be_q;        
    logic[63:0]                             load_data_d,load_data_q;        
    logic                                   load_status_d,load_status_q;
    logic[9:0]                              block_cnt_d,block_cnt_q;
    logic                                   find_block_d,find_block_q;
    logic                                   read_crc_d,read_crc_q;
    logic                                   read_crc_cnt_d,read_crc_cnt_q;
    logic[3:0]                              wait_cnt_d,wait_cnt_q;
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

    sdp_bram_fifo fifo (
        .clk_i              (clk_i),                 
        .rst_i              (rst_i),                 
        .full_o             (fifo_full),                  
        .afull_o            (fifo_afull),                  
        .empty_o            (fifo_empty),                  
        .data_i             (fifo_data_in),                  
        .data_o             (fifo_data_out),                  
        .push_i             (fifo_push),                  
        .pop_i              (fifo_pop)               
    );

//======================================================================================================================
// Control Register
//======================================================================================================================
    always_comb begin
        src_base_addr_d = src_base_addr_q;
        des_base_addr_d = des_base_addr_q;
        data_volume_d   = data_volume_q;
        burst_len_d     = burst_len_q;
        trans_ctrl_d    = trans_ctrl_q;
        trans_mode_d    = trans_mode_q;
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
                    burst_len_d = dma_we ? dma_wdata : burst_len_q;
                    dma_rdata = burst_len_q;
                end
                TRANS_CTRL: begin
                    trans_ctrl_d = dma_we ? dma_wdata : trans_ctrl_q;
                    dma_rdata = trans_ctrl_q;
                end
                // mode 0 : normal mode // mode 1 : spi mode
                TRANS_MODE: begin
                    trans_mode_d = dma_we ? dma_wdata[0] : trans_mode_q;
                    dma_rdata = trans_mode_q;
                end
                default: ;
            endcase    
        end
        if (set_done) begin
            trans_ctrl_d[DONE_LOC]    = 1'b1;
            trans_ctrl_d[START_LOC]   = 1'b0;
            trans_ctrl_d[BUSY_LOC]    = 1'b0;
        end
        if (set_busy) begin
            trans_ctrl_d[BUSY_LOC]    = 1'b1;
        end
    end

    assign src_cacheable = is_cacheable(src_base_addr_q);
    assign des_cacheable = is_cacheable(des_base_addr_q);
    assign start_dma = trans_ctrl_q[START_LOC];
//======================================================================================================================
// FSM
//======================================================================================================================
    always_comb begin : fsm
        // default assignment
        read_state_d        = read_state_q;
        write_state_d       = write_state_q;
        fifo_push           = 1'b0;
        fifo_pop            = 1'b0;

        read_addr_d         = read_addr_q;
        write_addr_d        = write_addr_q;
        left_read_data_d    = left_read_data_q;
        left_write_data_d   = left_write_data_q;
        read_trans_cnt_d    = read_trans_cnt_q;
        write_trans_cnt_d   = write_trans_cnt_q;
        load_data_be_d      = load_data_be_q;
        load_data_d         = load_data_q;
        load_status_d       = load_status_q;
        // TODO
        block_cnt_d         = block_cnt_q;
        find_block_d        = find_block_q;
        read_crc_d          = read_crc_q;
        read_crc_cnt_d      = read_crc_cnt_q;
        wait_cnt_d          = wait_cnt_q;

        release_addr_d      = release_addr_q;
        slave.a_valid       = 1'b0;
        slave.c_valid       = 1'b0;
        slave.e_valid       = 1'b0;

        read_ready          = 1'b0;
        write_ready         = 1'b0;

        set_done          = 1'b0;
        set_busy          = 1'b0;

        lock_data           = 1'b0;
        // read logic 
        case (read_state_q)
            READ_IDLE: begin
                if (start_dma && write_state_q == WRITE_IDLE) begin
                    set_busy = 1'b1;
                    // read_state_d = READ_REQ;
                    read_state_d = trans_mode_q ? WRITE_SPI : READ_REQ;
                    read_addr_d  = src_base_addr_q;
                    left_read_data_d = data_volume_q;
                    load_data_be_d = 8'h01;  
                    load_status_d = trans_mode_q;
                    block_cnt_d = '0;
                    find_block_d = trans_mode_q;
                    read_crc_d   = 1'b0;    
                end
            end
            WRITE_SPI : begin
                if (left_read_data_q != 0 || read_crc_q) begin
                    slave.a_valid = !fifo_afull;
                    if (slave.a_valid && slave.a_ready) begin
                        read_state_d = WAIT;
                        wait_cnt_d = '0;
                    end
                end else begin
                    read_state_d = READ_IDLE;
                end
            end
            WAIT : begin
                if (wait_cnt_q == 4'h8) begin
                    read_state_d = READ_REQ;       
                end else begin
                    wait_cnt_d = wait_cnt_q + 1;
                end
            end
            READ_REQ: begin
                if (left_read_data_q != 0 || read_crc_q) begin
                    slave.a_valid = !fifo_afull;
                    if (slave.a_valid && slave.a_ready) begin
                        read_trans_cnt_d = trans_ctrl_q ? 1'b1 : burst_len_q;
                        read_state_d = WAIT_READ;
                    end
                end else begin
                    read_state_d = READ_IDLE;    
                end
            end
            WAIT_READ: begin
                read_ready = !fifo_full;    
                if (read_valid && read_ready) begin
                    if (!trans_mode_q) begin    // normal mode
                        fifo_push = 1'b1;
                        left_read_data_d = left_read_data_q - ONE_TRANSFER;
                        read_addr_d = read_addr_q + ONE_TRANSFER;
                        if (read_trans_cnt_q == 1) begin
                           read_state_d = src_cacheable ? GRANT_ACK : READ_REQ;
                        end else begin
                           read_trans_cnt_d = read_trans_cnt_q - 1; 
                        end
                    end else if (load_status_q) begin
                        if (slave.d_bits.data[0] == 0) begin
                            load_status_d = 1'b0;
                            read_state_d  = READ_REQ;
                        end else begin
                            load_status_d = 1'b1;
                            read_state_d  = READ_REQ;
                        end
                    end else begin              // spi mode
                        if (find_block_q) begin
                            if (slave.d_bits.data[7:0] == 8'hfe) begin
                                find_block_d = 1'b0;
                            end
                            read_state_d  = WRITE_SPI;
                            load_status_d = 1'b1;
                        end else if (read_crc_q) begin
                            read_state_d = WRITE_SPI;
                            if (read_crc_cnt_q == 1'b1) begin
                               read_crc_d = 1'b0; 
                               find_block_d = 1'b1;
                            end begin
                               read_crc_cnt_d = read_crc_cnt_q + 1;
                            end
                        end else begin
                            read_state_d  = WRITE_SPI;
                            fifo_push = load_data_be_q[7];
                            load_data_be_d = {load_data_be_q[6:0], load_data_be_q[7]};
                            load_data_d    = {slave.d_bits.data[39:32],load_data_q[63:8]};
                            left_read_data_d = left_read_data_q - 1;
                            // read_addr_d      = load_data_be_q[7] ? (read_addr_q + ONE_TRANSFER)      : read_addr_q;
                            // read_addr_d      = read_addr_q + ONE_TRANSFER;
                            load_status_d = 1'b1;
                            if (block_cnt_q == 10'h1ff) begin
                                read_crc_d = 1'b1;
                                read_crc_cnt_d = 0;
                                block_cnt_d = 0;
                            end else begin
                                block_cnt_d = block_cnt_q + 1;
                            end
                        end
                    end
                end
            end
            GRANT_ACK: begin
                slave.e_valid = 1'b1;
                if (slave.e_ready) begin
                    read_state_d = READ_REQ;
                end
            end
           default : read_state_d = READ_IDLE;
        endcase
        // write logic 
        case (write_state_q)
            WRITE_IDLE: begin
                if (start_dma) begin
                    write_state_d       = WRITE;
                    write_addr_d        = des_base_addr_q;
                    left_write_data_d   = data_volume_q;
                    write_trans_cnt_d   = burst_len_q;
                    release_addr_d      = des_base_addr_q;
                end 
            end
            WRITE: begin
                if (left_write_data_q == 0) begin
                    write_state_d     = WRITE_IDLE;
                    set_done          = 1'b1;
                end else if (write_trans_cnt_q == 0) begin
                    write_state_d = WAIT_WRITE; 
                end else begin
                    if (!fifo_empty) begin
                        fifo_pop = 1'b1;
                        write_state_d = SEND_DATA; 
                        lock_data = 1'b1;
                    end
                    // slave.c_valid = !fifo_empty;        
                    // if (slave.c_valid && slave.c_ready) begin
                    //     fifo_pop = 1'b1;    
                    //     left_write_data_d = left_write_data_q - ONE_TRANSFER;
                    //     write_addr_d = write_addr_q + ONE_TRANSFER;
                    //     write_trans_cnt_d = write_trans_cnt_q - 1;
                    // end
                end
            end
            SEND_DATA : begin
                slave.c_valid = 1'b1;        
                if (slave.c_valid && slave.c_ready) begin
                    // fifo_pop = 1'b1;    
                    left_write_data_d = left_write_data_q - ONE_TRANSFER;
                    write_addr_d = write_addr_q + ONE_TRANSFER;
                    write_trans_cnt_d = write_trans_cnt_q - 1;
                    write_state_d = WRITE;
                end
            end
            WAIT_WRITE : begin
                write_ready = 1'b1;    
                if (write_valid && write_ready) begin
                    write_state_d = WRITE;
                    write_trans_cnt_d = burst_len_q;
                    release_addr_d = write_addr_q;
                end
            end
        endcase
    end
//======================================================================================================================
// TileLink interface
//======================================================================================================================
    always_comb begin
       if (read_state_q == WRITE_SPI) begin
            slave.a_bits.opcode = tl_pkg::PutFullData;
            slave.a_bits.address = 32'h20000068;
       end else begin
            slave.a_bits.opcode  = src_cacheable ? tl_pkg::AcquireBlock : tl_pkg::Get;
            slave.a_bits.address = load_status_q ? 32'h20000064 : read_addr_q;
       end
    end
    assign slave.a_bits.param   = tl_pkg::NtoB; //default value
    assign slave.a_bits.size    = trans_ctrl_q ? '0 : (burst_len_q - 1); 
    assign slave.a_bits.source  = SOURCE_ID;
    assign slave.a_bits.mask    = trans_mode_q ? 8'hf : 8'hff;
    assign slave.a_bits.data    = (read_state_q == WRITE_SPI) ? 8'hff : '0;
    assign slave.a_bits.corrupt = '0;

    assign slave.e_bits.sink    = sink_q;

    assign slave.c_bits.opcode  = des_cacheable ? tl_pkg::ReleaseData : tl_pkg::PutFullData;
    assign slave.c_bits.param   = tl_pkg::TtoB; //default value
    assign slave.c_bits.size    = burst_len_q - 1; 
    assign slave.c_bits.source  = SOURCE_ID;
    assign slave.c_bits.address = release_addr_q;
    assign slave.c_bits.data    = send_data_d;
    assign slave.c_bits.corrupt = '0;

    assign read_valid = slave.d_valid && (slave.d_bits.opcode inside {tl_pkg::GrantData, tl_pkg::AccessAckData});
    assign write_valid = slave.d_valid && (slave.d_bits.opcode inside {tl_pkg::ReleaseAck, tl_pkg::AccessAck});
    assign slave.d_ready = read_ready || write_ready;

    assign fifo_data_in = trans_mode_q ? load_data_d : slave.d_bits.data;
    assign send_data_d = lock_data_dly ? fifo_data_out : send_data_q;

    assign sink_d = slave.d_valid && slave.d_ready ? slave.d_bits.sink : sink_q;
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
        if(!rst_i) begin
            read_state_q        <= READ_IDLE;
            write_state_q       <= WRITE_IDLE;
            src_base_addr_q     <= '0;
            des_base_addr_q     <= '0;
            data_volume_q       <= '0;
            burst_len_q         <= '0;
            trans_ctrl_q        <= '0;
            read_addr_q         <= '0;
            write_addr_q        <= '0;
            left_read_data_q    <= '0;
            left_write_data_q   <= '0;
            read_trans_cnt_q    <= '0;
            write_trans_cnt_q   <= '0;
            release_addr_q      <= '0;
            send_data_q         <= '0;
            trans_mode_q        <= '0;
            lock_data_dly       <= '0;
            load_data_be_q      <= '0;
            load_data_q         <= '0;
            load_status_q       <= '0;
            block_cnt_q         <= '0;
            find_block_q        <= '0;
            wait_cnt_q          <= '0;
            read_crc_q          <= '0;  
            read_crc_cnt_q      <= '0;
        end else begin
            read_state_q        <= read_state_d     ;
            write_state_q       <= write_state_d    ;
            src_base_addr_q     <= src_base_addr_d  ;
            des_base_addr_q     <= des_base_addr_d  ;
            data_volume_q       <= data_volume_d    ;
            burst_len_q         <= burst_len_d      ;
            trans_ctrl_q        <= trans_ctrl_d    ;
            read_addr_q         <= read_addr_d      ;
            write_addr_q        <= write_addr_d     ;
            left_read_data_q    <= left_read_data_d ;
            left_write_data_q   <= left_write_data_d;
            read_trans_cnt_q    <= read_trans_cnt_d ;
            write_trans_cnt_q   <= write_trans_cnt_d;
            release_addr_q      <= release_addr_d   ;
            send_data_q         <= send_data_d      ;
            trans_mode_q        <= trans_mode_d;
            lock_data_dly       <= lock_data;
            load_data_be_q      <= load_data_be_d;
            load_data_q         <= load_data_d;
            load_status_q       <= load_status_d;
            block_cnt_q         <= block_cnt_d;
            find_block_q        <= find_block_d;
            wait_cnt_q          <= wait_cnt_d;
            read_crc_q          <= read_crc_d;
            read_crc_cnt_q      <= read_crc_cnt_d;
        end
    end


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
(* mark_debug = "true" *)  logic                    prb_dma_en;
(* mark_debug = "true" *)  logic                    prb_dma_we;
// (* mark_debug = "true" *)  logic [DATA_WIDTH-1:0]   prb_dma_rdata;
(* mark_debug = "true" *)  logic [31:0]             prb_dma_addr;
(* mark_debug = "true" *)  logic [DATA_WIDTH-1:0]   prb_dma_wdata;

assign prb_dma_en       = dma_en;
assign prb_dma_we       = dma_we;
// assign prb_dma_rdata    = dma_rdata;
assign prb_dma_addr     = dma_addr[31:0];
assign prb_dma_wdata    = dma_wdata;
(* mark_debug = "true" *)  read_state_e             prb_dma_read_state;
(* mark_debug = "true" *)  logic[31:0]              prb_dma_data_volume;
(* mark_debug = "true" *)  logic[7:0]               prb_dma_burst_len;
(* mark_debug = "true" *)  logic[31:0]              prb_dma_left_read_data;
(* mark_debug = "true" *)  logic[7:0]               prb_dma_load_data_be;  
(* mark_debug = "true" *)  logic                    prb_dma_load_status;
(* mark_debug = "true" *)  logic[10:0]              prb_dma_block_cnt;
(* mark_debug = "true" *)  logic                    prb_dma_find_block;

assign prb_dma_data_volume = data_volume_q;
assign prb_dma_read_state  = read_state_q;
assign prb_dma_burst_len   = burst_len_q;
assign prb_dma_left_read_data = left_read_data_q;
assign prb_dma_load_data_be   = load_data_be_q;  
assign prb_dma_load_status    = load_status_q;
assign prb_dma_block_cnt      = block_cnt_q;
assign prb_dma_find_block     = find_block_q;

(* mark_debug = "true" *)  logic                    prb_dma_a_valid;
(* mark_debug = "true" *)  logic                    prb_dma_a_ready;
(* mark_debug = "true" *)  logic[31:0]              prb_dma_a_addr;
(* mark_debug = "true" *)  logic[7:0]               prb_dma_a_size;
assign prb_dma_a_valid = slave.a_valid;
assign prb_dma_a_ready = slave.a_ready;
assign prb_dma_a_addr  = slave.a_bits.address;
assign prb_dma_a_size  = slave.a_bits.size;
(* mark_debug = "true" *)  logic                    prb_dma_d_valid;
(* mark_debug = "true" *)  logic                    prb_dma_d_ready;
(* mark_debug = "true" *)  logic[63:0]              prb_dma_d_data;
assign prb_dma_d_valid = slave.d_valid;
assign prb_dma_d_ready = slave.d_ready;
assign prb_dma_d_data  = slave.d_bits.data;

(* mark_debug = "true" *) logic                     prb_dma_fifo_full;
(* mark_debug = "true" *) logic                     prb_dma_fifo_afull;
(* mark_debug = "true" *) logic                     prb_dma_fifo_empty;
(* mark_debug = "true" *) logic                     prb_dma_fifo_push;
(* mark_debug = "true" *) logic                     prb_dma_fifo_pop;
(* mark_debug = "true" *) logic [DATA_WIDTH-1:0]    prb_dma_fifo_data_in;
(* mark_debug = "true" *) logic [DATA_WIDTH-1:0]    prb_dma_fifo_data_out;

assign prb_dma_fifo_full    = fifo_full;
assign prb_dma_fifo_afull   = fifo_afull;
assign prb_dma_fifo_empty   = fifo_empty;
assign prb_dma_fifo_push    = fifo_push;
assign prb_dma_fifo_pop     = fifo_pop;
assign prb_dma_fifo_data_in = fifo_data_in;
assign prb_dma_fifo_data_out = fifo_data_out;

(* mark_debug = "true" *) write_state_e   prb_dma_write_state;
(* mark_debug = "true" *) logic[31:0]     prb_dma_left_write_data;
(* mark_debug = "true" *) logic[31:0]     prb_dma_write_addr;
(* mark_debug = "true" *) logic[7:0]      prb_dma_left_write_trans_cnt;


assign prb_dma_write_state = write_state_q;
assign prb_dma_left_write_data = left_write_data_q;
assign prb_dma_left_write_trans_cnt = write_trans_cnt_q;
assign prb_dma_write_addr = write_addr_q;

(* mark_debug = "true" *) logic      prb_dma_done;
assign prb_dma_done = trans_ctrl_q[1];
endmodule