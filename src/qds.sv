// Seleccion de digito del cociente, SRT radix-2.
// q ∈ {-1,0,+1} a partir del residuo desplazado 2R (estimado 'est', punto fijo):
//   2R >= +1/2  -> +1 ,  2R < -1/2 -> -1 ,  resto -> 0
// La frontera negativa es ESTRICTA: con el estimado truncado en complemento a 2,
// est=-1 puede ser un valor real en [-1/2,0), asi que -1/2 exacto cae en q=0
// (la redundancia del SRT lo absorbe). Por eso q_neg compara con -HALF estricto.
module qds #(
  parameter int EW     = 3,
  parameter int FRAC_W = 1
)(
  input  logic signed [EW-1:0] est,
  output logic                 q_pos,
  output logic                 q_neg
);
  localparam int HALF = 1 << (FRAC_W - 1);
  assign q_pos = (est >=  HALF);
  assign q_neg = (est <  -HALF);
endmodule
