`include "tlib.svh"

module Design_sim;

    initial begin: proc_dump_wave
`ifdef SIMVISION_DUMP
	$display("SIMVISION dump");
        $shm_open("waves.shm");     // open waveform database
        $shm_probe("AS");           // A=all signals, S=include submodules
        
        #900;
        $shm_close();
`elsif GTKW_DUMP
	$display("GTKW dump");
        $dumpfile("wave.vcd");
        $dumpvars(0);
        #900;
`endif
        $finish;
    end

    //initial begin: finish
    //    #1000;
    //    $finish;
    //end

    localparam WCLK_PERIOD = 10;
    localparam RCLK_PERIOD = 8;
    localparam RST_PERIOD  = 2*WCLK_PERIOD;

    logic       WCLK;
    logic       RCLK;
    logic       RSTB;

    logic       ISOP=1'b0;
    logic       IEOP=1'b0;
    logic       IVALID=1'b0;
    logic [7:0] IDATA='0;
    logic       IREADY;

    logic       OSOP;
    logic       OEOP;
    logic       OVALID;
    logic [7:0] ODATA;



    Design dut (
        .WCLK  (WCLK  ),  
        .RCLK  (RCLK  ),  
        .RSTB  (RSTB  ),  
                
        .ISOP  (ISOP  ),  
        .IEOP  (IEOP  ),  
        .IVALID(IVALID),    
        .IDATA (IDATA ),   
        .IREADY(IREADY),    
                
        .OSOP  (OSOP  ),  
        .OEOP  (OEOP  ),  
        .OVALID(OVALID),    
        .ODATA (ODATA )
    );

    initial task_clock_gen(WCLK, WCLK_PERIOD/2);
    initial task_clock_gen(RCLK, RCLK_PERIOD/2);
    initial task_resetN(RSTB, RST_PERIOD);

    initial begin
        #RST_PERIOD;
        #1;
        // Case 1: Discontinuous stream of words
        ISOP = 1'b1; IEOP = 1'b0; IVALID=1'b1; IDATA=8'hAB;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b0; IDATA=8'h00;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'hBC;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b1; IVALID=1'b1; IDATA=8'hCD;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b0; IDATA=8'h00;

        #(2*WCLK_PERIOD);
        while (!IREADY) @(posedge WCLK); #1;

        // Case 2: Continuous stream of words
        ISOP = 1'b1; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h12;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h23;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b1; IVALID=1'b1; IDATA=8'h34;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b0; IDATA=8'h00;

        #(2*WCLK_PERIOD);
        while (!IREADY) @(posedge WCLK); #1;

        // Case 3: Single packet with 1 word
        ISOP = 1'b1; IEOP = 1'b1; IVALID=1'b1; IDATA=8'h56;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b0; IDATA=8'h00;

        #(2*WCLK_PERIOD);
        while (!IREADY) @(posedge WCLK); #1;

        // Case 4: Restarting packet transfer
        ISOP = 1'b1; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h12;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h23;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h34;
        #WCLK_PERIOD;
        // Restart
        ISOP = 1'b1; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h34;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h23;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b1; IDATA=8'h12;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b1; IVALID=1'b1; IDATA=8'h01;
        #WCLK_PERIOD;
        ISOP = 1'b0; IEOP = 1'b0; IVALID=1'b0; IDATA=8'h00;
    end
    

endmodule
