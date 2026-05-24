`include "macro.svh"

module fifo #(
    parameter DATA_W = 8,
    parameter ADDR_W = 5
)(
     input  logic              wclk
     /* verilator lint_off UNUSEDSIGNAL */
    ,input  logic              rclk
     /* verilator lint_off UNUSEDSIGNAL */
    ,input  logic              arstb

    ,input  logic [DATA_W-1:0] WPORT_DATA
    ,input  logic              WPORT_MEB
    ,input  logic              WPORT_WEB
    ,input  logic [ADDR_W-1:0] WPORT_ADDR

    ,output logic [DATA_W-1:0] RPORT_DATA
    ,input  logic              RPORT_MEB
    ,input  logic              RPORT_WEB
    ,input  logic [ADDR_W-1:0] RPORT_ADDR
);

logic [DATA_W-1:0] mem [2**ADDR_W-1:0];
logic [DATA_W-1:0] mem_next [2**ADDR_W-1:0];

assign RPORT_DATA = (RPORT_MEB == 1'b0 && RPORT_WEB == 1'b0) ? mem[RPORT_ADDR] : '0;
generate
    for (genvar i = 0; i < 2**ADDR_W; i = i + 1) begin: mem_gen
        assign mem_next[i] = (WPORT_MEB == 1'b0 && WPORT_WEB == 1'b0 && WPORT_ADDR == ADDR_W'(i)) ? WPORT_DATA : mem[i];
        `PRIM_FF_ARSTB(mem[i], mem_next[i], arstb, wclk, '0)
    end
endgenerate

endmodule
