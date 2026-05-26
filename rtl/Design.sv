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
    .clk     (WCLK      ),
    .arstb   (RSTB      ),
    .data_in (IDATA     ),
    .data_out(wfifo_data)
);

`PRIM_FF_ARSTB(isop_sampled  , ISOP         , RSTB, WCLK, 1'b0)
`PRIM_FF_ARSTB(ieop_sampled  , IEOP         , RSTB, WCLK, 1'b0)
`PRIM_FF_ARSTB(ivalid_sampled, IVALID       , RSTB, WCLK, 1'b0)
`PRIM_FF_ARSTB(IREADY        , iready_retime, RSTB, WCLK, 1'b0)

write_fsm write_fsm (
    .clk            (WCLK          ),
    .arstb          (RSTB          ),
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
    .arstb     (RSTB         ), 
    .ptr_ld_ps (wptr_ld_ps   ), 
    .ptr_en_lv (wptr_en_lv   ), 
    .ptr_val   (WPORT_ADDR) 
);

`PRIM_FF_ARSTB(WPORT_MEB, wfifo_meb_lv, RSTB, WCLK, 1'b1)
`PRIM_FF_ARSTB(WPORT_WEB, wfifo_web_lv, RSTB, WCLK, 1'b1)
`PRIM_FF_ARSTB(wfifo_eop_ps_retime, wfifo_eop_ps, RSTB, WCLK, 1'b0)
assign WPORT_DATA = {wfifo_eop_ps_retime, wfifo_data};
assign packet_written_ps = wfifo_eop_ps;

//----------------------------------------------------
// Domain crossing
//----------------------------------------------------


fifo #(
    .DATA_W(8+1),
    .ADDR_W(5)
) fifo (
    .wclk       (WCLK       ), 
    .rclk       (RCLK       ), 
    .arstb      (RSTB       ),  

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
    .arstb            (RSTB),  

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
    .arstb   (RSTB           ),
    .data_in (RPORT_DATA[7:0]),
    .data_out(ODATA          )
);

read_fsm read_fsm (
    .clk            (RCLK          ),
    .arstb          (RSTB          ),
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
`PRIM_FF_ARSTB(rfifo_eop_ps, RPORT_DATA[8], RSTB, RCLK, 1'b0)
`PRIM_FF_ARSTB(RPORT_MEB   , rfifo_meb_lv , RSTB, RCLK, 1'b1)
`PRIM_FF_ARSTB(RPORT_REB   , rfifo_reb_lv , RSTB, RCLK, 1'b1)

pointer #(
    .ADDR_W(5)
) read_pointer (
    .clk       (RCLK      ), 
    .arstb     (RSTB      ), 
    .ptr_ld_ps (rptr_ld_ps), 
    .ptr_en_lv (rptr_en_lv), 
    .ptr_val   (RPORT_ADDR) 
);

`PRIM_FF_ARSTB(OSOP  , osop_retime  , RSTB, RCLK, 1'b0)
`PRIM_FF_ARSTB(OEOP  , oeop_retime  , RSTB, RCLK, 1'b0)
`PRIM_FF_ARSTB(OVALID, ovalid_retime, RSTB, RCLK, 1'b0)

endmodule
