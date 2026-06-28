// Divisor SRT radix-2 sin pipeline: throughput 1 division/ciclo, latencia ~WIDTH+1.
module divider_simple #(
  parameter int WIDTH = 64
)(
  input  logic [WIDTH-1:0] srca,
  input  logic [WIDTH-1:0] srcb,
  input  logic             is_signed,
  output logic [WIDTH-1:0] result,
  output logic [WIDTH-1:0] rem,
  output logic             div_zero_f
);
  localparam int RW = 2*WIDTH + 2;       // 2W de fraccion + signo + entero
  localparam int LW = $clog2(WIDTH) + 1;

  logic [WIDTH-1:0] n_abs, d_abs;
  logic [LW-1:0]    lzc;
  logic             result_sign, rem_sign, dz;
  srt_preprocess #(.WIDTH(WIDTH)) u_pre (
    .srca, .srcb, .is_signed,
    .n_abs, .d_abs, .lzc, .result_sign, .rem_sign, .div_zero(dz)
  );

  // normalizacion: REM = dividendo << lzc ; d = divisor << (lzc + WIDTH)
  logic signed [RW-1:0] rem_init, d_al;
  assign rem_init = RW'(n_abs) << lzc;
  assign d_al     = RW'(d_abs) << (lzc + WIDTH);

  logic signed [RW-1:0] p  [WIDTH+1];
  logic [WIDTH-1:0]     qp [WIDTH+1];
  logic [WIDTH-1:0]     qn [WIDTH+1];
  assign p[0]  = rem_init;
  assign qp[0] = '0;
  assign qn[0] = '0;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : g_stage
      logic qpos, qneg;
      srt_stage #(.RW(RW), .EW(3), .FRAC_W(1)) u_st (
        .p(p[i]), .d(d_al), .ns(p[i+1]), .q_pos(qpos), .q_neg(qneg)
      );
      srt_quot #(.WIDTH(WIDTH)) u_q (
        .qp(qp[i]), .qn(qn[i]), .q_pos(qpos), .q_neg(qneg),
        .qp_next(qp[i+1]), .qn_next(qn[i+1])
      );
    end
  endgenerate

  // cociente = qp - qn directo ; correccion -1 si el residuo final es negativo
  logic p_neg;
  assign p_neg = p[WIDTH][RW-1];
  logic [WIDTH-1:0]     q_corr;
  logic signed [RW-1:0] p_fix;
  assign q_corr = p_neg ? (qp[WIDTH] - qn[WIDTH] - 1'b1) : (qp[WIDTH] - qn[WIDTH]);
  assign p_fix  = p_neg ? (p[WIDTH] + d_al) : p[WIDTH];

  // remainder = residuo final denormalizado (>> (lzc + WIDTH))
  logic [WIDTH-1:0] rem_mag;
  assign rem_mag = WIDTH'(p_fix >> (lzc + WIDTH));

  logic [WIDTH-1:0] q_signed, r_signed;
  cond_neg #(.WIDTH(WIDTH)) u_qs (.in(q_corr),  .do_neg(result_sign), .out(q_signed));
  cond_neg #(.WIDTH(WIDTH)) u_rs (.in(rem_mag), .do_neg(rem_sign),    .out(r_signed));

  assign result     = dz ? '1   : q_signed;
  assign rem        = dz ? srca : r_signed;
  assign div_zero_f = dz;
endmodule
