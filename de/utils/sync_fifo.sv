// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sync_fifo.sv
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

module sync_fifo # (
    parameter FIFO_LEN = 16,
    parameter DATA_WTH = 8,
    parameter ADDR_WTH = 4,
    parameter FIFO_RD_TYPE = "FWFT",                   // "STANDARD", "FWFT(First word fall through)"
    parameter FULL_ASSERT_VALUE = FIFO_LEN,
    parameter FULL_NEGATE_VALUE = FIFO_LEN,
    parameter EMPTY_ASSERT_VALUE = 0,
    parameter EMPTY_NEGATE_VALUE = 0
) (
    // clock & reset
    input   logic                                   clk_i,
    input   logic                                   rst_i,
    // clear
    input   logic                                   clr_i,
    // write interface
    input   logic[DATA_WTH-1 : 0]                   wr_data_i,
    input   logic                                   wr_en_i,
    output  logic                                   full_o,
    output  logic                                   a_full_o,
    // read interface
    output  logic[DATA_WTH-1 : 0]                   rd_data_o,
    input   logic                                   rd_en_i,
    output  logic                                   empty_o,
    output  logic                                   a_empty_o
);

// =====================================================================================================================
// Local parameters

// =====================================================================================================================
// Local variables

logic[DATA_WTH-1 : 0]                   mem[0 : FIFO_LEN-1];
logic                                   wr_en;
logic[ADDR_WTH : 0]                     wr_addr;
logic                                   wr_mark;
logic                                   rd_en;
logic[ADDR_WTH : 0]                     rd_addr;
logic                                   rd_mark;
logic                                   empty, full;
logic                                   a_empty, a_full;

// =====================================================================================================================
// Instances

// write logic
assign wr_en = wr_en_i & (~full);

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        wr_addr <= {(ADDR_WTH+1){1'b0}};
        wr_mark <= 1'b0;
    end else begin
        if(clr_i) begin
            wr_addr <= {(ADDR_WTH+1){1'b0}};
            wr_mark <= 1'b0;
        end else if(wr_en) begin
            if(wr_addr == FIFO_LEN - 1'b1) begin
                wr_addr <= {(ADDR_WTH+1){1'b0}};
                wr_mark <= ~wr_mark;
            end else begin
                wr_addr <= wr_addr + 1'b1;
            end
            mem[wr_addr[ADDR_WTH-1:0]] <= wr_data_i;
        end
    end
end

// read logic
assign rd_en = rd_en_i & (~empty);
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        rd_addr <= {(ADDR_WTH+1){1'b0}};
        rd_mark <= 1'b0;
    end else begin
        if(clr_i) begin
            rd_addr <= {(ADDR_WTH+1){1'b0}};
            rd_mark <= 1'b0;
        end else if(rd_en) begin
            if(rd_addr == FIFO_LEN - 1'b1) begin
                rd_addr <= {(ADDR_WTH+1){1'b0}};
                rd_mark <= ~rd_mark;
            end else begin
                rd_addr <= rd_addr + 1'b1;
            end
        end
    end
end

if(FIFO_RD_TYPE == "STANDARD") begin
    always_ff @(posedge clk_i) begin
        rd_data_o <= `TCQ mem[rd_addr[ADDR_WTH-1:0]];
    end
end else begin
    assign rd_data_o = mem[rd_addr[ADDR_WTH-1:0]] & ~{DATA_WTH{empty}};
end

// full/empty signal logic
assign empty = (wr_addr == rd_addr) && (wr_mark == rd_mark);
assign full = (wr_addr == rd_addr) && (wr_mark != rd_mark);

assign empty_o = empty;
assign full_o = full;

// almost full/empty signal logic
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        a_empty <= 1'b1;
        a_full <= 1'b0;
    end else begin
        if(clr_i) begin
            a_empty <= 1'b1;
            a_full <= 1'b0;
        end else if(rd_en & (~wr_en)) begin
            if(wr_addr <= rd_addr) begin
                if(wr_addr + FIFO_LEN - rd_addr == EMPTY_ASSERT_VALUE + 1'b1)
                    a_empty <= 1'b1;
                if(wr_addr + FIFO_LEN - rd_addr == FULL_NEGATE_VALUE)
                    a_full <= 1'b0;
            end else begin
                if(wr_addr - rd_addr == EMPTY_ASSERT_VALUE + 1'b1)
                    a_empty <= 1'b1;
                if(wr_addr - rd_addr == FULL_NEGATE_VALUE)
                    a_full <= 1'b0;
            end
        end else if((~rd_en) & wr_en) begin
            if(wr_addr < rd_addr) begin
                if(wr_addr + FIFO_LEN - rd_addr == EMPTY_NEGATE_VALUE)
                    a_empty <= 1'b0;
                if(wr_addr + FIFO_LEN - rd_addr == FULL_ASSERT_VALUE - 1'b1)
                    a_full <= 1'b1;
            end else begin
                if(wr_addr - rd_addr == EMPTY_NEGATE_VALUE)
                    a_empty <= 1'b0;
                if(wr_addr - rd_addr == FULL_ASSERT_VALUE - 1'b1)
                    a_full <= 1'b1;
            end
        end
    end
end

assign a_empty_o = a_empty;
assign a_full_o = a_full;

// =====================================================================================================================
// Assertions

// =====================================================================================================================
// Probes

// synopsys translate_off

// synopsys translate_on

endmodule : sync_fifo
