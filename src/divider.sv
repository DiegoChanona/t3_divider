// Divisor SRT radix-2 PIPELINED. Datapath en WIDTH etapas con un registro entre
// cada una: throughput 1 division/ciclo, latencia ~WIDTH+1.
// Todo el estado de una etapa va en UN solo registro 'stage_t': el dato activo
// (p, qp, qn) y la metadata que viaja sin cambiar (d, lzc, signos, dz, srca).
module divider #(
  parameter int WIDTH = 64
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] srca,
  input  logic [WIDTH-1:0] srcb,
  input  logic             is_signed,
  output logic [WIDTH-1:0] result,
  output logic [WIDTH-1:0] rem,
  output logic             div_zero_f
);
  localparam int RW = 2*WIDTH + 2;
  localparam int LW = $clog2(WIDTH) + 1;

  typedef struct packed {
    logic signed [RW-1:0] p;     // residuo parcial
    logic [WIDTH-1:0]     qp;    // acumulador de digitos +1
    logic [WIDTH-1:0]     qn;    // acumulador de digitos -1
    logic signed [RW-1:0] d;     // divisor alineado (metadata)
    logic [LW-1:0]        lzc;   // ceros a la izquierda del divisor
    logic                 rs;    // signo del cociente
    logic                 ms;    // signo del residuo
    logic                 dz;    // division por cero
    logic [WIDTH-1:0]     a;     // srca (para rem en div/0)
  } stage_t;

  // preprocess combinacional a la entrada
  logic [WIDTH-1:0] n_abs, d_abs;
  logic [LW-1:0]    lzc;
  logic             rsgn, msgn, dz;
  srt_preprocess #(.WIDTH(WIDTH)) u_pre (
    .srca, .srcb, .is_signed,
    .n_abs, .d_abs, .lzc, .result_sign(rsgn), .rem_sign(msgn), .div_zero(dz)
  );

  // valor que entra al pipe (etapa 0)
  stage_t in;
  always_comb begin
    in.p   = RW'(n_abs) << lzc;
    in.qp  = '0;
    in.qn  = '0;
    in.d   = RW'(d_abs) << (lzc + WIDTH);
    in.lzc = lzc;
    in.rs  = rsgn;
    in.ms  = msgn;
    in.dz  = dz;
    in.a   = srca;
  end

  stage_t pipe [WIDTH+1];   // un registro por etapa
  stage_t nxt  [WIDTH];     // valor combinacional siguiente de cada etapa

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : g_stage
      logic                 qpos, qneg;
      logic signed [RW-1:0] p_out;
      logic [WIDTH-1:0]     qp_out, qn_out;
      srt_stage #(.RW(RW), .EW(3), .FRAC_W(1)) u_st (
        .p(pipe[i].p), .d(pipe[i].d), .ns(p_out), .q_pos(qpos), .q_neg(qneg)
      );
      srt_quot #(.WIDTH(WIDTH)) u_q (
        .qp(pipe[i].qp), .qn(pipe[i].qn), .q_pos(qpos), .q_neg(qneg),
        .qp_next(qp_out), .qn_next(qn_out)
      );
      // siguiente estado = el actual con el dato actualizado      
      always_comb begin
        nxt[i]    = pipe[i];
        nxt[i].p  = p_out;
        nxt[i].qp = qp_out;
        nxt[i].qn = qn_out;
      end
    end
  endgenerate

  // avance del pipeline: un registro por etapa
  always_ff @(posedge clk) begin
    pipe[0] <= in;
    for (int s = 1; s <= WIDTH; s++)
      pipe[s] <= nxt[s-1];
  end

  // post-procesamiento combinacional sobre la ultima etapa
  logic                 p_neg;
  logic [WIDTH-1:0]     q_corr, rem_mag, q_signed, r_signed;
  logic signed [RW-1:0] p_fix;
  assign p_neg   = pipe[WIDTH].p[RW-1];
  assign q_corr  = p_neg ? (pipe[WIDTH].qp - pipe[WIDTH].qn - 1'b1)
                         : (pipe[WIDTH].qp - pipe[WIDTH].qn);
  assign p_fix   = p_neg ? (pipe[WIDTH].p + pipe[WIDTH].d) : pipe[WIDTH].p;
  assign rem_mag = WIDTH'(p_fix >> (pipe[WIDTH].lzc + WIDTH));

  cond_neg #(.WIDTH(WIDTH)) u_qs (.in(q_corr),  .do_neg(pipe[WIDTH].rs), .out(q_signed));
  cond_neg #(.WIDTH(WIDTH)) u_rs (.in(rem_mag), .do_neg(pipe[WIDTH].ms), .out(r_signed));

  assign result     = pipe[WIDTH].dz ? '1           : q_signed;
  assign rem        = pipe[WIDTH].dz ? pipe[WIDTH].a : r_signed;
  assign div_zero_f = pipe[WIDTH].dz;
endmodule
