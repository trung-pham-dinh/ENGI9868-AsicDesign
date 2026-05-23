module synchronizers #(
)(
     input  logic              wclk
    ,input  logic              rclk
    ,input  logic              arstb

    ,input  logic              packet_written_ps
    ,input  logic              packet_read_ps
    ,output logic              write_rdy_lv
    ,output logic              read_rdy_lv
);

// Write domain signals
logic packet_written_lv, packet_written_lv_next;
// Read domain signals
logic packet_read_lv, packet_read_lv_next;

//----------------------
// Write domain
//----------------------

always_comb begin
    packet_written_lv_next = (packet_written_ps) ? ~packet_written_lv : packet_written_lv;
end
`PRIM_FF_ARSTB(packet_written_lv, packet_written_lv_next, arstb, wclk, 1'b0)

pipeline r2w_synchronizer #(
    .WIDTH(1)
) r2w_sync (
    .clk     (wclk               ),
    .arstb   (arstb              ),
    .data_in (packet_read_lv     ),
    .data_out(packet_read_lv_sync)
);

edge_detector #(
    .EDGE_TYPE(2) // detect rising edge
) r2w_edge_detector (
    .clk        (wclk               ),
    .arstb      (arstb              ),
    .signal_in  (packet_read_lv_sync),
    .signal_out (packet_read_ps_sync)
);

`PRIM_FF_ARSTB(write_rdy_lv, write_rdy_lv_next, arstb, wclk, 1'b0)

always_comb begin
    if (~write_rdy_lv & packet_read_ps_sync) begin
        write_rdy_lv_next = 1'b1;
    end
    else if (write_rdy_lv & packet_read_ps) begin
        write_rdy_lv_next = 1'b0;
    end 
    else begin
        write_rdy_lv_next = write_rdy_lv;
    end
end

//----------------------
// Read domain
//----------------------

always_comb begin
    packet_read_lv_next = (packet_read_ps) ? ~packet_read_lv : packet_read_lv;
end
`PRIM_FF_ARSTB(packet_read_lv, packet_read_lv_next, arstb, rclk, 1'b0)

pipeline w2r_synchronizer #(
    .WIDTH(1)
) w2r_sync (
    .clk     (rclk                  ),
    .arstb   (arstb                 ),
    .data_in (packet_written_lv     ),
    .data_out(packet_written_lv_sync)
);

edge_detector #(
    .EDGE_TYPE(2) // detect rising edge
) w2r_edge_detector (
    .clk        (rclk                  ),
    .arstb      (arstb                 ),
    .signal_in  (packet_written_lv_sync),
    .signal_out (packet_written_ps_sync)
);

`PRIM_FF_ARSTB(read_rdy_lv, read_rdy_lv_next, arstb, rclk, 1'b0)

always_comb begin
    if (~read_rdy_lv & packet_written_ps_sync) begin
        read_rdy_lv_next = 1'b1;
    end
    else if (read_rdy_lv & packet_read_ps) begin
        read_rdy_lv_next = 1'b0;
    end 
    else begin
        read_rdy_lv_next = read_rdy_lv;
    end
end

endmodule