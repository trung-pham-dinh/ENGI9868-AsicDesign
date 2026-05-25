`include "prim.svh"

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
    ,input  logic              RPORT_REB
    ,input  logic [ADDR_W-1:0] RPORT_ADDR
);

logic [DATA_W-2:0] mem [2**ADDR_W-1:0];
logic [DATA_W-2:0] mem_next [2**ADDR_W-1:0];
logic [ADDR_W-1:0] eop_idx, eop_idx_next;
logic eop_bit;

assign eop_bit    = eop_idx == RPORT_ADDR;
assign RPORT_DATA = (RPORT_MEB == 1'b0 && RPORT_REB == 1'b0) ? {eop_bit, mem[RPORT_ADDR]} : '0;
generate
    for (genvar i = 0; i < 2**ADDR_W; i = i + 1) begin: mem_gen
        assign mem_next[i] = (WPORT_MEB == 1'b0 && WPORT_WEB == 1'b0 && WPORT_ADDR == ADDR_W'(i)) ? WPORT_DATA[DATA_W-2:0] : mem[i];
        `PRIM_FF_ARSTB(mem[i], mem_next[i], arstb, wclk, '0)
    end
endgenerate

always_comb begin
    if (WPORT_MEB == 1'b0 && WPORT_WEB == 1'b0) begin
        eop_idx_next = WPORT_DATA[DATA_W-1] ? WPORT_ADDR : eop_idx;
    end else begin
        eop_idx_next = eop_idx;
    end
end

`PRIM_FF_ARSTB(eop_idx, eop_idx_next, arstb, wclk, '0)

endmodule
