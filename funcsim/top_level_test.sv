`include "tlib.svh"

module top_level_test;

    initial begin: proc_dump_wave
`ifdef SIMVISION_DUMP
	$display("SIMVISION dump");
        $shm_open("waves.shm");     // open waveform database
        $shm_probe("AS");           // A=all signals, S=include submodules
        
        //$shm_close();
`elsif GTKW_DUMP
	$display("GTKW dump");
        $dumpfile("wave.vcd");
        $dumpvars(0);
`endif
    end

	//----------------------------------------------------------------------------
	// Signals to map inputs/outputs of the component
	//----------------------------------------------------------------------------
	logic        isop_i, ieop_i, ivalid_i, osop_i, oeop_i, ovalid_i, iready_i;
	logic [7:0]  idata_i, odata_i;

	// Control signals to signify when writer and reader are finished.
	logic writer_done = 1'b0;
	logic reader_done = 1'b0;
	logic done        = 1'b0;

	// Clock and reset signals
	logic wclk, rclk, rstb;

	//----------------------------------------------------------------------------
	// Constants
	//----------------------------------------------------------------------------
	localparam realtime WCLK_PERIOD = 10ns;
	localparam realtime RCLK_PERIOD = 8ns;

	localparam string SOURCE_FILE          = "../funcsim/text_files/source_data.txt";
	localparam string EXPECTED_OUTPUT_FILE = "../funcsim/text_files/expected_data.txt";
	localparam string ACTUAL_OUTPUT_FILE   = "../funcsim/text_files/dump_data.txt";
	localparam string SIM_RESULTS_FILE     = "../funcsim/text_files/log.txt";

	//----------------------------------------------------------------------------
	// Helper functions (replacing the VHDL TEXTIO conversion helpers)
	//----------------------------------------------------------------------------

	// Convert a single character into a 4-state logic value.
	function automatic logic char_to_logic(byte c);
		case (c)
			"0":        return 1'b0;
			"1":        return 1'b1;
			"Z", "z":   return 1'bz;
			"X", "x":   return 1'bx;
			default:    return 1'bx;
		endcase
	endfunction

	// Convert an 11-character '0'/'1'/'X'/'Z' string into an 11-bit vector.
	// First character of the string maps to the MSB (bit 10), matching the
	// VHDL to_std_logic_vector indexing.
	function automatic logic [10:0] str_to_slv(input string s);
		logic [10:0] v;
		for (int i = 0; i < 11; i++)
			v[10-i] = char_to_logic(s[i]);
		return v;
	endfunction

	// Convert an 11-bit vector into its string representation (MSB first),
	// using uppercase X/Z to match the VHDL std_logic character set.
	function automatic string slv_to_str(input logic [10:0] v);
		string s = "";
		for (int i = 10; i >= 0; i--) begin
			case (v[i])
			  1'b0: s = {s, "0"};
			  1'b1: s = {s, "1"};
			  1'bz: s = {s, "Z"};
			  default: s = {s, "X"};
			endcase
		end
		return s;
	endfunction

	// Convert a numeric value + unit string into a delay (in ns time units).
	function automatic realtime to_time(input real val, input string unit);
		case (unit)
			"fs": return val * 1.0e-6;
			"ps": return val * 1.0e-3;
			"ns": return val;
			"us": return val * 1.0e3;
			"ms": return val * 1.0e6;
			default: return val;          // assume ns if unit unrecognized
		endcase
	endfunction

	// Read one line from a file, stripping the trailing newline / CR.
	// Returns the number of characters read by $fgets (0 at EOF/error).
	function automatic int read_line(int fd, output string s);
		int code;
		code = $fgets(s, fd);
		if (code != 0)
			while (s.len() > 0 && (s[s.len()-1] == "\n" || s[s.len()-1] == 8'h0d))
				s = s.substr(0, s.len()-2);
		return code;
	endfunction

	//----------------------------------------------------------------------------
	// Instantiate the design
	//----------------------------------------------------------------------------
	Design dut (
	    // ISOP, IEOP, IVALID inputs
	    .ISOP   (isop_i),
	    .IEOP   (ieop_i),
	    .IVALID (ivalid_i),

	    // Input data
	    .IDATA  (idata_i),

	    // Clocks and resets
	    .WCLK   (wclk),
	    .RCLK   (rclk),
	    .RSTB   (rstb),

	    // Scan Signals - 3 scan chains for each clock domain
	    // .scan_in   (scan_in_i),
	    // .scan_out  (/* OPEN */),
	    // .scan_en   (scan_en_i),
	    //
	    // Scan Test Control signals to control gated resets
	    // during scan testing - in synchronizers block.
	    // .scan_mode (scan_mode_i),

	    // IREADY output
	    .IREADY (iready_i),

	    // OSOP, OEOP, OVALID outputs
	    .OSOP   (osop_i),
	    .OEOP   (oeop_i),
	    .OVALID (ovalid_i),

	    // Output data
	    .ODATA  (odata_i)
	);

	//----------------------------------------------------------------------------
	// Generate clock signals
	//----------------------------------------------------------------------------
	initial task_clock_gen(wclk, WCLK_PERIOD/2);
	initial task_clock_gen(rclk, RCLK_PERIOD/2);

	//----------------------------------------------------------------------------
	// Apply stimulus to top_level design (upstream_logic)
	//----------------------------------------------------------------------------
	initial begin : upstream_logic
		int          fd;
		string       input_line;
		string       line_id;
		string       control_vector_s;
		string       rest;
		logic [10:0] control_vector;
		byte         rstb_val_s;
		real         n1, n2;
		string       u1, u2;
		realtime     after_time, wait_time;
		static int   num_trans = 0;
		bit          restart;

		// Open the stimulus file.
		fd = $fopen(SOURCE_FILE, "r");
		if (fd == 0)
		  $fatal(1, "Could not open source file: %s", SOURCE_FILE);

		// Initially reset the system before running any tests at all.
		rstb = 1'b0;
		#(10*WCLK_PERIOD);
		rstb = 1'b1;

		// Set initial values for inputs.
		// scan_in_i   = '0;
		// scan_en_i   = 1'b0;
		// scan_mode_i = 1'b0;
		isop_i   = 1'b0;
		ieop_i   = 1'b0;
		ivalid_i = 1'b0;
		idata_i  = 8'bxxxxxxxx;

		// Wait a while for system to stabilize.
		#(5*WCLK_PERIOD);

		// Wait until iready_i = '1'.
		while (iready_i !== 1'b1)
		  #(WCLK_PERIOD);

		// Wait until falling edge of clock.
		@(negedge wclk);

		// ----- input_loop -----
		forever begin
			restart = 1'b0;

			// Read a line from the input file.
			if (read_line(fd, input_line) == 0) break;     // endfile -> stop
			line_id = (input_line.len() == 0) ? "XX" : input_line.substr(0, 1);

			// Keep reading until we get a transaction start ("ST").
			while (line_id != "ST") begin
				if (read_line(fd, input_line) == 0) begin restart = 1'b1; break; end
				line_id = (input_line.len() == 0) ? "XX" : input_line.substr(0, 1);
			end
			if (restart) continue;

			// A transaction has begun. Read next line and parse.
			if (read_line(fd, input_line) == 0) continue;
			line_id = (input_line.len() == 0) ? "XX" : input_line.substr(0, 1);

			// Loop until transaction done ("DO").
			while (line_id != "DO") begin
				if (line_id == "DA") begin
					control_vector_s = input_line.substr(5, 15);
					control_vector   = str_to_slv(control_vector_s);
					isop_i   = control_vector[10];
					ieop_i   = control_vector[9];
					ivalid_i = control_vector[8];
					idata_i  = control_vector[7:0];
					#(WCLK_PERIOD);
				end

				// Read line and parse.
				if (read_line(fd, input_line) == 0) begin restart = 1'b1; break; end
				line_id = (input_line.len() == 0) ? "XX" : input_line.substr(0, 1);
			end
			if (restart) continue;

			// Set control inputs to default values.
			isop_i   = 1'b0;
			ieop_i   = 1'b0;
			ivalid_i = 1'b0;
			idata_i  = 8'bxxxxxxxx;

			// Transaction ended. Wait 2 clock cycles.
			#(2*WCLK_PERIOD);

			// Increment transaction count.
			num_trans = num_trans + 1;

			// Wait for iready = '1'.
			while (iready_i !== 1'b1)
				#(WCLK_PERIOD);

			// Wait for a number of clock cycles equal to num_trans (chosen
			// arbitrarily) after iready = '1' before starting next transaction.
			#(num_trans*WCLK_PERIOD);
		end

		// End of file. End simulation.
		$fclose(fd);
		writer_done = 1'b1;
		#(1000*RCLK_PERIOD);
		$display("Simulation done.");
		$finish;
	end

	//----------------------------------------------------------------------------
	// Basic protocol checking (kept commented, as in the original VHDL).
	//----------------------------------------------------------------------------
	// protocol_check2:
	//   Check that IREADY deasserts within 2 clocks after start of packet.
	//   (Original VHDL block left disabled.)

	//----------------------------------------------------------------------------
	// Record system output (downstream_logic)
	// The output from the design is recorded in the actual-output file.
	//----------------------------------------------------------------------------
	int          design_fd;
	string       header = "SEVDATA";          // header at start of every packet
	logic [10:0] out_vec;

	initial begin
		design_fd = $fopen(ACTUAL_OUTPUT_FILE, "w");
		if (design_fd == 0)
			$fatal(1, "Could not open output file: %s", ACTUAL_OUTPUT_FILE);
	end

	// Packet and control signals are written to the output file on the rising
	// edge of rclk when ovalid is asserted.
	always @(posedge rclk) begin
		if (ovalid_i === 1'b1) begin
			if (osop_i === 1'b1) begin
				// Write the header (start of a new packet).
				$fdisplay(design_fd, "%s", header);
			end
			out_vec = {osop_i, oeop_i, ovalid_i, odata_i};
			$fdisplay(design_fd, "%s", slv_to_str(out_vec));
		end
	end

	//----------------------------------------------------------------------------
	// check_result
	//
	// Triggered when writer_done goes high (all stimulus applied and the
	// downstream_logic recording window has closed).
	//
	// Strategy: read the expected and actual output files line by line in
	// lock-step. A "SEVDATA" header marks the start of a new test/packet.
	// Within a packet every 11-character data line must match exactly.
	// Results (PASSED / FAILED + test number) are written to the log file.
	//
	// Differences from the original VHDL commented block:
	//   * The VHDL compared character-by-character inside a 0-to-10 loop
	//     (matching the fixed 11-char line width). Here we compare whole
	//     lines with the == string operator, which is equivalent.
	//   * The VHDL `done` signal toggled after 100000 ns; here we trigger
	//     directly on writer_done to avoid the extra timer.
	//   * $fdisplay automatically appends a newline, matching writeline.
	//----------------------------------------------------------------------------

	always @(posedge writer_done) begin : check_result
 
		int    exp_fd, act_fd, res_fd;
		string exp_line, act_line;
		static int    test_number = 0;
		static int    pass        = 1;          // 1 = passing, 0 = failing
		static string pass_msg    = "PASSED    ";
		static string fail_msg    = "FAILED    ";
 
		// Small settling window — let downstream_logic flush its last write.
		$fclose(design_fd);  // flush + close the write handle
		#(20*RCLK_PERIOD);
 
		exp_fd = $fopen(EXPECTED_OUTPUT_FILE, "r");
		act_fd = $fopen(ACTUAL_OUTPUT_FILE,   "r");
		res_fd = $fopen(SIM_RESULTS_FILE,     "w");
 
		if (exp_fd == 0) $fatal(1, "check_result: cannot open expected file: %s", EXPECTED_OUTPUT_FILE);
		if (act_fd == 0) $fatal(1, "check_result: cannot open actual file: %s",   ACTUAL_OUTPUT_FILE);
		if (res_fd == 0) $fatal(1, "check_result: cannot open results file: %s",  SIM_RESULTS_FILE);
 
		while (!$feof(exp_fd)) begin
 
			// Read one line from each file.
			if (read_line(exp_fd, exp_line) == 0) break;
			void'(read_line(act_fd, act_line));   // keep files in lock-step
 
			if (exp_line == "") continue;         // skip blank lines
 
			if (exp_line == "SEVDATA") begin
				// Start of a new packet: log result of the previous test (if any).
				if (test_number > 0) begin
					if (pass) begin
						$display("%s%0d", pass_msg, test_number);
						$fdisplay(res_fd, "%s%0d", pass_msg, test_number);
					end
					else begin
						$display("%s%0d", fail_msg, test_number);
						$fdisplay(res_fd, "%s%0d", fail_msg, test_number);
					end
				end
				test_number = test_number + 1;
				pass        = 1;                    // reset pass flag for new test
			end else begin
				// Data line: compare expected vs actual character by character
				// across all 11 bit positions.
				// $display("exp_line: %s", exp_line);
				// $display("act_line: %s", act_line);
				for (int i = 0; i < 11; i++) begin
					if (i >= exp_line.len() || i >= act_line.len() || exp_line[i] != act_line[i]) begin
						pass = 0;
					end
				end
			end
 
		end
 
		// Log the result of the final test.
		if (test_number > 0) begin
			if (pass) begin
				$display("%s%0d", pass_msg, test_number);
				$fdisplay(res_fd, "%s%0d", pass_msg, test_number);
			end
			else begin
				$display("%s%0d", fail_msg, test_number);
				$fdisplay(res_fd, "%s%0d", fail_msg, test_number);
			end
		end
 
		$fclose(exp_fd);
		$fclose(act_fd);
		$fclose(res_fd);
 
		reader_done = 1'b1;
		$display("check_result: done — results written to %s", SIM_RESULTS_FILE);
 
	end
endmodule