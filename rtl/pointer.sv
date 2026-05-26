`include "prim.svh"

module pointer #(
    parameter ADDR_W = 5
)(
     input  logic              clk
    ,input  logic              arstb
    ,input  logic              ptr_ld_ps
    ,input  logic              ptr_en_lv
    ,output logic [ADDR_W-1:0] ptr_val
);

logic [ADDR_W-1:0] ptr_val_next;

always_comb begin
    if (ptr_en_lv == 1'b1) begin
        ptr_val_next = (ptr_ld_ps == 1'b1) ? '0 : ptr_val + 1;
    end 
    else begin
        ptr_val_next = ptr_val;
    end
end

`PRIM_FF_ARSTB(ptr_val, ptr_val_next, arstb, clk, '0)
    
endmodule
