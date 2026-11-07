// Auto Generated, don't modify!!!
package sy_soc_pkg;
//----------------------------------------------------------------------------------------------------------------------
// SOC parameters
//----------------------------------------------------------------------------------------------------------------------
parameter integer CORE_NUM = 2;

parameter DBGBase       = 64'h0000_0000;
parameter DBGLength     = 64'h1000;
parameter DRAMBase      = 64'h8000_0000;
parameter DRAMLength    = 64'h8000_0000;
parameter PLICBase      = 64'hC00_0000;
parameter PLICLength    = 64'h400_0000;
parameter CLINTBase     = 64'h200_0000;
parameter CLINTLength   = 64'hC_0000;
parameter UARTBase      = 64'h4181_0000;
parameter UARTLength    = 64'h1000;
parameter DMABase       = 64'h4182_0000;
parameter DMALength     = 64'h1000;
parameter REGMAPBase    = 64'h4184_0000;
parameter REGMAPLength  = 64'h1_0000;
parameter SDBase        = 64'h4185_0000;
parameter SDLength      = 64'h7B_0000;
parameter BOOTROMBase   = 64'h4200_0000;
parameter BOOTROMLength = 64'h3E00_0000;

parameter ReservedBase   = {64{1'b1}};
parameter ReservedLength = 1;

endpackage
