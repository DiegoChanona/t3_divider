/*
Negador condicional en complemento a 2.
Reutilizado 4 veces en el divisor:
  - abs(srca) = cond_neg(srca, srca[MSB])
  - abs(srcb) = cond_neg(srcb, srcb[MSB])
  - reaplicar signo al cociente = cond_neg(Q_mag, q_sign)
  - reaplicar signo al residuo  = cond_neg(rem_mag, rem_sign)
*/
module cond_neg #(
  parameter int WIDTH = 64
)(
  input  logic [WIDTH-1:0] in,
  input  logic             do_neg,   // 1 -> out = -in ; 0 -> out = in
  output logic [WIDTH-1:0] out
);
  assign out = do_neg ? (~in + 1'b1) : in;
endmodule
