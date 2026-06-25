// Selección de dígito del cociente, SRT radix-2.
// q E {-1,0,+1} a partir del residuo desplazado 2R:
//   2R >= +1/2 -> +1 ,  2R <= -1/2 -> -1 ,  resto -> 0
// 'est' ya viene asimilado desde srt_stage 
module qds #(
  parameter int EW     = 2,
  parameter int FRAC_W = 1
)(
  input  logic signed [EW-1:0] est,
  output logic                 q_pos,
  output logic                 q_neg
);
  // est es punto fijo con FRAC_W bits de fracción, así que 1/2 -> 2^(FRAC_W-1)
  localparam int HALF = 1 << (FRAC_W - 1);

  assign q_pos = (est >=  HALF);
  assign q_neg = (est <= -HALF);
endmodule
