`include "macro.svh"

module counter (
    input  logic clk,
    input  logic reset,
    output logic [3:0] count
);

logic [3:0] count_next;


assign count_next = count + 1'b1;

`PRIM_FF_RST(count, count_next, reset, clk, '0)

endmodule
