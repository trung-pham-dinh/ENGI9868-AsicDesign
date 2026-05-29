`include "tlib.svh"

module pointer_sim;

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

    localparam CLK_PERIOD = 10;
    localparam RST_PERIOD  = 2*CLK_PERIOD;

    localparam ADDR_W = 5;
    
    logic              clk=0;
    logic              arstb=0;
    logic              ptr_ld_ps=0;
    logic              ptr_en_lv=0;
    logic [ADDR_W-1:0] ptr_val;

    pointer #(
        .ADDR_W(ADDR_W)
    )dut(
        .clk      (clk      ), 
        .arstb    (arstb    ),   
        .ptr_ld_ps(ptr_ld_ps),       
        .ptr_en_lv(ptr_en_lv),       
        .ptr_val  (ptr_val  )     
    );

    initial task_clock_gen(clk, CLK_PERIOD/2);
    initial task_resetN(arstb, RST_PERIOD);

    initial begin
        #RST_PERIOD;
        arstb = 1'b1;
        #1;

        #(2*CLK_PERIOD);
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b1; 
        #(5*CLK_PERIOD);
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b0; 
        #(2*CLK_PERIOD);
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b1; 
        #CLK_PERIOD;
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b0; 
        #(2*CLK_PERIOD);
        ptr_ld_ps = 1'b1; ptr_en_lv = 1'b0; 
        #CLK_PERIOD;
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b0; 
        #CLK_PERIOD;
        ptr_ld_ps = 1'b1; ptr_en_lv = 1'b1; 
        #CLK_PERIOD;
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b1; 
        #CLK_PERIOD;
        ptr_ld_ps = 1'b0; ptr_en_lv = 1'b0; 

    end

endmodule
