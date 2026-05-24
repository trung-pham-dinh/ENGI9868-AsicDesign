`include "macro.svh"

module write_fsm #(
)(
     input  logic              clk
    ,input  logic              arstb

    ,input  logic              isop
    ,input  logic              ieop
    ,input  logic              ivalid
    ,output logic              iready

    ,output logic              wfifo_eop_ps
    ,output logic              wfifo_meb_lv
    ,output logic              wfifo_web_lv
    ,output logic              wptr_ld_ps
    ,output logic              wptr_en_lv
    ,input  logic              write_rdy_lv
);

typedef enum logic [1:0] {
    WRITE_READY,
    WRITE_EN,
    WRITE_LOCKED
} wfsm_state_t;
wfsm_state_t wfsm_state, wfsm_next;
logic write_en;
logic isop_pipe, ieop_pipe, ivalid_pipe;

always_comb begin
    case (wfsm_state)
        WRITE_READY: begin
            if (ivalid & isop) begin
                wfsm_next = WRITE_EN;
            end else begin
                wfsm_next = WRITE_READY;
            end
        end
        WRITE_EN: begin
            if (wfifo_eop_ps) begin
                wfsm_next = WRITE_LOCKED;
            end else begin
                wfsm_next = WRITE_EN;
            end
        end
        WRITE_LOCKED: begin
            if (write_rdy_lv) begin
                wfsm_next = WRITE_READY;
            end else begin
                wfsm_next = WRITE_LOCKED;
            end
        end
        default: wfsm_next = WRITE_READY;
    endcase

    write_en = (wfsm_state == WRITE_EN);

    wptr_ld_ps   = write_en & ivalid_pipe & isop_pipe;
    wfifo_eop_ps = write_en & ivalid_pipe & ieop_pipe;
    wptr_en_lv   = write_en & ivalid_pipe;
    wfifo_web_lv = ~(write_en & ivalid_pipe);
    wfifo_meb_lv = ~write_en;
end

`PRIM_FF_ARSTB(wfsm_state , wfsm_next, arstb, clk, WRITE_READY)
`PRIM_FF_ARSTB(isop_pipe  , isop     , arstb, clk, WRITE_READY)
`PRIM_FF_ARSTB(ieop_pipe  , ieop     , arstb, clk, 1'b0)
`PRIM_FF_ARSTB(ivalid_pipe, ivalid   , arstb, clk, 1'b0)

endmodule
