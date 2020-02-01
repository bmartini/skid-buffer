`ifndef _skid_register_
`define _skid_register_


`default_nettype none

module skid_register
  #(parameter
    DATA_WIDTH = 32)
   (input  wire                     clk,
    input  wire                     rst,

    input  wire [DATA_WIDTH-1:0]    up_bus,
    input  wire                     up_val,
    output reg                      up_rdy,

    output reg  [DATA_WIDTH-1:0]    dn_bus,
    output reg                      dn_val,
    input  wire                     dn_rdy
);

    reg  [DATA_WIDTH-1:0]   skid_bus;
    reg                     skid_val;

    wire                    dn_active;
    wire                    dn_val_i;
    wire [DATA_WIDTH-1:0]   dn_bus_i;


    // skid_bus always reflects downstream data's last cycle
    always @(posedge clk)
        skid_bus <= dn_bus_i;


    // skid_val remembers if there is valid data in the skid register until
    // it's consumed by the downstream
    always @(posedge clk)
        if (rst)    skid_val <= 1'b0;
        else        skid_val <= dn_val_i & ~dn_active;


    // down stream mux: if up_rdy not active, use last cycle's data and valid
    assign dn_bus_i = up_rdy ? up_bus : skid_bus;

    assign dn_val_i = up_rdy ? up_val : skid_val;


    // when down stream is active, set upstream to ready
    always @(posedge clk)
        up_rdy <= dn_active;


    always @(posedge clk)
        if      (rst)       dn_val <= 1'b0;
        else if (dn_active) dn_val <= dn_val_i;


    always @(posedge clk)
        if (dn_active) dn_bus <= dn_bus_i;


    // do not stall pipeline until it is primed
    assign dn_active = ~dn_val | dn_rdy;


endmodule

`default_nettype wire

`endif //  `ifndef _skid_register_
