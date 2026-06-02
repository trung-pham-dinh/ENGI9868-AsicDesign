`include "prim.svh"

module reset_synchronizer #(
    parameter STAGE_NUM = 2
)(
    input  logic clk,
    input  logic rstb_in,
    output logic rstb_out
);

    pipeline #(
        .STAGE_NUM(2),
        .DATA_W   (1)
    ) syncher (
        .clk     (clk     ), 
        .arstb   (rstb_in ),   
        .data_in (1'b1    ),     
        .data_out(rstb_out)      
    );

endmodule