`timescale 1ns/1ps
/*
Testbench autoverificable para el módulo lzc.
Con WIDTH pequeño (<=16) hace prueba EXHAUSTIVA de todos los vectores
contra un modelo de referencia. Sube WIDTH y cambia a aleatorio si quieres.
*/
module tb_lzc;

  localparam int WIDTH = 8;                 // ancho bajo prueba (8 -> 256 vectores)
  localparam int CW    = $clog2(WIDTH) + 1; // ancho del contador (0..WIDTH)

  logic [WIDTH-1:0] src;
  logic [CW-1:0]    lzc_count;
  logic             all_zero;

  // DUT
  lzc #(.WIDTH(WIDTH)) dut (
    .src       (src),
    .lzc_count (lzc_count),
    .all_zero  (all_zero)
  );

  // Modelo de referencia: cuenta ceros desde el MSB
  function automatic int unsigned ref_lzc(input logic [WIDTH-1:0] v);
    ref_lzc = WIDTH;                  // si todos son cero -> WIDTH
    for (int i = WIDTH-1; i >= 0; i--)
      if (v[i]) begin
        ref_lzc = (WIDTH-1) - i;      // posicion del primer 1 desde el MSB
        break;
      end
  endfunction

  int errors = 0;

  task automatic check(input logic [WIDTH-1:0] v);
    int unsigned exp_cnt;
    logic        exp_az;
    src = v;
    #1;                              // propagar la logica combinacional
    exp_cnt = ref_lzc(v);
    exp_az  = (v == '0);
    if (lzc_count !== exp_cnt[CW-1:0] || all_zero !== exp_az) begin
      $error("FAIL src=%b -> cnt=%0d az=%b | esperado cnt=%0d az=%b",
             v, lzc_count, all_zero, exp_cnt, exp_az);
      errors++;
    end
  endtask

  initial begin
    // Prueba exhaustiva (valida la estructura recursiva completa)
    for (int v = 0; v < (1 << WIDTH); v++)
      check(v[WIDTH-1:0]);

    if (errors == 0)
      $display("[PASS] Todos los %0d vectores correctos.", (1 << WIDTH));
    else
      $display("[FAIL] %0d casos fallaron.", errors);
    $finish;
  end

endmodule
