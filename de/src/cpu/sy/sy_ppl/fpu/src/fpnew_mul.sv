// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : fpnew_mul.v
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

// this file come from fpnew_fma.sv, we remove some logic to only support mul
module fpnew_mul
  import sy_pkg::*;
#(
  parameter fpnew_pkg::fp_format_e   FpFormat    = fpnew_pkg::fp_format_e'(0),
  localparam int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat) // do not change
) (
  input logic                      clk_i,

  // Input signals
  input  logic                     in_valid_i,
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input logic [1:0]                is_boxed_i, // 2 operands
  input fpnew_pkg::roundmode_e     rnd_mode_i,
  // Output signals
  output logic                     out_valid_o,
  output logic [WIDTH-1:0]         result_o,
  output fpnew_pkg::status_t       status_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);
  localparam int unsigned BIAS     = fpnew_pkg::bias(FpFormat);
  // Precision bits 'p' include the implicit bit
  localparam int unsigned PRECISION_BITS = MAN_BITS + 1;
  // The lower 2p+3 bits of the internal FMA result will be needed for leading-zero detection
  localparam int unsigned LOWER_SUM_WIDTH  = 2 * PRECISION_BITS + 3;
  localparam int unsigned LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
  // Internal exponent width of FMA must accomodate all meaningful exponent values in order to avoid
  // datapath leakage. This is either given by the exponent bits or the width of the LZC result.
  // In most reasonable FP formats the internal exponent will be wider than the LZC result.
  localparam int unsigned EXP_WIDTH = unsigned'(fpnew_pkg::maximum(EXP_BITS + 2, LZC_RESULT_WIDTH));
  // Shift amount width: maximum internal mantissa size is 3p+4 bits
  localparam int unsigned SHIFT_AMOUNT_WIDTH = $clog2(3 * PRECISION_BITS + 5);

  // ----------------
  // Type definition
  // ----------------
  typedef struct packed {
    logic                sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  logic[1:0][WIDTH-1:0]                   st1_operands_q;
  logic[1:0]                              st1_is_boxed_q;
  fpnew_pkg::roundmode_e                  st1_rnd_mode_q;
  logic                                   st1_valid_q;
//======================================================================================================================
// Stage0 : input pipeline
//======================================================================================================================
    always_ff @(posedge clk_i) begin
        st1_operands_q <= operands_i;
        st1_is_boxed_q <= is_boxed_i;
        st1_rnd_mode_q <= rnd_mode_i;
        st1_valid_q    <= in_valid_i;
    end
//======================================================================================================================
// Stage1 : input classification and special case handling
//======================================================================================================================
    // -----------------
    // Input processing
    // -----------------
    fpnew_pkg::fp_info_t [1:0] info_q;

    // Classify input
    fpnew_classifier #(
      .FpFormat    ( FpFormat ),
      .NumOperands ( 2        )
      ) i_class_inputs (
      .operands_i ( st1_operands_q ),
      .is_boxed_i ( st1_is_boxed_q ),
      .info_o     ( info_q         )
    );

    fp_t                 operand_a, operand_b;
    fpnew_pkg::fp_info_t info_a,    info_b;

    always_comb begin : op_select
      operand_a = st1_operands_q[0];
      operand_b = st1_operands_q[1];
      info_a    = info_q[0];
      info_b    = info_q[1];
    end

    // ---------------------
    // Input classification
    // ---------------------
    logic any_operand_inf;
    logic any_operand_nan;
    logic signalling_nan;
    logic effective_subtraction;
    logic tentative_sign;

    // Reduction for special case handling
    assign any_operand_inf = (| {info_a.is_inf,        info_b.is_inf        });
    assign any_operand_nan = (| {info_a.is_nan,        info_b.is_nan        });
    assign signalling_nan  = (| {info_a.is_signalling, info_b.is_signalling });
    // Effective subtraction in FMA occurs when product and addend signs differ
    // assign effective_subtraction = operand_a.sign ^ operand_b.sign ^ operand_c.sign;
    // The tentative sign of the FMA shall be the sign of the product
    assign tentative_sign = operand_a.sign ^ operand_b.sign;

    // ----------------------
    // Special case handling
    // ----------------------
    fp_t                special_result;
    fpnew_pkg::status_t special_status;
    logic               result_is_special;

    always_comb begin : special_cases
        // Default assignments
        special_result    = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)}; // canonical qNaN
        special_status    = '0;
        result_is_special = 1'b0;

        // Handle potentially mixed nan & infinity input => important for the case where infinity and
        // zero are multiplied and added to a qnan.
        // RISC-V mandates raising the NV exception in these cases:
        // (inf * 0) + c or (0 * inf) + c INVALID, no matter c (even quiet NaNs)
        if ((info_a.is_inf && info_b.is_zero) || (info_a.is_zero && info_b.is_inf)) begin
          result_is_special = 1'b1; // bypass FMA, output is the canonical qNaN
          special_status.NV = 1'b1; // invalid operation
        // NaN Inputs cause canonical quiet NaN at the output and maybe invalid OP
        end else if (any_operand_nan) begin
          result_is_special = 1'b1;           // bypass FMA, output is the canonical qNaN
          special_status.NV = signalling_nan; // raise the invalid operation flag if signalling
        // Special cases involving infinity
        end else if (any_operand_inf) begin
            result_is_special = 1'b1; // bypass FMA
            special_result    = '{sign: operand_a.sign ^ operand_b.sign, exponent: '1, mantissa: '0};
        end
    end

//======================================================================================================================
// Stage2 : multiply
//======================================================================================================================
    fp_t                                    st2_operand_a, st2_operand_b;
    fpnew_pkg::fp_info_t                    st2_info_a,    st2_info_b;
    fpnew_pkg::roundmode_e                  st2_rnd_mode_q;
    logic                                   st2_valid_q;
    fp_t                                    st2_special_result;
    fpnew_pkg::status_t                     st2_special_status;
    logic                                   st2_result_is_special;
    logic                                   st2_tentative_sign;

    always_ff @(posedge clk_i) begin
        st2_operand_a   <= operand_a;
        st2_operand_b   <= operand_b;
        st2_info_a      <= info_a;
        st2_info_b      <= info_b;
        st2_rnd_mode_q  <= st1_rnd_mode_q;
        st2_valid_q     <= st1_valid_q;
        st2_special_result <= special_result;
        st2_special_status <= special_status;
        st2_result_is_special <= result_is_special;
        st2_tentative_sign <= tentative_sign;
    end    

    // ---------------------------
    // Initial exponent data path
    // ---------------------------
    logic signed [EXP_WIDTH-1:0] exponent_a, exponent_b;
    logic signed [EXP_WIDTH-1:0] exponent_product;
    logic signed [EXP_WIDTH-1:0] tentative_exponent;

    // Zero-extend exponents into signed container - implicit width extension
    assign exponent_a = signed'({1'b0, st2_operand_a.exponent});
    assign exponent_b = signed'({1'b0, st2_operand_b.exponent});
    // Calculate internal exponents from encoded values. Real exponents are (ex = Ex - bias + 1 - nx)
    // with Ex the encoded exponent and nx the implicit bit. Internal exponents stay biased.
    // Biased product exponent is the sum of encoded exponents minus the bias.
    assign exponent_product = (st2_info_a.is_zero || st2_info_b.is_zero)
                              ? 2 - signed'(BIAS) // in case the product is zero, set minimum exp.
                              : signed'(exponent_a + st2_info_a.is_subnormal
                                        + exponent_b + st2_info_b.is_subnormal
                                        - signed'(BIAS));
    // The tentative exponent will be the larger of the product or addend exponent
    assign tentative_exponent = exponent_product;

    // ------------------
    // Product data path
    // ------------------
    logic [PRECISION_BITS:0]   mantissa_a, mantissa_b;
    logic [2*PRECISION_BITS+1:0] product;             // the p*p product is 2p bits wide
    logic [3*PRECISION_BITS+3:0] product_shifted;     // addends are 3p+4 bit wide (including G/R)

    // Add implicit bits to mantissae
    assign mantissa_a = {1'b0,st2_info_a.is_normal, st2_operand_a.mantissa};
    assign mantissa_b = {1'b0,st2_info_b.is_normal, st2_operand_b.mantissa};

    // Mantissa multiplier (a*b)
    // assign product = mantissa_a * mantissa_b;
    // multiplier
    mult_pip_wrap # (
        .IWTH     (PRECISION_BITS+1),
        .DLY_NUM  (1)
    ) man_mult(
        .clk_i  (clk_i),
        .a_i    (mantissa_a),
        .b_i    (mantissa_b),
        .prod_o (product)
    );

    // Product is placed into a 3p+4 bit wide vector, padded with 2 bits for round and sticky:
    // | 000...000 | product | RS |
    //  <-  p+2  -> <-  2p -> < 2>
    assign product_shifted = product[2*PRECISION_BITS-1:0] << 2; // constant shift

    logic [3*PRECISION_BITS+3:0] sum;       // discard carry as sum won't overflow
    logic                        final_sign;
    // Complement negative sum (can only happen in subtraction -> overflows for positive results)
    assign sum        = product_shifted;
    // In case of a mispredicted subtraction result, do a sign flip
    assign final_sign = st2_tentative_sign;

    logic signed [EXP_WIDTH-1:0] tmp_exponent_product;
    logic                        tmp_tentative_exponent;
    logic                        tmp_final_sign;
    fpnew_pkg::roundmode_e       tmp_rnd_mode_q;
    logic                        tmp_valid_q;
    fp_t                         tmp_special_result;
    fpnew_pkg::status_t          tmp_special_status;
    logic                        tmp_result_is_special;

    always_ff @(posedge clk_i) begin
        tmp_exponent_product   <= exponent_product;
        tmp_tentative_exponent <= tentative_exponent;
        tmp_final_sign         <= final_sign;
        tmp_rnd_mode_q         <= st2_rnd_mode_q;
        tmp_valid_q            <= st2_valid_q;
        tmp_special_result     <= st2_special_result;
        tmp_special_status     <= st2_special_status;
        tmp_result_is_special  <= st2_result_is_special;
    end

//======================================================================================================================
// Stage3 : lookup leading zero 
//======================================================================================================================
    logic signed [EXP_WIDTH-1:0]   st3_exponent_product;
    logic signed [EXP_WIDTH-1:0]   st3_tentative_exponent;
    logic [SHIFT_AMOUNT_WIDTH-1:0] st3_addend_shamt;
    logic [3*PRECISION_BITS+3:0]   st3_sum;
    logic                          st3_final_sign;
    fpnew_pkg::roundmode_e         st3_rnd_mode;
    logic                          st3_result_is_special;
    fp_t                           st3_special_result;
    fpnew_pkg::status_t            st3_special_status;
    logic                          st3_valid;

    always_ff @(posedge clk_i) begin
        st3_exponent_product            <= tmp_exponent_product;
        st3_tentative_exponent          <= tmp_tentative_exponent;
        st3_sum                         <= sum;
        st3_final_sign                  <= tmp_final_sign;
        st3_rnd_mode                    <= tmp_rnd_mode_q;
        st3_result_is_special           <= tmp_result_is_special;
        st3_special_result              <= tmp_special_result;
        st3_special_status              <= tmp_special_status;
        st3_valid                       <= tmp_valid_q;
    end    
    // --------------
    // Normalization
    // --------------
    logic        [LOWER_SUM_WIDTH-1:0]  sum_lower;              // lower 2p+3 bits of sum are searched
    logic        [LZC_RESULT_WIDTH-1:0] leading_zero_count;     // the number of leading zeroes
    logic                               lzc_zeroes;             // in case only zeroes found

    logic        [SHIFT_AMOUNT_WIDTH-1:0] norm_shamt; // Normalization shift amount
    logic signed [EXP_WIDTH-1:0]          normalized_exponent;

    logic [3*PRECISION_BITS+4:0] sum_shifted;       // result after first normalization shift
    logic [PRECISION_BITS:0]     final_mantissa;    // final mantissa before rounding with round bit
    logic [2*PRECISION_BITS+2:0] sum_sticky_bits;   // remaining 2p+3 sticky bits after normalization
    logic                        sticky_after_norm; // sticky bit after normalization

    logic signed [EXP_WIDTH-1:0] final_exponent;

    assign sum_lower = st3_sum[LOWER_SUM_WIDTH-1:0];

    // Leading zero counter for cancellations
    lzc #(
      .WIDTH ( LOWER_SUM_WIDTH ),
      .MODE  ( 1               ) // MODE = 1 counts leading zeroes
    ) i_lzc (
      .in_i    ( sum_lower          ),
      .cnt_o   ( leading_zero_count ),
      .empty_o ( lzc_zeroes         )
    );

  logic signed [LZC_RESULT_WIDTH:0]   leading_zero_count_sgn; // signed leading-zero count
  assign leading_zero_count_sgn = signed'({1'b0, leading_zero_count});

    // Normalization shift amount based on exponents and LZC (unsigned as only left shifts)
    always_comb begin : norm_shift_amount
        // Product-anchored case or cancellations require LZC
        // Normal result (biased exponent > 0 and not a zero)
        if ((st3_exponent_product - leading_zero_count_sgn + 1 >= 0) && !lzc_zeroes) begin
          // Undo initial product shift, remove the counted zeroes
          norm_shamt          = PRECISION_BITS + 2 + leading_zero_count;
          normalized_exponent = st3_exponent_product - leading_zero_count_sgn + 1; // account for shift
        // Subnormal result
        end else begin
          // Cap the shift distance to align mantissa with minimum exponent
          norm_shamt          = unsigned'(signed'(PRECISION_BITS) + 2 + st3_exponent_product);
          normalized_exponent = 0; // subnormals encoded as 0
        end
    end
//======================================================================================================================
// Stage4 : normalization
//======================================================================================================================
  logic        [SHIFT_AMOUNT_WIDTH-1:0] st4_norm_shamt; // Normalization shift amount
  logic signed [EXP_WIDTH-1:0]          st4_normalized_exponent;
  logic [3*PRECISION_BITS+3:0]          st4_sum;
  logic                                 st4_final_sign;
  fpnew_pkg::roundmode_e                st4_rnd_mode;
  logic                                 st4_result_is_special;
  fp_t                                  st4_special_result;
  fpnew_pkg::status_t                   st4_special_status;
  logic                                 st4_valid;


  always_ff @(posedge clk_i) begin
    st4_norm_shamt <= norm_shamt;
    st4_normalized_exponent <= normalized_exponent;
    st4_sum <= st3_sum;
    st4_final_sign <= st3_final_sign;
    st4_rnd_mode <= st3_rnd_mode;
    st4_result_is_special <= st3_result_is_special;
    st4_special_result <= st3_special_result;
    st4_special_status <= st3_special_status;
    st4_valid <= st3_valid;
  end


  // Do the large normalization shift
  assign sum_shifted       = st4_sum << st4_norm_shamt;

  // The addend-anchored case needs a 1-bit normalization since the leading-one can be to the left
  // or right of the (non-carry) MSB of the sum.
  always_comb begin : small_norm
    // Default assignment, discarding carry bit
    {final_mantissa, sum_sticky_bits} = sum_shifted;
    final_exponent                    = st4_normalized_exponent;

    // The normalized sum has overflown, align right and fix exponent
    if (sum_shifted[3*PRECISION_BITS+4]) begin // check the carry bit
      {final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
      final_exponent                    = st4_normalized_exponent + 1;
    // The normalized sum is normal, nothing to do
    end else if (sum_shifted[3*PRECISION_BITS+3]) begin // check the sum MSB
      // do nothing
    // The normalized sum is still denormal, align left - unless the result is not already subnormal
    end else if (st4_normalized_exponent > 1) begin
      {final_mantissa, sum_sticky_bits} = sum_shifted << 1;
      final_exponent                    = st4_normalized_exponent - 1;
    // Otherwise we're denormal
    end else begin
      final_exponent = '0;
    end
  end

  // Update the sticky bit with the shifted-out bits
  assign sticky_after_norm = (| {sum_sticky_bits});

//======================================================================================================================
// Stage5 : Rounding and classification
//======================================================================================================================
    logic signed [EXP_WIDTH-1:0] st5_final_exponent;
    logic                        st5_final_sign;
    logic [PRECISION_BITS:0]     st5_final_mantissa;    
    logic                        st5_sticky_after_norm; 
    fpnew_pkg::roundmode_e       st5_rnd_mode;
    logic                        st5_effective_subtraction;
    logic                        st5_result_is_special;
    fp_t                         st5_special_result;
    fpnew_pkg::status_t          st5_special_status;
    logic                        st5_valid;

    always_ff @(posedge clk_i) begin
        st5_final_exponent <= final_exponent;
        st5_final_sign     <= st4_final_sign;
        st5_final_mantissa <= final_mantissa;
        st5_sticky_after_norm <= sticky_after_norm;
        st5_rnd_mode       <= st4_rnd_mode;
        // st4_effective_subtraction <= st4_effective_subtraction;
        st5_result_is_special   <= st4_result_is_special;
        st5_special_result      <= st4_special_result;
        st5_special_status      <= st4_special_status;
        st5_valid               <= st4_valid;
    end


  logic                         pre_round_sign;
  logic [EXP_BITS-1:0]          pre_round_exponent;
  logic [MAN_BITS-1:0]          pre_round_mantissa;
  logic [EXP_BITS+MAN_BITS-1:0] pre_round_abs; // absolute value of result before rounding
  logic [1:0]                   round_sticky_bits;

  logic of_before_round, of_after_round; // overflow
  logic uf_before_round, uf_after_round; // underflow
  logic result_zero;

  logic                         rounded_sign;
  logic [EXP_BITS+MAN_BITS-1:0] rounded_abs; // absolute value of result after rounding

  // Classification before round. RISC-V mandates checking underflow AFTER rounding!
  assign of_before_round = st5_final_exponent >= 2**(EXP_BITS)-1; // infinity exponent is all ones
  assign uf_before_round = st5_final_exponent == 0;               // exponent for subnormals capped to 0

  // Assemble result before rounding. In case of overflow, the largest normal value is set.
  assign pre_round_sign     = st5_final_sign;
  assign pre_round_exponent = (of_before_round) ? 2**EXP_BITS-2 : unsigned'(st5_final_exponent[EXP_BITS-1:0]);
  assign pre_round_mantissa = (of_before_round) ? '1 : st5_final_mantissa[MAN_BITS:1]; // bit 0 is R bit
  assign pre_round_abs      = {pre_round_exponent, pre_round_mantissa};

  // In case of overflow, the round and sticky bits are set for proper rounding
  assign round_sticky_bits  = (of_before_round) ? 2'b11 : {st5_final_mantissa[0], st5_sticky_after_norm};

  // Perform the rounding
  fpnew_rounding #(
    .AbsWidth ( EXP_BITS + MAN_BITS )
  ) i_fpnew_rounding (
    .abs_value_i             ( pre_round_abs           ),
    .sign_i                  ( pre_round_sign          ),
    .round_sticky_bits_i     ( round_sticky_bits       ),
    .rnd_mode_i              ( st5_rnd_mode            ),
    .effective_subtraction_i ( 1'b1                    ),
    .abs_rounded_o           ( rounded_abs             ),
    .sign_o                  ( rounded_sign            ),
    .exact_zero_o            ( result_zero             )
  );

  // Classification after rounding
  assign uf_after_round = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '0; // exponent = 0
  assign of_after_round = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '1; // exponent all ones

  // -----------------
  // Result selection
  // -----------------
  logic [WIDTH-1:0]     regular_result;
  fpnew_pkg::status_t   regular_status;

  // Assemble regular result
  assign regular_result    = {rounded_sign, rounded_abs};
  assign regular_status.NV = 1'b0; // only valid cases are handled in regular path
  assign regular_status.DZ = 1'b0; // no divisions
  assign regular_status.OF = of_before_round | of_after_round;   // rounding can introduce overflow
  assign regular_status.UF = uf_after_round & regular_status.NX; // only inexact results raise UF
  assign regular_status.NX = (| round_sticky_bits) | of_before_round | of_after_round;

  // Final results for output pipeline
  fp_t                result_d;
  fpnew_pkg::status_t status_d;

  // Select output depending on special case detection
  assign result_d = st5_result_is_special ? st5_special_result : regular_result;
  assign status_d = st5_result_is_special ? st5_special_status : regular_status;

//======================================================================================================================
// Stage6 : output
//======================================================================================================================
    always_ff @(posedge clk_i) begin
        out_valid_o <= st5_valid;
        result_o    <= result_d;
        status_o    <= status_d;
    end

endmodule
