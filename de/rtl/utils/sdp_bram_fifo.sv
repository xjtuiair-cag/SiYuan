// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sdp_bram_fifo.v
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

module sdp_bram_fifo #(
    parameter int unsigned DATA_WIDTH   = 64,   
    parameter int unsigned DEPTH        = 512,    
    parameter int unsigned ADDR_DEPTH   = $clog2(DEPTH) 
)(
    input  logic                                clk_i,           
    input  logic                                rst_i,           
    // status flags
    output logic                                full_o,           
    output logic                                empty_o,          

    input  logic [DATA_WIDTH-1:0]               data_i,           
    output logic [DATA_WIDTH-1:0]               data_o,           
    input  logic                                push_i,           
    input  logic                                pop_i             
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam int unsigned FIFO_DEPTH =  DEPTH;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

    logic [ADDR_DEPTH - 1:0]    read_pointer_d, read_pointer_q; 
    logic [ADDR_DEPTH - 1:0]    write_pointer_d, write_pointer_q;
    logic [ADDR_DEPTH:0]        cnt_d, cnt_q; // this integer will be truncated by the synthesis tool

    logic                       data_ram_ren ;   
    logic                       data_ram_wen;                   
    logic [ADDR_DEPTH-1:0]      data_ram_raddr;      
    logic [ADDR_DEPTH-1:0]      data_ram_waddr;      
    logic [DATA_WIDTH-1:0]      data_ram_rdata;            
    logic [DATA_WIDTH-1:0]      data_ram_wdata;            

//======================================================================================================================
// Data array
//======================================================================================================================
    sdp_512x64sd1_wrap data_ram(
      .wr_clk_i                   (clk_i                ),              
      .we_i                       (data_ram_wen         ),          
      .waddr_i                    (data_ram_waddr       ),             
      .wdata_i                    (data_ram_wdata       ),             
      .wstrb_i                    (8'hff                ),             
      .rd_clk_i                   (clk_i                ),              
      .re_i                       (data_ram_ren         ),          
      .raddr_i                    (data_ram_raddr       ),             
      .rdata_o                    (data_ram_rdata       )    
    );
//======================================================================================================================
// Read Write Logic
//======================================================================================================================
    // full/empty logic
    assign full_o       = (cnt_q == FIFO_DEPTH[ADDR_DEPTH:0]);
    assign empty_o      = (cnt_q == 0);

    assign data_ram_wdata  = data_i;
    assign data_ram_waddr  = write_pointer_q;
    assign data_ram_raddr  = read_pointer_d;
    assign data_o          = data_ram_rdata;

    // read and write queue logic
    always_comb begin : read_write_comb
        // default assignment
        read_pointer_d  = read_pointer_q;
        write_pointer_d = write_pointer_q;
        cnt_d           = cnt_q;

        data_ram_wen    = 1'b0;
        data_ram_ren    = 1'b1; // always read data

        // push a new element to the queue
        if (push_i && ~full_o) begin
            // push the data onto the queue
            data_ram_wen    = 1'b1;
            // increment the write counter
            if (write_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) begin
                write_pointer_d = '0;
            end else begin
                write_pointer_d = write_pointer_q + 1;
            end
            // increment the overall counter
            cnt_d = cnt_q + 1;
        end

        if (pop_i && ~empty_o) begin

            // data_ram_ren = 1'b1;
            // but increment the read pointer...
            if (read_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1) begin
                read_pointer_d = '0;
            end else begin
                read_pointer_d = read_pointer_q + 1;
            end
            // ... and decrement the overall count
            cnt_d   = cnt_q - 1;
        end

        // keep the count pointer stable if we push and pop at the same time
        if (push_i && pop_i &&  ~full_o && ~empty_o)
            cnt_d   = cnt_q;
   end

    // sequential process
    always_ff @(posedge clk_i or negedge rst_i) begin
        if(~rst_i) begin
            read_pointer_q  <= '0;
            write_pointer_q <= '0;
            cnt_q           <= '0;
        end else begin
            read_pointer_q  <= read_pointer_d;
            write_pointer_q <= write_pointer_d;
            cnt_q           <= cnt_d;
        end
    end

endmodule 