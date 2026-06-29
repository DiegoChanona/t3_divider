// Una iteracion del divisor SRT radix-2 (no redundante).
// Variante con sumador Kogge-Stone (parallel_prefix_adder) en vez del operador +,
// para comparar logic depth / fmax contra la carry chain dedicada.
module srt_stage #(
  parameter int RW     = 68,   // ancho del residuo, con bits de guarda
  parameter int EW     = 3,    // bits altos que mira qds
  parameter int FRAC_W = 1
)(
  input  logic signed [RW-1:0] p,
  input  logic signed [RW-1:0] d,    // divisor normalizado, alineado al residuo
  output logic signed [RW-1:0] ns,   // residuo siguiente
  output logic                 q_pos,
  output logic                 q_neg
);
  // 2R
  logic signed [RW-1:0] r2;
  assign r2 = p << 1;

  // qds mira los bits altos de 2R directamente
  logic signed [EW-1:0] est;
  assign est = r2[RW-1 -: EW];
  qds #(.EW(EW), .FRAC_W(FRAC_W)) u_qds (.est(est), .q_pos(q_pos), .q_neg(q_neg));

  // R' = 2R - q*D :  q=+1 -> r2 + ~d + 1 (resta) ; q=-1 -> r2 + d ; q=0 -> r2
  logic [RW-1:0] addend;
  logic          cin;
  assign addend = q_pos ? ~d : (q_neg ? d : '0);
  assign cin    = q_pos;   // el +1 del complemento a 2 cuando se resta

  logic ppa_cout, ppa_zero, ppa_ov;
  parallel_prefix_adder #(.WIDTH(RW)) u_add (
    .srca(r2), .srcb(addend), .cin(cin), .is_signed(1'b0),
    .result(ns), .cout(ppa_cout), .zero_f(ppa_zero), .ov_f(ppa_ov)
  );
endmodule
