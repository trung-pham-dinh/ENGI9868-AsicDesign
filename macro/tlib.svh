`ifndef TLIB_SVH
`define TLIB_SVH

// TASK: Clock Generator
task automatic task_clock_gen(ref logic i_clk, input int DELAY);
  begin
    i_clk = 1'b1;
    forever #(DELAY) i_clk = ~i_clk;
  end
endtask

task automatic task_reset(ref logic i_rst_n, input int RESETPERIOD);
  begin
    i_rst_n = 1'b1;
    #RESETPERIOD i_rst_n = 1'b0;
  end
endtask

task automatic task_resetN(ref logic i_rst_n, input int RESETPERIOD);
  begin
    i_rst_n = 1'b0;
    #RESETPERIOD i_rst_n = 1'b1;
  end
endtask

`endif
