// Pre-procesamiento del divisor SRT.
// Saca |dividendo| y |divisor|, normaliza el divisor a [1/2,1) (MSB=1) para que
// qds use umbrales fijos +/-1/2, y calcula los signos de salida.
// Orden importante: ABS antes que LZC (un negativo tiene unos a la izquierda).
module srt_preprocess #(
  parameter int WIDTH = 64
)(
  input  logic [WIDTH-1:0]       srca,        // dividendo
  input  logic [WIDTH-1:0]       srcb,        // divisor
  input  logic                   is_signed,
  output logic [WIDTH-1:0]       n_abs,        // |dividendo|
  output logic [WIDTH-1:0]       d_norm,       // |divisor| normalizado (MSB=1)
  output logic [$clog2(WIDTH):0] shift_s,      // bits que se recorre el divisor para normalizarlo
  output logic                   result_sign,  // signo del cociente
  output logic                   rem_sign,     // signo del residuo 
  output logic                   div_zero
);
  logic sign_a, sign_b;
  assign sign_a = is_signed & srca[WIDTH-1];
  assign sign_b = is_signed & srcb[WIDTH-1];

  logic [WIDTH-1:0] d_abs;
  cond_neg #(.WIDTH(WIDTH)) u_abs_a (.in(srca), .do_neg(sign_a), .out(n_abs));
  cond_neg #(.WIDTH(WIDTH)) u_abs_b (.in(srcb), .do_neg(sign_b), .out(d_abs));

  logic all_zero;
  lzc #(.WIDTH(WIDTH)) u_lzc (.src(d_abs), .lzc_count(shift_s), .all_zero(all_zero));

  assign d_norm   = d_abs << shift_s; // Se normaliza shifteando el divisor para que el MSB sea 1
  assign div_zero = all_zero;

  assign result_sign = sign_a ^ sign_b;
  assign rem_sign    = sign_a;
endmodule
