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
// Write side
logic         rstb_wsynced;
logic         WPORT_MEB, WPORT_WEB;
logic [4:0]   WPORT_ADDR;
logic [7+1:0] WPORT_DATA;
logic         packet_written_ps;
logic         write_rdy_lv;

// Read side
logic         rstb_rsynced;
logic         RPORT_MEB, RPORT_REB;
logic [4:0]   RPORT_ADDR;
logic [7+1:0] RPORT_DATA;
logic         packet_read_ps;
logic         read_rdy_lv;

//----------------------------------------------------
// Write domain
//----------------------------------------------------
wclk_domain wclk_domain (
    .WCLK             (WCLK             ),
    .RSTB             (RSTB             ),

    .ISOP             (ISOP             ),
    .IEOP             (IEOP             ),
    .IVALID           (IVALID           ),
    .IDATA            (IDATA            ),
    .IREADY           (IREADY           ),

    .write_rdy_lv     (write_rdy_lv     ),
    .packet_written_ps(packet_written_ps),

    .rstb_wsynced     (rstb_wsynced     ),

    .WPORT_MEB        (WPORT_MEB        ),
    .WPORT_WEB        (WPORT_WEB        ),
    .WPORT_ADDR       (WPORT_ADDR       ),
    .WPORT_DATA       (WPORT_DATA       )
);

//----------------------------------------------------
// Read domain
//----------------------------------------------------
rdclk_domain rdclk_domain (
    .RCLK             (RCLK             ),
    .RSTB             (RSTB             ),

    .OSOP             (OSOP             ),
    .OEOP             (OEOP             ),
    .OVALID           (OVALID           ),
    .ODATA            (ODATA            ),

    .read_rdy_lv      (read_rdy_lv      ),
    .packet_read_ps   (packet_read_ps   ),

    .rstb_rsynced     (rstb_rsynced     ),

    .RPORT_MEB        (RPORT_MEB        ),
    .RPORT_REB        (RPORT_REB        ),
    .RPORT_ADDR       (RPORT_ADDR       ),
    .RPORT_DATA       (RPORT_DATA       )
);

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

    .WPORT_DATA (WPORT_DATA  ),
    .WPORT_MEB  (WPORT_MEB   ),
    .WPORT_WEB  (WPORT_WEB   ),
    .WPORT_ADDR (WPORT_ADDR  ),

    .RPORT_DATA (RPORT_DATA  ),
    .RPORT_MEB  (RPORT_MEB   ),
    .RPORT_REB  (RPORT_REB   ),
    .RPORT_ADDR (RPORT_ADDR  )
);

synchronizers synchronizers (
    .wclk             (WCLK             ),
    .rclk             (RCLK             ),
    .arstb_wclk       (rstb_wsynced     ),
    .arstb_rclk       (rstb_rsynced     ),

    .packet_written_ps(packet_written_ps),
    .packet_read_ps   (packet_read_ps   ),
    .write_rdy_lv     (write_rdy_lv     ),
    .read_rdy_lv      (read_rdy_lv      )
);

endmodule