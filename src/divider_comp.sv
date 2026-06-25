/*
Divisor comportamental como referencia para nuestro divisor de 64 bits.
*/


module divider_comp #(
  parameter int WIDTH = 64
) (
  input  logic [WIDTH-1:0] srca,
  input  logic [WIDTH-1:0] srcb,
  input  logic             is_signed,
  output logic [WIDTH-1:0] result,
  output logic [WIDTH-1:0] rem,
  output logic             div_zero_f
);
  
  always_comb begin
    if (srcb == 0) begin
      result       = '1;
      rem          = srca;
      div_zero_f   = 1;
    end else if (is_signed) begin
      result       = $signed(srca) / $signed(srcb);
      rem          = $signed(srca) % $signed(srcb);
      div_zero_f   = 0;
    end else begin
      result       = srca / srcb;
      rem          = srca % srcb;
      div_zero_f   = 0;
    end
  end
endmodule