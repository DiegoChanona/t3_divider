// Pre-procesamiento del divisor SRT: valor absoluto, CLZ del divisor y signos.
// La extension y los shifts de normalizacion los hace divider.sv.
module srt_preprocess #(
  parameter int WIDTH = 64
)(
  input  logic [WIDTH-1:0]       srca,         // dividendo
  input  logic [WIDTH-1:0]       srcb,         // divisor
  input  logic                   is_signed,

  output logic [WIDTH-1:0]       n_abs,         // |dividendo|
  output logic [WIDTH-1:0]       d_abs,         // |divisor|
  output logic [$clog2(WIDTH):0] lzc,           // ceros a la izquierda del divisor
  output logic                   result_sign,   // signo del cociente
  output logic                   rem_sign,      // signo del residuo (sigue al dividendo)
  output logic                   div_zero
);
  logic sign_a, sign_b;
  assign sign_a = is_signed & srca[WIDTH-1];
  assign sign_b = is_signed & srcb[WIDTH-1];

  cond_neg #(.WIDTH(WIDTH)) u_abs_a (.in(srca), .do_neg(sign_a), .out(n_abs));
  cond_neg #(.WIDTH(WIDTH)) u_abs_b (.in(srcb), .do_neg(sign_b), .out(d_abs));

  lzc #(.WIDTH(WIDTH)) u_lzc (.src(d_abs), .lzc_count(lzc), .all_zero(div_zero));

  assign result_sign = sign_a ^ sign_b;
  assign rem_sign    = sign_a;
endmodule
