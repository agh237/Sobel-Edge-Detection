
module edgedetect_top #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540
) (
    input  logic        clock,
    input  logic        reset,
    output logic        full,
    input  logic        wr_en,
    input  logic [23:0] din,
    output logic        empty,
    input  logic        rd_en,
    output logic [7:0]  dout
);

logic [23:0] dout_o;
logic [7:0] dout_g;

logic  [7:0] din_g;
logic  [7:0] din_s;

logic        empty_o;
logic        empty_g;

logic        rd_en_o;
logic        rd_en_g;


logic        full_g;
logic        full_s;

logic        wr_en_g;
logic        wr_en_s;


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(24)
) fifo_o_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en),
    .din(din),
    .full(full),
    .rd_clk(clock),
    .rd_en(rd_en_o),
    .dout(dout_o),
    .empty(empty_o)
);

grayscale #(
) grayscale_inst (
    .clock(clock),
    .reset(reset),
    .in_dout(dout_o),
    .in_rd_en(rd_en_o),
    .in_empty(empty_o),
    .out_din(din_g),
    .out_full(full_g),
    .out_wr_en(wr_en_g)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(8)
) fifo_g_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_g),
    .din(din_g),
    .full(full_g),
    .rd_clk(clock),
    .rd_en(rd_en_g),
    .dout(dout_g),
    .empty(empty_g)
);

sobel #(
) sobel_inst (
    .clock(clock),
    .reset(reset),
    .in_dout(dout_g),
    .in_rd_en(rd_en_g),
    .in_empty(empty_g),
    .out_din(din_s),
    .out_full(full_s),
    .out_wr_en(wr_en_s)
);


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(8)
) fifo_s_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en_s),
    .din(din_s),
    .full(full_s),
    .rd_clk(clock),
    .rd_en(rd_en),
    .dout(dout),
    .empty(empty)
);


endmodule
