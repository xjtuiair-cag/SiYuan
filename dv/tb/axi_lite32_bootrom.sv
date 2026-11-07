`timescale 1ns/1ps
module axi_lite32_bootrom #(
    parameter ADDR_WIDTH  = 32,            // byte-address width (can be larger)
    parameter DATA_WIDTH  = 32,            // data width in bits (32)
    parameter MEM_BYTES   = 1024 * 1024   
)(
    input  logic                     ACLK,
    input  logic                     ARESETn,

    // Write address channel
    input  logic                     AWVALID,
    output logic                     AWREADY,
    input  logic [ADDR_WIDTH-1:0]    AWADDR,

    // Write data channel
    input  logic                     WVALID,
    output logic                     WREADY,
    input  logic [DATA_WIDTH-1:0]    WDATA,
    input  logic [DATA_WIDTH/8-1:0]  WSTRB,

    // Write response channel
    output logic                     BVALID,
    input  logic                     BREADY,
    output logic[1:0]                BRESP, // 2'b00 = OKAY

    // Read address channel
    input  logic                     ARVALID,
    output logic                     ARREADY,
    input  logic [ADDR_WIDTH-1:0]    ARADDR,

    // Read data channel
    output logic                     RVALID,
    input  logic                     RREADY,
    output logic[DATA_WIDTH-1:0]     RDATA,
    output logic[1:0]                RRESP
);
    localparam BYTE_WIDTH  = DATA_WIDTH/8;
    localparam WORD_WIDTH_BYTES = BYTE_WIDTH;
    localparam integer DEPTH = MEM_BYTES / WORD_WIDTH_BYTES; // number of DATA_WIDTH words


    // memory: word-addressable, each word is DATA_WIDTH bits
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [63:0] tmp_mem [0:DEPTH/2-1];

    // Address word index calculation
    function logic[15:0] addr_to_index(input logic [ADDR_WIDTH-1:0] addr);
        // align to DATA_WIDTH (byte offset >> log2(BYTE_WIDTH))
        addr_to_index = addr >> $clog2(WORD_WIDTH_BYTES);
    endfunction

    int fd;
    // sanitize DEPTH > 0
    initial begin
        if (DEPTH <= 0) begin
            $fatal(1, "Invalid DEPTH computed: %0d", DEPTH);
        end
        // read bootrom file
        fd = $fopen("bootrom.dat", "r");
        if (fd) begin
            // 文件存在
            $display("INFO: Found file %s, loading with $readmemh ...", "bootrom.dat");
            $fclose(fd); // 关闭文件
            $readmemh("bootrom.dat", tmp_mem);
            for(integer i=0; i<DEPTH/2; i++) begin
                for(integer j=0; j<2; j++) begin
                    mem[i*2+j] = tmp_mem[i][j*32+:32];
                end
            end
        // for (integer i = 0; i < 50; i++)
        //     $display("memory[%0d] = %h", i, mem[i]);
        end else begin
          // 文件不存在
          $display("WARNING: File %s not found, skip loading.", "bootrom.dat");
        end
    end

    // Internal latches
    logic [ADDR_WIDTH-1:0] lat_awaddr;
    logic aw_valid_latched;
    logic [ADDR_WIDTH-1:0] lat_araddr;
    logic ar_valid_latched;

    // For read-after-write (if write accepted same cycle as read)
    logic [ADDR_WIDTH-1:0] last_write_addr;
    logic [DATA_WIDTH-1:0] last_write_data;
    logic [BYTE_WIDTH-1:0] last_write_strb;
    logic last_write_valid;

    // AXI-Lite write address handshake: accept AW when ready
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1;
            aw_valid_latched <= 0;
            lat_awaddr <= '0;
        end else begin
            // AWREADY: accept when not holding a pending AW
            // if (!aw_valid_latched && !BVALID) begin
            //     AWREADY <= 1'b1;
            // end else begin
            //     AWREADY <= 1'b0;
            // end

            if (AWVALID && AWREADY) begin
                lat_awaddr <= AWADDR;
                aw_valid_latched <= 1'b1;
                AWREADY <= 1'b0;
            end

            // clear latched AW when write response issued
            if (BVALID && BREADY) begin
                aw_valid_latched <= 1'b0;
                AWREADY <= 1'b1;
            end
        end
    end
    logic [15:0] write_idx;
    assign write_idx = addr_to_index(lat_awaddr);
    // AXI-Lite write data handshake
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            WREADY <= 1;
            BVALID <= 0;
            BRESP  <= 2'b00;
            last_write_valid <= 0;
        end else begin
            // WREADY: accept data when AW was latched (we require both AW and W to perform write)
            // if (aw_valid_latched && !BVALID) begin
            //     WREADY <= 1'b1;
            // end else begin
            //     WREADY <= 1'b0;
            // end

            if (WVALID && WREADY) begin
                // perform byte-wise write to memory
                // int idx = addr_to_index(lat_awaddr);
                // if (idx >= 0 && idx < DEPTH) begin
                    // build mask and write
                    // logic [DATA_WIDTH-1:0] old = mem[idx];
                    // logic [DATA_WIDTH-1:0] newv = old;
                    for (integer b = 0; b < BYTE_WIDTH; b++) begin
                        if (WSTRB[b]) begin
                            mem[write_idx][b*8 +: 8] = WDATA[b*8 +: 8];
                        end
                    // mem[idx] <= newv;
                end 
                    // out-of-range write: ignore or you can set BRESP to SLVERR (2'b10)

                // record last write for potential read-after-write
                last_write_addr  <= lat_awaddr;
                last_write_data  <= WDATA;
                last_write_strb  <= WSTRB;
                last_write_valid <= 1'b1;

                // produce write response next cycle
                BVALID <= 1'b1;
                BRESP  <= 2'b00; // OKAY
                WREADY <= 1'b0;
            end

            // clear write response when accepted by master
            if (BVALID && BREADY) begin
                BVALID <= 1'b0;
                last_write_valid <= 1'b0; // optionally clear
                WREADY <= 1'b1;
            end
        end
    end

    logic [15:0] read_idx;
    assign read_idx = addr_to_index(lat_araddr);
    // AXI-Lite read address handshake
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1;
            ar_valid_latched <= 0;
            lat_araddr <= '0;
            RVALID <= 0;
            RRESP  <= 2'b00;
            RDATA  <= '0;
        end else begin
            // accept AR when not currently presenting read data
            // if (!RVALID) ARREADY <= 1'b1;
            // else          ARREADY <= 1'b0;

            if (ARVALID && ARREADY) begin
                lat_araddr <= ARADDR;
                ar_valid_latched <= 1'b1;
                // Fetch data from memory next cycle (to model typical memory latency)
                ARREADY <= 1'b0;
            end

            // Provide read data when AR was latched and RVALID is not already asserted
            if (ar_valid_latched && !RVALID) begin
                // int idx = addr_to_index(lat_araddr);
                // logic [DATA_WIDTH-1:0] read_word = '0;

                // if (idx >= 0 && idx < DEPTH) begin
                //     read_word = mem[idx];
                // end

                // // if a write happened to same address and last_write_valid, reflect write-through
                // if (last_write_valid && (addr_to_index(last_write_addr) == idx)) begin
                //     // construct merged data: apply last_write_strb to last_write_data over mem
                //     logic [DATA_WIDTH-1:0] merged = read_word;
                //     for (int b = 0; b < BYTE_WIDTH; b++) begin
                //         if (last_write_strb[b])
                //             merged[b*8 +: 8] = last_write_data[b*8 +: 8];
                //     end
                //     read_word = merged;
                // end

                // RDATA  <= read_word;
                RDATA  <= mem[read_idx];
                RRESP  <= 2'b00; // OKAY
                RVALID <= 1'b1;
                ar_valid_latched <= 1'b0;
            end

            // clear RVALID on master ready
            if (RVALID && RREADY) begin
                RVALID <= 1'b0;
                ARREADY <= 1'b1;
            end
        end
    end

endmodule