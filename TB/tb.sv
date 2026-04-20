`timescale 1ns/1ps
import tb_pkg::*;
module tb;

  logic clk;

  adder_if vif(clk);
  adder dut(vif);
  adder_assertions asrt(vif);

  environment env;

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    vif.reset = 1;

    #10;
    vif.reset = 0;

    env = new(vif);
    env.run();

    #1000;

    $display("\nFinal Coverage = %0.2f %%", env.mon.cg.get_coverage());

    $finish;
  end

endmodule