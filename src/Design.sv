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
// Write domain
//----------------------------------------------------
logic isop_sampled, ieop_sampled, ivalid_sampled, iready_retime;
logic [7:0] wfifo_data;

pipeline #(
    .STAGE_NUM(2),
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

pointer write_pointer (
    .clk       (WCLK            ), 
    .arstb     (RSTB            ), 
    .ptr_ld_ps (wptr_ld_ps      ), 
    .ptr_en_lv (wptr_en_lv      ), 
    .ptr_val   (write_pointer_lv) 
);

//----------------------------------------------------
// FIFO
//----------------------------------------------------

//----------------------------------------------------
// Read domain
//----------------------------------------------------

endmodule