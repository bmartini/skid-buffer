`ifndef _skid_fallthrough_
`define _skid_fallthrough_


`default_nettype none

module skid_fallthrough
  #(parameter
    DATA_WIDTH = 32)
   (input  wire                     clk,
    input  wire                     rst,

    input  wire [DATA_WIDTH-1:0]    fifo_data,
    input  wire                     fifo_empty,
    output reg                      fifo_pop,

    output reg  [DATA_WIDTH-1:0]    dn_bus,
    output reg                      dn_val,
    input  wire                     dn_rdy
);

    reg                     fifo_val;

    reg  [DATA_WIDTH-1:0]   skid_data;
    reg                     skid_val;

    wire                    dn_active;
    wire                    dn_val_i;
    wire [DATA_WIDTH-1:0]   dn_bus_i;


    // stallable fifo valid flag
    always @(posedge clk)
        if      (rst)       fifo_val <= 1'b0;
        else if (fifo_pop)  fifo_val <= ~fifo_empty;


    // skid_data always reflects downstream data's last cycle
    always @(posedge clk)
        skid_data <= dn_bus_i;


    // skid_val remembers if there is valid data in the skid register until
    // it's consumed by the downstream
    always @(posedge clk)
        if (rst)    skid_val <= 1'b0;
        else        skid_val <= dn_val_i & ~dn_active;


    // down stream mux: when fifo_pop is not active, use last cycle's data and valid
    assign dn_bus_i = fifo_pop ? fifo_data  : skid_data;

    assign dn_val_i = fifo_pop ? fifo_val   : skid_val;


    // when down stream is active, pop upstream fifo
    always @(posedge clk)
        fifo_pop <= dn_active;


    always @(posedge clk)
        if      (rst)       dn_val <= 1'b0;
        else if (dn_active) dn_val <= dn_val_i;


    always @(posedge clk)
        if (dn_active) dn_bus <= dn_bus_i;


    // do not stall pipeline until it is primed
    assign dn_active = ~dn_val | dn_rdy;


endmodule

`default_nettype wire

`endif //  `ifndef _skid_fallthrough_
