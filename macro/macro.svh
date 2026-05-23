`ifndef MACRO
`define MACRO

`define PRIM_FF_RST(OUT, IN, RST, CLK, RST_VAL='0)    \
    always_ff @( posedge CLK ) begin : \prim_ff_``OUT \
        if (RST) begin                                \
            OUT <= RST_VAL;                           \
        end                                           \
        else begin                                    \
            OUT <= IN;                                \
        end                                           \
    end                                                 

`define PRIM_FF_EN_RST(OUT, IN, EN, RST, CLK, RST_VAL='0) \
    always_ff @( posedge CLK ) begin : \prim_ff_``OUT     \
        if (RST) begin                                    \
            OUT <= RST_VAL;                               \
        end                                               \
        else begin                                        \
            OUT <= (EN) ? IN : OUT;                       \
        end                                               \
    end                                                 

`endif
