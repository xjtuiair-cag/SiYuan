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
// FILE NAME  : UART_rec.sv
// DEPARTMENT : Cognitive Architecture Group
// AUTHOR     : shenghuan
// AUTHOR'S EMAIL :
// ---------------------------------------------------------------------------------------------------------------------
// Ver 1.0  2024-09-10 initial version.
// ---------------------------------------------------------------------------------------------------------------------

module UART_rec 
#(
    parameter BPS = 115200,
    parameter CLK_fre = 50000000,
    parameter DATA_WIDTH = 8
)(
    input  logic                            clk           ,
    input  logic                            rstn          , 
    input  logic                            uart_rx       ,    

    output logic                            rx_done       ,    
    output logic[DATA_WIDTH - 1:0]          rece_data
);

    localparam BPS_CNT = CLK_fre / BPS;
    
    logic                       start_flag          ;         
    logic                       rx_flag             ;      
    logic                       rx_flag_d0          ;         
    logic                       rx_flag_d1          ;         
    logic [DATA_WIDTH-1 : 0]    data_out            ;       
    logic [DATA_WIDTH-1 : 0]    reg_rece_data       ;            

    logic [3:0]                 rx_cnt              ;     
    logic [15:0]                bps_cnt             ;      

	logic                       done                ;

    //当起始位来临的时刻，rx_flag_d1=1，rx_flag_d0=0，此时start_flag=
    //检测下降沿信号
    assign start_flag = rx_flag_d1 && (~rx_flag_d0);
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rx_flag_d0 <= 1'b0;
            rx_flag_d1 <= 1'b0;
        end else begin
            rx_flag_d0 <= uart_rx;
            rx_flag_d1 <= rx_flag_d0;
        end
    end

    //判断什么时候开始接受传输和停止传输
    //rx_flag=1标志着对输入信号采样即接受传输，为0表示不接受传输。
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin     
            rx_flag <= 1'b0;
        end else begin
            if(start_flag)                  //感受到起始位后开始接受传输
                rx_flag <= start_flag;
            else if(rx_cnt == 4'd9 && bps_cnt == BPS_CNT / 2)//当接受传输超过9位并且处于采样中心时停止接受传输
                rx_flag <= 0;
            else
                rx_flag <= rx_flag;
        end
    end

    //bps_cnt在每个时钟周期内加1，当超过BPS_CNT后表示采样一位数据
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            bps_cnt <= 16'b0;
            rx_cnt <= 4'b0;
        end else if(rx_flag) begin
            if(bps_cnt < BPS_CNT - 1'b1) begin
                bps_cnt <= bps_cnt + 1'b1;
                rx_cnt <= rx_cnt;
            end else begin
                bps_cnt <= 16'b0;
                rx_cnt <= rx_cnt + 1'b1;
            end
        end else begin
            bps_cnt <= 16'b0;
            rx_cnt <= 4'b0;
        end
    end

    //采样数据
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            data_out <= 8'b0;
        end else if(rx_flag) begin
            if(bps_cnt == BPS_CNT / 2) begin
                case(rx_cnt)
                //为什么从rx_cnt=1时开始采样数据而不是0时呢
                //这是因为rx_cnt=0时数据线上的还是起始位，不能采集
                    4'd1    :     data_out[0] <= rx_flag_d1;
                    4'd2    :     data_out[1] <= rx_flag_d1;
                    4'd3    :     data_out[2] <= rx_flag_d1;
                    4'd4    :     data_out[3] <= rx_flag_d1;
                    4'd5    :     data_out[4] <= rx_flag_d1;
                    4'd6    :     data_out[5] <= rx_flag_d1;
                    4'd7    :     data_out[6] <= rx_flag_d1;
                    4'd8    :     data_out[7] <= rx_flag_d1;
                    default :   ;
                endcase
            end
        end else begin
            data_out <= 8'b0;
        end 
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            done <= 1'b0;
            reg_rece_data <= 8'b0;
        end else if(rx_cnt == 4'd9) begin
            reg_rece_data <= data_out;
            done <= 1'b1;
        end else begin
            reg_rece_data <= reg_rece_data;
            done <= 1'b0;
        end
    end

	assign rx_done = done;
    assign rece_data = reg_rece_data;
endmodule //UART_rec