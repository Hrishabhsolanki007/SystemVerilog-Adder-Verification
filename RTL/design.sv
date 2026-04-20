`timescale 1ns/1ps
module adder(adder_if vif);

  always @(posedge vif.clk) begin
    if (vif.reset)
      vif.out <= 0;
    else
      vif.out <= vif.ip1 + vif.ip2;
  end

endmodule