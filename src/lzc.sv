/*
Leading Zero Count (LZC) module
This module counts the number of leading zeros in a binary input vector.
Is used on the divider to determine the number of bits to shift the divisor and dividend for normalization.

*/


module lzc #(
  parameter int WIDTH = 32
) (
  input  logic [WIDTH-1:0] src,
  output logic [$clog2(WIDTH):0] lzc_count,
  output logic all_zero
);
  generate 
    if (WIDTH ==1) begin : g_base
        assign lzc_count = ~src[0];
        assign all_zero = ~src[0];
    end else begin : g_rec
        localparam int HALF = WIDTH / 2;
        logic [$clog2(HALF):0] cnt_hi, cnt_lo;
        logic az_hi, az_lo; //señales de "all zero" para cada mitad

        // Instancias para la mitad alta y baja para dividir la ruta crítica 
        lzc #(.WIDTH(HALF)) u_hi (.src(src[WIDTH-1:HALF]), .lzc_count(cnt_hi), .all_zero(az_hi));
        lzc #(.WIDTH(HALF)) u_lo (.src(src[HALF-1:0]),     .lzc_count(cnt_lo), .all_zero(az_lo));

        assign all_zero = az_hi & az_lo; // Señal completa de "all zero"

        // Si la mitad alta tiene un 1 -> el conteo lo da ella (cnt_hi).
        // Si la mitad alta es todo ceros -> HALF + conteo de la mitad baja.
        always_comb
          lzc_count = az_hi ? (HALF + cnt_lo) : cnt_hi;
    end
  endgenerate

endmodule