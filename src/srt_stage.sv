// Una iteración del divisor SRT radix-2
module srt_stage #(
  parameter int RW     = 68,   // ancho del residuo, con bits de guarda
  parameter int EW     = 2,    // bits altos que mira qds
  parameter int FRAC_W = 1
)(
  input  logic signed [RW-1:0] p,
  input  logic signed [RW-1:0] d,    // divisor normalizado, alineado al residuo
  output logic signed [RW-1:0] ns,  // residuo siguiente
  output logic                 q_pos,
  output logic                 q_neg
);
  // 2R
  logic signed [RW-1:0] r2;
  assign r2 = p << 1;

  // qds mira los bits altos de 2R directamente
  logic signed [EW-1:0] est;
  assign est = r2[RW-1 -: EW];

  qds #(.EW(EW), .FRAC_W(FRAC_W)) u_qds (
    .est(est), .q_pos(q_pos), .q_neg(q_neg)
  );

  // R' = 2R - q*D
  logic signed [RW-1:0] addend;
  assign addend = q_pos ? -d : (q_neg ? d : '0);
  assign ns = r2 + addend;
endmodule
