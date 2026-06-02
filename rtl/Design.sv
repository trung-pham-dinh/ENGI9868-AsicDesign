`include "prim.svh"

module Design (
     input  logic              WCLK
    ,input  logic              RCLK
    ,input  logic              RSTB

    ,input  logic              ISOP
    ,input  logic              IEOP
    ,input  logic              IVALID
    ,input  logic [7:0]        IDATA
    ,output logic              IREADY

    ,output logic              OSOP
    ,output logic              OEOP
    ,output logic              OVALID
    ,output logic [7:0]        ODATA
);

//----------------------------------------------------
// Crossing-domain signals
//----------------------------------------------------
logic WPORT_MEB, WPORT_WEB, packet_written_ps;
logic [4:0]   WPORT_ADDR;
logic [7+1:0] WPORT_DATA;
logic write_rdy_lv;


logic RPORT_MEB, RPORT_REB, packet_read_ps;
logic [4:0]   RPORT_ADDR;
logic [7+1:0] RPORT_DATA;
logic read_rdy_lv;

//----------------------------------------------------
// Reset sync
//----------------------------------------------------
logic rstb_wsynced, rstb_rsynced;

reset_synchronizer #(
    .STAGE_NUM(2)
) wrclk_reset_synchronizer (
    .clk     (WCLK        ), 
    .rstb_in (RSTB        ),     
    .rstb_out(rstb_wsynced)      
);

reset_synchronizer #(
    .STAGE_NUM(2)
) rdclk_reset_synchronizer (
    .clk     (RCLK        ), 
    .rstb_in (RSTB        ),     
    .rstb_out(rstb_rsynced)      
);
//----------------------------------------------------
// Write domain
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
    .ptr_val   (WPORT_ADDR) 
);

`PRIM_FF_ARSTB(WPORT_MEB, wfifo_meb_lv, rstb_wsynced, WCLK, 1'b1)
`PRIM_FF_ARSTB(WPORT_WEB, wfifo_web_lv, rstb_wsynced, WCLK, 1'b1)
`PRIM_FF_ARSTB(wfifo_eop_ps_retime, wfifo_eop_ps, rstb_wsynced, WCLK, 1'b0)
assign WPORT_DATA = {wfifo_eop_ps_retime, wfifo_data};
assign packet_written_ps = wfifo_eop_ps;

//----------------------------------------------------
// Domain crossing
//----------------------------------------------------


fifo #(
    .DATA_W(8+1),
    .ADDR_W(5)
) fifo (
    .wclk       (WCLK        ), 
    .rclk       (RCLK        ), 
    .arstb      (rstb_wsynced),  

    .WPORT_DATA (WPORT_DATA),       
    .WPORT_MEB  (WPORT_MEB ),      
    .WPORT_WEB  (WPORT_WEB ),      
    .WPORT_ADDR (WPORT_ADDR),       

    .RPORT_DATA (RPORT_DATA),       
    .RPORT_MEB  (RPORT_MEB ),      
    .RPORT_REB  (RPORT_REB ),      
    .RPORT_ADDR (RPORT_ADDR)       
);

synchronizers synchronizers (
    .wclk             (WCLK), 
    .rclk             (RCLK), 
    .arstb_wclk       (rstb_wsynced),  
    .arstb_rclk       (rstb_rsynced),  

    .packet_written_ps(packet_written_ps),              
    .packet_read_ps   (packet_read_ps   ),           
    .write_rdy_lv     (write_rdy_lv     ),         
    .read_rdy_lv      (read_rdy_lv      )
);

//----------------------------------------------------
// Read domain
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
