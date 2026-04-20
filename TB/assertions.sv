module adder_assertions(adder_if vif);

  property p_add_correct;
    @(posedge vif.clk)
    disable iff (vif.reset)
    (vif.ip1 + vif.ip2) |=> (vif.out == $past(vif.ip1 + vif.ip2));
  endproperty

  assert property (p_add_correct)
    else $error("ASSERTION FAILED: Wrong output!");

endmodule