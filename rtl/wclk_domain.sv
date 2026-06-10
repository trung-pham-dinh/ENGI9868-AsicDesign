`include "prim.svh"

module wclk_domain (
     input  logic              WCLK
    ,input  logic              RSTB

    // Input stream interface
    ,input  logic              ISOP
    ,input  logic              IEOP
    ,input  logic              IVALID
    ,input  logic [7:0]        IDATA
    ,output logic              IREADY

    // From / to synchronizers
    ,input  logic              write_rdy_lv
    ,output logic              packet_written_ps

    // Synced reset out (to fifo + synchronizers)
    ,output logic              rstb_wsynced

    // FIFO write port
    ,output logic              WPORT_MEB
    ,output logic              WPORT_WEB
    ,output logic [4:0]        WPORT_ADDR
    ,output logic [7+1:0]      WPORT_DATA
);

//----------------------------------------------------
// Reset sync
//----------------------------------------------------
reset_synchronizer #(
    .STAGE_NUM(2)
) wrclk_reset_synchronizer (
    .clk     (WCLK        ),
    .rstb_in (RSTB        ),
    .rstb_out(rstb_wsynced)
);

//----------------------------------------------------
// Write domain logic
//----------------------------------------------------
logic isop_sampled, ieop_sampled, ivalid_sampled, iready_retime;
logic wfifo_eop_ps, wfifo_meb_lv, wfifo_web_lv, wptr_ld_ps, wptr_en_lv;
logic wfifo_eop_ps_retime;
logic [7:0] wfifo_data;

pipeline #(
    .STAGE_NUM(3),
    .DATA_W(8)
) idata_pipeline (
    .clk     (WCLK        ),
    .arstb   (rstb_wsynced),
    .data_in (IDATA       ),
    .data_out(wfifo_data  )
);

`PRIM_FF_ARSTB(isop_sampled  , ISOP         , rstb_wsynced, WCLK, 1'b0)
`PRIM_FF_ARSTB(ieop_sampled  , IEOP         , rstb_wsynced, WCLK, 1'b0)
`PRIM_FF_ARSTB(ivalid_sampled, IVALID       , rstb_wsynced, WCLK, 1'b0)
`PRIM_FF_ARSTB(IREADY        , iready_retime, rstb_wsynced, WCLK, 1'b0)

write_fsm write_fsm (
    .clk            (WCLK          ),
    .arstb          (rstb_wsynced  ),
    .isop           (isop_sampled  ),
    .ieop           (ieop_sampled  ),
    .ivalid         (ivalid_sampled),
    .iready         (iready_retime ),

    .wfifo_eop_ps   (wfifo_eop_ps  ),
    .wfifo_meb_lv   (wfifo_meb_lv  ),
    .wfifo_web_lv   (wfifo_web_lv  ),
    .wptr_ld_ps     (wptr_ld_ps    ),
    .wptr_en_lv     (wptr_en_lv    ),
    .write_rdy_lv   (write_rdy_lv  )
);

pointer #(
    .ADDR_W(5)
) write_pointer (
    .clk       (WCLK         ),
    .arstb     (rstb_wsynced ),
    .ptr_ld_ps (wptr_ld_ps   ),
    .ptr_en_lv (wptr_en_lv   ),
    .ptr_val   (WPORT_ADDR   )
);

`PRIM_FF_ARSTB(WPORT_MEB, wfifo_meb_lv, rstb_wsynced, WCLK, 1'b1)
`PRIM_FF_ARSTB(WPORT_WEB, wfifo_web_lv, rstb_wsynced, WCLK, 1'b1)
`PRIM_FF_ARSTB(wfifo_eop_ps_retime, wfifo_eop_ps, rstb_wsynced, WCLK, 1'b0)
assign WPORT_DATA = {wfifo_eop_ps_retime, wfifo_data};
assign packet_written_ps = wfifo_eop_ps;

endmodule