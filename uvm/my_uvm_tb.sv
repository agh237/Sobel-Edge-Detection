
import uvm_pkg::*;
import my_uvm_package::*;

`include "my_uvm_if.sv"

`timescale 1 ns / 1 ns

module my_uvm_tb;

    my_uvm_if vif();

    edgedetect_top #(
        .WIDTH(IMG_WIDTH),
        .HEIGHT(IMG_HEIGHT)
    ) edgedetect_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .full(vif.in_full),
        .wr_en(vif.in_wr_en),
        .din(vif.in_din),
        .empty(vif.out_empty),
        .rd_en(vif.out_rd_en),
        .dout(vif.out_dout)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual my_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("my_uvm_test");        
    end

    // reset
    initial begin
        vif.clock <= 1'b1;
        vif.reset <= 1'b0;
        @(posedge vif.clock);
        vif.reset <= 1'b1;
        @(posedge vif.clock);
        vif.reset <= 1'b0;
    end

    // 10ns clock
    always
        #(CLOCK_PERIOD/2) vif.clock = ~vif.clock;
endmodule






