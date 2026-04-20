package tb_pkg;

// ===================== TRANSACTION =====================
class transaction;
  rand bit [7:0] ip1, ip2;
  bit [8:0] out;

  constraint c1 {
    ip1 < 100;
    ip2 < 100;
  }
endclass


// ===================== GENERATOR =====================
class generator;
  transaction tr;
  mailbox #(transaction) mbx;

  // Directed values to hit all bins
  int vals[3] = '{5, 30, 80};

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();

    // Random testing
    repeat (80) begin
      tr = new();
      assert(tr.randomize());
      mbx.put(tr);
    end

    // Directed testing → ensures 100% coverage
    foreach (vals[i]) begin
      foreach (vals[j]) begin
        tr = new();
        tr.ip1 = vals[i];
        tr.ip2 = vals[j];
        mbx.put(tr);
      end
    end

  endtask
endclass


// ===================== DRIVER =====================
class driver;
  virtual adder_if vif;
  mailbox #(transaction) mbx;

  function new(virtual adder_if vif, mailbox #(transaction) mbx);
    this.vif = vif;
    this.mbx = mbx;
  endfunction

  task run();
    transaction tr;

    forever begin
      mbx.get(tr);

      @(posedge vif.clk);
      vif.ip1 = tr.ip1;
      vif.ip2 = tr.ip2;

      @(posedge vif.clk);
      tr.out = vif.out;
    end
  endtask
endclass


// ===================== MONITOR =====================
class monitor;

  virtual adder_if vif;
  mailbox #(transaction) mbx;

  transaction tr;

  covergroup cg;

    option.per_instance = 1;

    ip1_cp: coverpoint tr.ip1 {
      bins low  = {[0:10]};
      bins mid  = {[11:50]};
      bins high = {[51:99]};
    }

    ip2_cp: coverpoint tr.ip2 {
      bins low  = {[0:10]};
      bins mid  = {[11:50]};
      bins high = {[51:99]};
    }

    cross ip1_cp, ip2_cp;

  endgroup


  function new(virtual adder_if vif, mailbox #(transaction) mbx);
    this.vif = vif;
    this.mbx = mbx;
    tr = new();
    cg = new();
  endfunction


  task run();

    forever begin

      transaction tr_local = new();

      @(posedge vif.clk);
      tr_local.ip1 = vif.ip1;
      tr_local.ip2 = vif.ip2;

      // assign for coverage
      tr = tr_local;
      cg.sample();

      @(posedge vif.clk);
      tr_local.out = vif.out;

      mbx.put(tr_local);
    end

  endtask

endclass


// ===================== SCOREBOARD =====================
class scoreboard;
  mailbox #(transaction) mbx;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    transaction tr;
    bit [8:0] expected;

    forever begin
      mbx.get(tr);

      expected = tr.ip1 + tr.ip2;

      if (expected == tr.out)
        $display("PASS: %0d + %0d = %0d", tr.ip1, tr.ip2, tr.out);
      else
        $display("FAIL: %0d + %0d = %0d (expected %0d)", tr.ip1, tr.ip2, tr.out, expected);
    end
  endtask
endclass


// ===================== ENVIRONMENT =====================
class environment;

  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;

  mailbox #(transaction) gen_drv = new();
  mailbox #(transaction) mon_scb = new();

  virtual adder_if vif;

  function new(virtual adder_if vif);
    this.vif = vif;

    gen = new(gen_drv);
    drv = new(vif, gen_drv);
    mon = new(vif, mon_scb);
    scb = new(mon_scb);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_none
  endtask

endclass

endpackage