// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_ctrl.v
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

module sy_fft_ctrl
    import fft_pkg::*;
#(
    parameter BASE_ADDR = 64'h4_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                                clk_i,           
    input  logic                                rst_i,           
    // TL bus, used to read/write regs
    TL_BUS.Master                               master, 
    // flush entire fft module
    output logic                                flush_o,
    // buf and bank pointer
    input  logic                                buf_ptr_i,
    input  logic                                wt_buf_ptr_i,
    input  logic                                bank_ptr_i,
    input  logic [IQ_WTH+1:0]                   iq_status_i,
    input  logic                                lsu_status_i,
    input  logic                                exe_status_i,
    // insert instruction to IBUF
    output logic                                ctrl_iq__vld_o,
    input  logic                                iq_ctrl__rdy_i,
    output iq_data_t                            ctrl_iq__data_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam  CTRL    = BASE_ADDR + 64'h0;
    localparam  DATA0   = BASE_ADDR + 64'h4;
    localparam  DATA1   = BASE_ADDR + 64'h8;
    localparam  DATA2   = BASE_ADDR + 64'hC;
    localparam  DATA3   = BASE_ADDR + 64'h10;
    localparam  STATUS  = BASE_ADDR + 64'h14;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   fft_en;
    logic                                   fft_we;
    logic [DATA_WIDTH-1:0]                  fft_rdata;
    logic [ADDR_WIDTH-1:0]                  fft_addr;
    logic [DATA_WIDTH-1:0]                  fft_wdata;

    logic                                   instr_insert_en_d,instr_insert_en_q;
    logic                                   flush_d,flush_q;
    logic [DATA_WIDTH-1:0]                  data0_d,data0_q;           
    logic [DATA_WIDTH-1:0]                  data1_d,data1_q;           
    logic [DATA_WIDTH-1:0]                  data2_d,data2_q;           
    logic [DATA_WIDTH-1:0]                  data3_d,data3_q;           

    logic [7:0]                             instr_idx_cnt;
//======================================================================================================================
// trans TileLink to Reg read/write
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

        .addr_o             ( fft_addr      ),
        .en_o               ( fft_en        ),
        .we_o               ( fft_we        ),
        .wdata_o            ( fft_wdata     ),
        .rdata_i            ( fft_rdata     )
    );
//======================================================================================================================
// RegMap
//======================================================================================================================
    always_comb begin
        instr_insert_en_d = 1'b0;
        flush_d = 1'b0;   
        data0_d = data0_q;
        data1_d = data1_q;
        data2_d = data2_q;
        data3_d = data3_q;
        fft_rdata = '0;
        if (fft_en) begin
            case(fft_addr)
                CTRL : begin
                    instr_insert_en_d = fft_wdata[0] && fft_we;
                    flush_d = fft_wdata[1] && fft_we;
                    fft_rdata = '0;
                end
                DATA0:begin
                    data0_d = fft_wdata;
                    fft_rdata = data0_q;
                end
                DATA1:begin
                    data1_d = fft_wdata;
                    fft_rdata = data1_q;
                end
                DATA2:begin
                    data2_d = fft_wdata;
                    fft_rdata = data2_q;
                end
                DATA3:begin
                    data3_d = fft_wdata;
                    fft_rdata = data3_q;
                end
                STATUS: begin
                    fft_rdata = {exe_status_i,lsu_status_i,iq_status_i};
                end
                default:;
            endcase
        end
    end

    always_ff @(`DFF_CR(clk_i,rst_i)) begin 
        if(`DFF_IS_R(rst_i)) begin
            instr_insert_en_q <= 1'b0;
            flush_q <= 1'b0;
            data0_q <= '0;
            data1_q <= '0;
            data2_q <= '0;
            data3_q <= '0;
            instr_idx_cnt <= '0;
        end else begin
            instr_insert_en_q <= instr_insert_en_d;
            flush_q <= flush_d;
            data0_q <= data0_d;
            data1_q <= data1_d;
            data2_q <= data2_d;
            data3_q <= data3_d;
            if (flush_o) begin
                instr_idx_cnt <= '0;
            end else if (ctrl_iq__vld_o && iq_ctrl__rdy_i) begin
                instr_idx_cnt <= instr_idx_cnt + 1'b1;
            end
        end
    end
    // send fft instruction to issue queue
    assign ctrl_iq__vld_o = instr_insert_en_q;
    assign ctrl_iq__data_o.addr = {data1_q[15:0],data0_q};
    assign ctrl_iq__data_o.reverse_base = data1_q[31:16];
    assign ctrl_iq__data_o.stride = data2_q;
    assign ctrl_iq__data_o.op = fft_op_e'(data3_q[1:0]);   // fft op
    assign ctrl_iq__data_o.mode = data3_q[2];               // op mode
    assign ctrl_iq__data_o.load_wt = data3_q[3];            // load weight
    assign ctrl_iq__data_o.is_lds = data3_q[4];             // need switch buf pointer
    assign ctrl_iq__data_o.tot_level = data3_q[8:5];             // need switch buf pointer
    assign ctrl_iq__data_o.cur_level = data3_q[12:9];
    assign ctrl_iq__data_o.rd_ocm_addr = data3_q[21:13];
    assign ctrl_iq__data_o.wr_ocm_addr = data3_q[29:21];
    // save buf pointer and bank pointer
    // assign ctrl_iq__data_o.buf_idx = buf_ptr_i;
    // assign ctrl_iq__data_o.wt_buf_ptr = wt_buf_ptr_i;
    // assign ctrl_iq__data_o.bank_idx = bank_ptr_i;
    // assign ctrl_iq__data_o.instr_idx = instr_idx_cnt;

    assign ctrl_iq__data_o.bank_idx = bank_ptr_i; 
    assign ctrl_iq__data_o.instr_idx = instr_idx_cnt;

    assign ctrl_iq__data_o.rs1_idx = buf_ptr_i;
    assign ctrl_iq__data_o.rs2_idx = wt_buf_ptr_i;
    assign ctrl_iq__data_o.rdst_idx = ctrl_iq__data_o.load_wt ? wt_buf_ptr_i : buf_ptr_i;
    assign ctrl_iq__data_o.rs1_vld = ctrl_iq__data_o.op == EXE || ctrl_iq__data_o.op == STORE;
    assign ctrl_iq__data_o.rs2_vld = ctrl_iq__data_o.op == EXE;
    assign ctrl_iq__data_o.rdst_vld = ctrl_iq__data_o.op == EXE || ctrl_iq__data_o.op == LOAD;

    // flush entire fft 
    assign flush_o = flush_q;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

endmodule 