module sobel #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540       
)(
    input  logic        clock,
    input  logic        reset,
    output logic        in_rd_en,
    input  logic        in_empty,
    input  logic [7:0]  in_dout,
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [7:0]  out_din
);

localparam WH_BUFF = (WIDTH * 2) +3; 
localparam WIDTH_bit = $clog2(WIDTH);
localparam HEIGHT_bit = $clog2(HEIGHT);

typedef enum logic [1:0] {s0, s1, s2, s3} state_types;
state_types state, state_c;

localparam logic [0:2][0:2][7:0] horizion_mat= '{{8'hFF,8'h00,8'h01},{8'hFE,8'h00,8'h02},{8'hFF,8'h00,8'h01}};
localparam logic [0:2][0:2][7:0] vertical_mat= '{{8'hFF,8'hFE,8'hFF},{8'h00,8'h00,8'h00},{8'h01,8'h02,8'h01}};
logic [0:WH_BUFF-1] [7:0] shift_rg, shift_rg_c;
logic [0:2][0:2][0:7] data;
logic [WIDTH_bit-1:0] x, x_c;
logic [HEIGHT_bit-1:0] y, y_c;
logic [15:0]horizion_gradient, vertical_gradient,grad_vh;
logic [7:0] grad, grad_c;

function [15:0] abs (input logic [15:0] value);
 abs= (value[15]==1'b1) ? -value:value;
endfunction

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= s0;
        x <= '0;
        y <= '0;
        shift_rg <= {WH_BUFF{8'b0}};
    end else begin
        state <= state_c;
        x <= x_c;
        y <= y_c;
        shift_rg <= shift_rg_c;
    end
end

always_comb begin
    in_rd_en  = 1'b0;
    out_wr_en = 1'b0;
    out_din   = 8'b0;
    state_c   = state;
    shift_rg_c = shift_rg;
    x_c = x;
    y_c= y;

for (int i=0; i<3; i ++) begin 
    for (int j =0; j<3;j++) begin
        data[i][j] = shift_rg [(2-i) *WIDTH+(2-j)];
    end
end

grad = 8'h00;
vertical_gradient = 16'sh0000;
horizion_gradient = 16'sh0000;

if (x!=0 && x!= WIDTH-1 && y!=0 && y!= HEIGHT-1) begin
    for (int i=0;i<3;i=i+1) begin
      for (int j=0; j<3 ; j=j+1)begin
      horizion_gradient=$signed(horizion_gradient) + $signed(16'($unsigned(data[i][j]))  * 16'($signed(horizion_mat[j][i])));
      vertical_gradient=$signed(vertical_gradient) + $signed(16'($unsigned(data[i][j]))  * 16'($signed(vertical_mat[j][i])));
      end
    end
    grad_vh=$signed(abs(horizion_gradient)+abs(vertical_gradient)) /2;
    grad= ($unsigned(grad_vh)>255) ? 8'hFF : grad_vh[7:0]; 
end
    case (state)
        
        s0: begin
            x_c=0;
            y_c=0;
            state_c=s1;
        end

        s1: begin
            if (in_empty == 1'b0) begin
                shift_rg_c[1:WH_BUFF-1] = shift_rg [0 : WH_BUFF-2];
                shift_rg_c[0]=in_dout;
                in_rd_en = 1'b1;
                x_c = $unsigned(x) +1 ;
                if (x==WIDTH-1)begin
                    x_c = '0;
                    y_c = $unsigned(y) +1;
                end
                if ((y*WIDTH +x) == WIDTH +1) begin
                    x_c = $unsigned (x) -1;
                    y_c = $unsigned (y) -1;
                    state_c = s2;
                end
            end
        end

        s2 : begin
            if (in_empty == 1'b0 && out_full == 1'b0) begin
                shift_rg_c [1:WH_BUFF -1] = shift_rg[0:WH_BUFF-2];
                shift_rg_c[0]=in_dout;
                in_rd_en = 1'b1;
                x_c = $unsigned(x) +1;
                if (x==WIDTH-1)begin
                    x_c = '0;
                    y_c = $unsigned(y) +1;
                end
                out_din=grad;
                out_wr_en =1'b1;
                state_c=(y==HEIGHT -2 && x== WIDTH-3) ? s3 :s2;

            end
        end

        s3 : begin
            if (out_full == 1'b0) begin
                x_c = $unsigned(x) +1;
                if (x==WIDTH-1)begin
                    x_c = '0;
                    y_c = $unsigned(y) +1;
                end
                out_din = grad;
                out_wr_en =1'b1;
                if (x== WIDTH-1 && y== HEIGHT -1) begin
                    state_c =s0;
                end
            end
        end
        
        default: begin
            x_c ='X;
            y_c = 'X;
            state_c = s0;
        end

    endcase
end

endmodule