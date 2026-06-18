`include "dsp_mult.sv"

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

localparam PIPE_DEPTH = 9;
logic signed [IWIDTH-1:0] a[0:7], b[0:7];
logic signed [OWIDTH-1:0] r1[0:7], r2[0:3], r3[0:1], r4;
logic [PIPE_DEPTH-1:0] valid;

logic signed [OWIDTH-1:0] t[0:7];

genvar i;
generate
for (i = 0; i < 8; i++) begin: layer1
    dsp_mult # (
        .IWIDTH(IWIDTH), .OWIDTH(OWIDTH)
    ) mult_inst (
        .clk(clk), .rst(rst),
        .ain(a[i]), .bin(b[i]), .pout(t[i])
    );
end
endgenerate

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 8; i++) begin
            a[i] <= '0;
            b[i] <= '0;
            r1[i] <= '0;
        end
        for (int i = 0; i < 4; i++)
            r2[i] <= '0;
        for (int i = 0; i < 2; i++)
            r3[i] <= '0;
        r4 <= '0;
        valid <= 0;
    end else begin
        for (int i = 0; i < 8; i++) begin
            a[i] <= vec0[IWIDTH*i +: IWIDTH];
            b[i] <= vec1[IWIDTH*i +: IWIDTH];
            r1[i] <= t[i];
        end
        for (int i = 0; i < 4; i++)
            r2[i] <= r1[2*i] + r1[2*i+1];
        for (int i = 0; i < 2; i++)
            r3[i] <= r2[2*i] + r2[2*i+1];
        r4 <= r3[0] + r3[1];
        valid <= {valid[PIPE_DEPTH-2:0], ivalid};
    end
end

assign result = r4;
assign ovalid = valid[PIPE_DEPTH-1];

endmodule
