module edge_detector #(
    parameter EDGE_TYPE = 0 // 1: rising edge, 0: falling edge: 2: both edge
) (
    input  logic clk,
    input  logic arstb,
    input  logic signal_in,
    output logic edge_detected
);

logic signal_in_d;

generate
    if (EDGE_TYPE == 1) begin: rising_edge // rising edge
        assign edge_detected = signal_in & ~signal_in_d;
    end else if (EDGE_TYPE == 0) begin: falling_edge // falling edge
        assign edge_detected = ~signal_in & signal_in_d;
    end else begin: both_edge // both edge
        assign edge_detected = signal_in ^ signal_in_d;
    end
endgenerate

`PRIM_FF_ARSTB(signal_in_d, signal_in, arstb, clk, 1'b0)
    
endmodule
