module accum # (
    parameter DATAW = 32,
    parameter ACCUMW = 32
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data,
    input  ivalid,
    input  first,
    input  last,
    output signed [ACCUMW-1:0] result,
    output ovalid
);

logic valid;
logic signed [ACCUMW-1:0] res;

always_ff @(posedge clk) begin
    if (rst) begin
        res <= 0;
        valid <= 0;
    end else begin
        if (ivalid) begin
            res <= (first) ? data : res+data;
            valid <= last;
        end else begin
          valid <= 0;
        end
    end
end

assign ovalid = valid;
assign result = res;

endmodule