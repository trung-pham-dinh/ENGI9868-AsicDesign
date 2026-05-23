//`timescale 1ns/1ps

module counter_sim;

logic clk;
logic reset;
logic [3:0] count;

initial begin: proc_dump_wave
  $dumpfile("wave.vcd");
  $dumpvars(0);
end

// Instantiate DUT
counter uut (
    .clk(clk),
    .reset(reset),
    .count(count)
);

// Clock generation: 10ns period
always #5 clk = ~clk;

initial begin
    // Initialize signals
    clk = 0;
    reset = 1;

    // Hold reset for a few cycles
    #20;
    reset = 0;

    // Run simulation
    #100;

    // Finish
    $finish;
end

// Monitor output
initial begin
    $monitor("Time=%0t reset=%b count=%0d", $time, reset, count);
end

endmodule
