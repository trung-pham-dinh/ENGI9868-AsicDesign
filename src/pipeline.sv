module pipeline #(
    parameter STAGE_NUM = 3,
    parameter DATA_W = 8
)(
     input  logic              clk
    ,input  logic              arstb
    ,input  logic [DATA_W-1:0] data_in
    ,output logic [DATA_W-1:0] data_out
);

logic [DATA_W-1:0] stage_data [STAGE_NUM-1:0];

assign data_out = stage_data[STAGE_NUM-1];
for (genvar i = 0; i < STAGE_NUM; i++) begin: stage_gen
    if (i == 0) begin: first_stage
        `PRIM_FF_ARSTB(stage_data[i], data_in, arstb, clk, '0)
    end else begin: other_stages
        `PRIM_FF_ARSTB(stage_data[i], stage_data[i-1], arstb, clk, '0)
    end
end

endmodule
