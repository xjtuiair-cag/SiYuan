// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : axi_mem_benos.v
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

`timescale 1ns / 1ps

// Attention: This simulation module has not implemented all features of AXI protocol. It only support aligned access
// with strobe, increasement burst type, and 4KiB access boundary.

module axi_mem_sim # (
    parameter ADDR_WTH = 32,
    parameter DATA_WTH = 256,
    parameter MEM_SIZE = 4*1024*1024,
    parameter ID_WIDTH = 4,
    parameter OFFSET = 64'h80000000
) (
    input    logic                                  clk_i,
    input    logic                                  rst_i,

    input    logic[ADDR_WTH-1 : 0]                  awaddr,
    input    logic[1:0]                             awburst,
    input    logic[3:0]                             awcache,
    input    logic[7:0]                             awlen,
    input    logic[ID_WIDTH-1:0]                    awid,
    input    logic[0:0]                             awlock,
    input    logic[2:0]                             awprot,
    input    logic[3:0]                             awqos,
    output   logic                                  awready,
    input    logic[3:0]                             awregion,
    input    logic[2:0]                             awsize,
    input    logic                                  awvalid,
    input    logic[DATA_WTH-1 : 0]                  wdata,
    input    logic                                  wlast,
    output   logic                                  wready,
    input    logic[DATA_WTH/8-1 : 0]                wstrb,
    input    logic                                  wvalid,
    input    logic                                  bready,
    output   logic[1:0]                             bresp,
    output   logic[ID_WIDTH-1:0]                    bid,    
    output   logic                                  bvalid,

    input    logic[ADDR_WTH-1 : 0]                  araddr,
    input    logic[1:0]                             arburst,
    input    logic[3:0]                             arcache,
    input    logic[7:0]                             arlen,
    input    logic[ID_WIDTH-1:0]                    arid,
    input    logic[0:0]                             arlock,
    input    logic[2:0]                             arprot,
    input    logic[3:0]                             arqos,
    output   logic                                  arready,
    input    logic[3:0]                             arregion,
    input    logic[2:0]                             arsize,
    input    logic                                  arvalid,
    output   logic[DATA_WTH-1 : 0]                  rdata,
    output   logic                                  rlast,
    input    logic                                  rready,
    output   logic[1:0]                             rresp,
    output   logic[ID_WIDTH-1:0]                    rid,
    output   logic                                  rvalid
);

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

    localparam BLK_NUM = 3;
    localparam ADDR_BIT = $clog2(ADDR_WTH);
    localparam DATA_BIT = $clog2(DATA_WTH);
    localparam MEM_BIT = $clog2(MEM_SIZE);
    localparam BENOS_START = 64'h80200000;
    localparam SBI_START = 64'h80000000;

    logic[DATA_WTH-1:0]                     rmt_mem_sbi[MEM_SIZE/DATA_WTH*8-1 : 0]; //8000_0000 -- 8001_0000
    logic[DATA_WTH-1:0]                     rmt_mem_benos[MEM_SIZE/DATA_WTH*8-1 : 0]; // 8020_0000 -- 8021_0000   

    logic[ADDR_WTH-1:0]                     cmd_waddr;
    logic[ID_WIDTH-1:0]                     cmd_wid;
    logic[7:0]                              cmd_wlen;
    logic[11-DATA_BIT+3:0]                  cmd_woffset;
    logic                                   wready_org;
    logic[ADDR_WTH-1:0]                     wcnt;
    logic[ADDR_WTH-1:0]                     cmd_raddr;
    logic[ID_WIDTH-1:0]                     cmd_rid;
    logic[7:0]                              cmd_rlen;

    logic[11-DATA_BIT+3:0]                  cmd_roffset;
    logic[ADDR_WTH-1:0]                     rcnt;
    logic                                   rvalid_org;

    logic[7:0]                              blk_cnt;

    logic[ADDR_WTH-1:0]                     raddr;
    logic[ADDR_WTH-1:0]                     waddr;

    logic                                   wr_sbi_or_benos; // 1 for sbi , 0 for benos
    logic                                   rd_sbi_or_benos;
//======================================================================================================================
// Instance
//======================================================================================================================

    // -----
    // # Initialization
    initial begin
        #10;
        // sbi memory
        $readmemh("mysbi.dat", rmt_mem_sbi);
        $display("SBI Memory contents:");
        for (int i = 0; i < 100; i++)
            $display("memory[%0d] = %h", i, rmt_mem_sbi[i]);

        // benos memory
        $readmemh("benos.dat", rmt_mem_benos);
        $display("benos Memory contents:");
        for (int i = 0; i < 100; i++)
            $display("memory[%0d] = %h", i, rmt_mem_benos[i]);
    end

    // -----
    // # Memory write interface

    // AW ready signal is clear when it receives a write request, and is set when the transfer of current request is
    // finished.
    always @(posedge clk_i) begin
        if(!rst_i) begin
            awready <= 1'b1;
            cmd_waddr <= {ADDR_WTH{1'b0}};
            cmd_wlen <= 8'h0;
            cmd_wid <= 2'h0;
        end else begin
            if(awvalid && awready) begin
                awready <= 1'b0;
                // save current command params if this command is valid
                cmd_waddr <= awaddr;
                cmd_wlen <= awlen;
                cmd_wid <= awid;
            end
            if(wvalid && (wlast || (cmd_wlen == wcnt)) && wready) begin
                awready <= 1'b1;
            end
        end
    end

    // WR ready signal is '0' in common. It is set when a write request is valid, and after all data are transferd it
    // is clear.
    always @(posedge clk_i) begin
        if(!rst_i) begin
            wready_org <= 1'b0;
            wcnt <= {ADDR_WTH{1'b0}};
        end else begin
            if(awvalid && awready) begin
                wready_org <= 1'b1;
                wcnt <= {ADDR_WTH{1'b0}};
            end
            if(wvalid && wready) begin
                wcnt <= wcnt + 1'b1;
                if(wlast) begin
                    if(wcnt != cmd_wlen) $display("[ERROR] AXI WR channel receives uncorrect wlast signal.");
                    wready_org <= 1'b0;
                end
            end
        end
    end
    assign wready = wready_org && (blk_cnt == BLK_NUM);

    always_comb begin
        waddr = cmd_waddr - SBI_START;
        wr_sbi_or_benos = 1'b1;
        if(cmd_waddr >= BENOS_START) begin
            waddr = cmd_waddr - BENOS_START;
            wr_sbi_or_benos = 1'b0;
        end
    end

    // write MEM
    assign cmd_woffset = waddr[11:(DATA_BIT-3)] + wcnt;
    always @(posedge clk_i) begin
        if(wvalid && wready) begin
            for(integer i=0; i<DATA_WTH/8; i=i+1) begin
                if(wstrb[i] && wr_sbi_or_benos) begin
                    rmt_mem_sbi[{waddr[MEM_BIT-1:12],cmd_woffset}][i*8 +: 8] <= wdata[i*8 +: 8];
                end else if(wstrb[i]) begin
                    rmt_mem_benos[{waddr[MEM_BIT-1:12],cmd_woffset}][i*8 +: 8] <= wdata[i*8 +: 8];
                end
            end
        end
    end

    // B channel send the write feedback data.
    always @(posedge clk_i) begin
        if(!rst_i) begin
            bvalid <= 1'b0;
            bresp <= 2'h0;
        end else begin
            if(wvalid && wlast && wready) begin
                bvalid <= 1'b1;
                bresp <= 2'h0;
                bid <= cmd_wid;
            end
            if(bvalid && bready) begin
                bvalid <= 1'b0;
            end
        end
    end

    // -----
    // # Memory read interface
    
    // AR ready signal is clear when it receives a read request, and is set when all the read data is transfered.
    always @(posedge clk_i) begin
        if(!rst_i) begin
            arready <= 1'b1;
            cmd_raddr <= {ADDR_WTH{1'b0}};
            cmd_rlen <= 8'h0;
            cmd_rid <= 2'h0;
        end else begin
            if(arvalid && arready) begin
                arready <= 1'b0;
                cmd_raddr <= araddr;
                cmd_rlen <= arlen;
                cmd_rid <= arid;
            end
            if(rvalid && rlast && rready) begin
                arready <= 1'b1;
            end
        end
    end

    // RD channel send the read data back.
    always @(posedge clk_i) begin
        if(!rst_i) begin
            rvalid_org <= 1'b0;
            rcnt <= {ADDR_WTH{1'b0}};
        end else begin
            if(arvalid && arready) begin
                rvalid_org <= 1'b1;
                rcnt <= {ADDR_WTH{1'b0}};
            end
            if(rvalid && rready) begin
                rcnt <= rcnt + 1'b1;
                if(rlast) begin
                    rvalid_org <= 1'b0;
                end
            end
        end
    end
    assign rvalid = rvalid_org && (blk_cnt == BLK_NUM);

    always @(posedge clk_i) begin
        if(!rst_i) begin
            blk_cnt <= 8'h0;
        end else begin
            if(blk_cnt == BLK_NUM) begin
                blk_cnt <= 8'h0;
            end else begin
                blk_cnt <= blk_cnt + 1'b1;
            end
        end
    end

    always_comb begin
        raddr = cmd_raddr - SBI_START;
        rd_sbi_or_benos = 1'b1;
        if(cmd_raddr >= BENOS_START) begin
            raddr = cmd_raddr - BENOS_START;
            rd_sbi_or_benos = 1'b0;
        end
    end

    assign cmd_roffset = raddr[11:(DATA_BIT-3)] + rcnt;
    assign rlast = (rcnt == cmd_rlen) && rvalid;
    assign rresp = 2'h0;
    assign rid = cmd_rid;

    always_comb begin
        rdata = rmt_mem_sbi[{raddr[MEM_BIT-1:12], cmd_roffset}];
        if(!rd_sbi_or_benos) begin
            rdata = rmt_mem_benos[{raddr[MEM_BIT-1:12], cmd_roffset}];
        end
    end

//======================================================================================================================
// just for simulation
//======================================================================================================================
// synospsys translate_off

// synospsys translate_on

//======================================================================================================================
// probe signals
//======================================================================================================================
    logic[ADDR_WTH-1:0]                             prb_raddr_true;
    logic[ADDR_WTH-1:0]                             prb_waddr_true;
    logic[ADDR_WTH-1:0]                             prb_raddr_off;
    logic[ADDR_WTH-1:0]                             prb_waddr_off;
    logic                                           prb_wr_type;
    logic                                           prb_rd_type;

    assign prb_raddr_true = cmd_raddr;
    assign prb_waddr_true = cmd_waddr;
    assign prb_raddr_off = raddr; 
    assign prb_waddr_off = waddr;
    assign prb_wr_type = wr_sbi_or_benos;
    assign prb_rd_type = rd_sbi_or_benos;
endmodule : axi_mem_sim
