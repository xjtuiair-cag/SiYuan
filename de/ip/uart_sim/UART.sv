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
// FILE NAME  : swf_with_uart.sv
// DEPARTMENT : Cognitive Architecture Group
// AUTHOR     : shenghuan
// AUTHOR'S EMAIL :
// ---------------------------------------------------------------------------------------------------------------------
// Ver 1.0  2024-09-10 initial version.
// ---------------------------------------------------------------------------------------------------------------------


module UART (
    input  wire clk,
    input  wire rstn,
    input  wire uart_rx,
    output wire uart_tx,
    input  wire en,
    output wire trans_done,
    output [7:0] rx_data,
    input  [7:0] tx_data  
);


    UART_rec receiver(
        .clk(clk),
        .rstn(rstn),
        .uart_rx(uart_rx),
        .rx_done(),
        .rece_data(rx_data)
    );

    UART_send send(
        .clk(clk),
        .rstn(rstn),
        .tx_en(en),
        .trans_data(tx_data),
        .trans_done(trans_done),
        .uart_tx(uart_tx)
    );

endmodule //UART