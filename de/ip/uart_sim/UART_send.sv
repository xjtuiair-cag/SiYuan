// ---------------------------------------------------------------------------------------------------------------------
// Copyright (c) 1986-2022, CAG(Cognitive Architecture Group), Institute of AI and Robotics, Xi'an Jiaotong University.
// Proprietary and Confidential All Rights Reserved.
// ---------------------------------------------------------------------------------------------------------------------
// NOTICE: All information contained herein is, and remains the property of CAG, Institute of AI and Robotics,  Xi'an
// Jiaotong University. The intellectual and technical concepts contained herein are proprietary to CAG team, and may be
// covered by P.R.C. and Foreign Patents, patents in process, and are protected by trade secret or copyright law.
//
// This work may not be copied, modified, re-published, uploaded, executed, or distributed in any way, in any time, in
// any medium, whether in whole or in part, without prior written permission from CAG, Institute of AI and Robotics,
// Xi'an Jiaotong University.
//
// The copyright notice above does not evidence any actual or intended publication or disclosure of this source code,
// which includes information that is confidential and/or proprietary, and is a trade secret of CAG.
// ---------------------------------------------------------------------------------------------------------------------
// FILE NAME  : UART_send.sv
// DEPARTMENT : Cognitive Architecture Group
// AUTHOR     : shenghuan
// AUTHOR'S EMAIL :
// ---------------------------------------------------------------------------------------------------------------------
// Ver 1.0  2024-09-10 initial version.
// ---------------------------------------------------------------------------------------------------------------------

module UART_send 
#(
    parameter BPS = 115200,
    parameter CLK_fre = 50000000,
    parameter DATA_WIDTH = 8
)(
    input  logic                        clk             ,
    input  logic                        rstn            ,
    input  logic                        tx_en           ,
    input  logic[DATA_WIDTH - 1:0]      trans_data      ,

    output logic                        trans_done      ,
    output logic                        uart_tx
);

    localparam BPS_CNT = CLK_fre / BPS;

    logic                               start_flag                          ; 
    logic                               tx_flag                             ; 
    logic                               tx_flag_d0                          ; 
    logic                               tx_flag_d1                          ; 
    logic [DATA_WIDTH-1:0]              data_in                             ;                 
    logic                               reg_uart_tx                         ;  
    logic                               reg_trans_done                      ;     

    logic [3:0]                         tx_cnt                              ;   
    logic [15:0]                        bps_cnt                             ;     

    //当起始位来临的时刻，tx_flag_d1=1，tx_flag_d0=0，此时start_flag=1，但只持续一个时钟周期的时间
    //检测tx_en的上升沿
    assign start_flag = tx_flag_d0 && (~tx_flag_d1);
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            tx_flag_d0 <= 1'b0;
            tx_flag_d1 <= 1'b0;
        end else begin
            tx_flag_d0 <= tx_en;
            tx_flag_d1 <= tx_flag_d0;
        end
    end

    //判断什么时候开始输出和停止输出
    //tx_flag=1标志着开始输出数据，为0表示不输出
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin     
            tx_flag <= 1'b0;
            data_in <= 8'b0;
        end else begin
            if(start_flag) begin//感受到起始位后置输出标志为1，并且把要发送的数据加载到内部寄存器中
                tx_flag <= start_flag;
                data_in <= trans_data;
                reg_trans_done <= 0;
            end else if(tx_cnt == 4'd9 && bps_cnt == BPS_CNT / 2) begin//当传输超过9位并且处于采样中心时停止传输
                tx_flag <= 0;
                data_in <= 8'b0;
                reg_trans_done <= 1;
            end else begin
                tx_flag <= tx_flag;
                data_in <= data_in;
                reg_trans_done <= 0;
            end
                
        end
    end

    assign trans_done = reg_trans_done;
    //bps_cnt在每个时钟周期内加1，当超过BPS_CNT后表示输出一位数据
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            bps_cnt <= 16'b0;
            tx_cnt <= 4'b0;
        end else if(tx_flag) begin
            if(bps_cnt < BPS_CNT - 1'b1) begin
                bps_cnt <= bps_cnt + 1'b1;
                tx_cnt <= tx_cnt;
            end else begin
                bps_cnt <= 16'b0;
                tx_cnt <= tx_cnt + 1'b1;
            end
        end else begin
            bps_cnt <= 16'b0;
            tx_cnt <= 4'b0;
        end
    end

    //输出数据
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            reg_uart_tx <= 1'b1;  //复位后输出高电平
        end else if(tx_flag) begin
                case(tx_cnt)
                    4'd0    :     reg_uart_tx <= 1'b0;          //输出起始位
                    4'd1    :     reg_uart_tx <= data_in[0];    //输出8位数据
                    4'd2    :     reg_uart_tx <= data_in[1];
                    4'd3    :     reg_uart_tx <= data_in[2];
                    4'd4    :     reg_uart_tx <= data_in[3];
                    4'd5    :     reg_uart_tx <= data_in[4];
                    4'd6    :     reg_uart_tx <= data_in[5];
                    4'd7    :     reg_uart_tx <= data_in[6];
                    4'd8    :     reg_uart_tx <= data_in[7];
                    4'd9    :     reg_uart_tx <= 1'b0;         //输出停止位
                    default :   ;
                endcase
        end else begin
            reg_uart_tx <= 1'b1;
        end 
    end

    assign uart_tx = reg_uart_tx;
endmodule