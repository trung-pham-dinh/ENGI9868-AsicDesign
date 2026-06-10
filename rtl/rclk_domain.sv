`include "prim.svh"

module rdclk_domain (
     input  logic              RCLK
    ,input  logic              RSTB

    // Output stream interface
    ,output logic              OSOP
    ,output logic              OEOP
    ,output logic              OVALID
    ,output logic [7:0]        ODATA

    // From / to synchronizers
    ,input  logic              read_rdy_lv
    ,output logic              packet_read_ps

    // Synced reset out (to synchronizers)
    ,output logic              rstb_rsynced

    // FIFO read port
    ,output logic              RPORT_MEB
    ,output logic              RPORT_REB
    ,output logic [4:0]        RPORT_ADDR
    ,input  logic [7+1:0]      RPORT_DATA
);

//----------------------------------------------------
// Reset sync
//----------------------------------------------------
reset_synchronizer #(
    .STAGE_NUM(2)
) rdclk_reset_synchronizer (
    .clk     (RCLK        ),
    .rstb_in (RSTB        ),
    .rstb_out(rstb_rsynced)
);

//----------------------------------------------------
// Read domain logic
//----------------------------------------------------
logic osop_retime;
logic oeop_retime;
logic ovalid_retime;

logic rfifo_eop_ps;
logic rfifo_meb_lv;
logic rfifo_reb_lv;
logic rptr_ld_ps;
logic rptr_en_lv;

pipeline #(
    .STAGE_NUM(2),
    .DATA_W(8)
) odata_pipeline (
    .clk     (RCLK           ),
    .arstb   (rstb_rsynced   ),
    .data_in (RPORT_DATA[7:0]),
    .data_out(ODATA          )
);

read_fsm read_fsm (
    .clk            (RCLK          ),
    .arstb          (rstb_rsynced  ),
    .read_rdy_lv    (read_rdy_lv   ),

    .osop           (osop_retime   ),
    .oeop           (oeop_retime   ),
    .ovalid         (ovalid_retime ),

    .rfifo_eop_ps   (rfifo_eop_ps  ),
    .rfifo_meb_lv   (rfifo_meb_lv  ),
    .rfifo_reb_lv   (rfifo_reb_lv  ),
    .rptr_ld_ps     (rptr_ld_ps    ),
    .rptr_en_lv     (rptr_en_lv    )
);

assign packet_read_ps = RPORT_DATA[8];
`PRIM_FF_ARSTB(rfifo_eop_ps, RPORT_DATA[8], rstb_rsynced, RCLK, 1'b0)
`PRIM_FF_ARSTB(RPORT_MEB   , rfifo_meb_lv , rstb_rsynced, RCLK, 1'b1)
`PRIM_FF_ARSTB(RPORT_REB   , rfifo_reb_lv , rstb_rsynced, RCLK, 1'b1)

pointer #(
    .ADDR_W(5)
) read_pointer (
    .clk       (RCLK        ),
    .arstb     (rstb_rsynced),
    .ptr_ld_ps (rptr_ld_ps  ),
    .ptr_en_lv (rptr_en_lv  ),
    .ptr_val   (RPORT_ADDR  )
);

`PRIM_FF_ARSTB(OSOP  , osop_retime  , rstb_rsynced, RCLK, 1'b0)
`PRIM_FF_ARSTB(OEOP  , oeop_retime  , rstb_rsynced, RCLK, 1'b0)
`PRIM_FF_ARSTB(OVALID, ovalid_retime, rstb_rsynced, RCLK, 1'b0)

endmodule