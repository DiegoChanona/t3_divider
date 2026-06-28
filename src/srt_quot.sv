// Acumulacion del cociente con dos registros: qp marca los digitos +1 y qn los
// digitos -1. Al final divider.sv hace Q = qp - qn (un restador de W bits).
// Es un paso (los registros viven en divider.sv).
module srt_quot #(
  parameter int WIDTH = 64
)(
  input  logic [WIDTH-1:0] qp,
  input  logic [WIDTH-1:0] qn,
  input  logic             q_pos,
  input  logic             q_neg,
  output logic [WIDTH-1:0] qp_next,
  output logic [WIDTH-1:0] qn_next
);
  assign qp_next = (qp << 1) | q_pos;
  assign qn_next = (qn << 1) | q_neg;
endmodule
