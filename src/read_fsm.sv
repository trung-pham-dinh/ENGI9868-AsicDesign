`include "macro.svh"

module read_fsm #(
)(
     input  logic              clk
    ,input  logic              arstb

    ,output logic              osop
    ,output logic              oeop
    ,output logic              ovalid

    ,input  logic              rfifo_eop_ps
    ,output logic              rfifo_meb_lv
    ,output logic              rfifo_web_lv
    ,output logic              rptr_ld_ps
    ,output logic              rptr_en_lv
    ,input  logic              read_rdy_lv
);

typedef enum logic [0:0] {
    READ_EN,
    READ_LOCKED,
} rfsm_state_t;

rfsm_state_t rfsm_state, rfsm_next;
logic read_en;
logic osop_pipe, oeop_pipe, ovalid_pipe;

always_comb begin
    case (rfsm_state)
        READ_LOCKED: begin
            if (read_rdy_lv) begin
                rfsm_next = READ_EN;
            end else begin
                rfsm_next = READ_LOCKED;
            end
        end
        READ_EN: begin
            if (rfifo_eop_ps) begin
                rfsm_next = READ_LOCKED;
            end else begin
                rfsm_next = READ_EN;
            end
        end
        default: rfsm_next = READ_LOCKED;
    endcase

    read_en_lv = (rfsm_state == READ_EN);

    rptr_ld_ps   = read_en_ps;
    rptr_en_lv   = read_en_lv & ~rfifo_eop_ps;
    rfifo_web_lv = ~rptr_en_lv;
    rfifo_meb_lv = ~rptr_en_lv;
end

`PRIM_FF_ARSTB(rfsm_state , rfsm_next, arstb, clk, READ_READY)

edge_detector #(
    .EDGE_TYPE(1) // detect rising edge
) _edge_detector (
    .clk          (clk       ),
    .arstb        (arstb     ),
    .signal_in    (read_en_lv),
    .edge_detected(read_en_ps)
);


pipeline #(
    .STAGE_NUM(2),
    .DATA_W(2)
) _pipeline (
    .clk     (clk        ),
    .arstb   (arstb      ),
    .data_in ({read_en_ps, read_en_lv}),
    .data_out({osop      , ovalid})
);
`PRIM_FF_ARSTB(oeop, rfifo_eop_ps, arstb, clk, 1'b0)


endmodule