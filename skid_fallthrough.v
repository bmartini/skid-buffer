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



`ifdef FORMAL

    initial begin
        // ensure reset is triggered at the start
        assume(rst == 1);
    end


    //
    // Check the proper relationship between interface bus signals
    //


    // fifo holds data steady when not popping (not true for all fifos)
    always @(posedge clk)
        if ( ~rst && $past(fifo_val && ~fifo_pop)) begin
            assume($stable(fifo_data));
        end


    // fifo empty will not rise unless data has been popped
    always @(posedge clk)
        if ( ~rst && $past( ~rst) && $rose(fifo_empty)) begin
            assume($past(fifo_pop));
        end


    // dn stream path holds data steady when stalled
    always @(posedge clk)
        if ( ~rst && $past(dn_val && ~dn_rdy)) begin
            assert($stable(dn_bus));
        end


    // dn stream path will only release data after a transaction
    always @(posedge clk)
        if ( ~rst && $past( ~rst) && $fell(dn_val)) begin
            assert($past(dn_rdy));
        end


    //
    // Check that the down data is sourced from correct locations
    //

    // dn stream data sourced from up stream data
    always @(posedge clk)
        if ( ~rst && $past(dn_val && dn_rdy && fifo_pop)) begin
            assert(dn_bus == $past(fifo_data));
        end


    // dn stream data sourced from skid register
    always @(posedge clk)
        if ( ~rst && $past(dn_val && dn_rdy && ~fifo_pop)) begin
            assert(dn_bus == $past(skid_data));
        end


    //
    // Check that the valid fifo data is always stored somewhere
    //

    // valid fifo data is passed to dn register when dn is not stalled
    always @(posedge clk)
        if ( ~rst && $past( ~rst && fifo_val && fifo_pop && ~dn_val)) begin
            assert(($past(fifo_data) == dn_bus) && dn_val);
        end


    // valid fifo data is passed to skid register when dn is stalled
    always @(posedge clk)
        if ( ~rst && $past( ~rst && fifo_val && fifo_pop && dn_val && ~dn_rdy)) begin
            assert(($past(fifo_data) == skid_data) && dn_val);
        end


    //
    // Check that the skid register does not drop data
    //

    // skid register held steady when back pressure is being applied to fifo
    always @(posedge clk)
        if ( ~rst && $past( ~fifo_pop)) begin
            assert($stable(skid_data));
        end


    // skid register holds last up stream value when back pressure is applied to fifo
    always @(posedge clk)
        if ( ~rst && $fell(fifo_pop)) begin
            assert(skid_data == $past(fifo_data));
        end


`endif
endmodule

`default_nettype wire

`endif //  `ifndef _skid_fallthrough_
