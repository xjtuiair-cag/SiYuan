// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL_BUS.v
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

import tl_pkg::*;
interface TL_BUS;

    A_chan_bits_t   a_bits  ;
    logic           a_valid ;
    logic           a_ready ;

    B_chan_bits_t   b_bits  ;
    logic           b_valid ;
    logic           b_ready ;

    C_chan_bits_t   c_bits  ;
    logic           c_valid ;
    logic           c_ready ;

    D_chan_bits_t   d_bits  ;
    logic           d_valid ;
    logic           d_ready ;

    E_chan_bits_t   e_bits  ;
    logic           e_valid ;
    logic           e_ready ;

  modport Master (
    input a_valid, a_bits, c_valid, c_bits, e_valid, e_bits,
    input b_ready, d_ready,
    output  a_ready, c_ready, e_ready,
    output  b_valid, b_bits, d_valid, d_bits
  );

  modport Slave (
    output  a_valid, a_bits, c_valid, c_bits, e_valid, e_bits,
    output  b_ready, d_ready,
    input  a_ready, c_ready, e_ready,
    input  b_valid, b_bits, d_valid, d_bits
  );

endinterface
