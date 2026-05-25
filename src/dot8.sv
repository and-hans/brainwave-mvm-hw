/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* 8-Lane Dot Product Module                           */
/*******************************************************/

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

/******* Your code starts here *******/

// performs a * b
module dsp_mult # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [IWIDTH-1:0] ain,
    input signed [IWIDTH-1:0] bin,
    output logic signed [OWIDTH-1:0] pout
);
    logic signed [29:0] a_pad;
    logic signed [17:0] b_pad;
    assign a_pad = {3'b111,27'(ain)};
    assign b_pad = 18'(bin);
    logic signed [47:0] p;
    assign pout = p;
    
    DSP48E2 #(
        .USE_MULT("MULTIPLY"),
        .AREG(1), .ACASCREG(1),
        .BREG(1), .BCASCREG(1),
        .CREG(1), .DREG(1), .ADREG(1),
        .MREG(1), .PREG(1),
        .ALUMODEREG(0), .INMODEREG(0), .OPMODEREG(0),
        .CARRYINREG(0), .CARRYINSELREG(0)
    )
    DSP_mult_inst (
        .CLK(clk),
        // Data outputs: Data Ports
        .P(p),
        // Control inputs: Control Inputs/Status Bits
        .ALUMODE(4'b0000),
        .CARRYINSEL(3'b000),
        .INMODE(5'b00000),
        .OPMODE(9'b00_000_01_01),
        // Data inputs: Data Ports
        .A(a_pad),
        .B(b_pad),
        .C(48'hFFFFFFFFFFFF),
        .D(27'h7FFFFFF),
        .CARRYIN(1'b0),
        // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
        .CEA1(1'b0), .CEA2(1'b1),
        .CEB1(1'b0), .CEB2(1'b1),
        .CEC(1'b0), .CED(1'b0), .CEAD(1'b0),
        .CEM(1'b1), .CEP(1'b1),
        .CEALUMODE(1'b1), .CECTRL(1'b1), .CEINMODE(1'b1),
        .CECARRYIN(1'b1),
        .RSTA(1'b0), .RSTB(1'b0),
        .RSTC(1'b0), .RSTD(1'b0),
        .RSTM(1'b0), .RSTP(1'b0),
        .RSTALUMODE(1'b0), .RSTCTRL(1'b0), .RSTINMODE(1'b0),
        .RSTALLCARRYIN(1'b0)
    );
endmodule

localparam PIPE_DEPTH = 8;
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

/******* Your code ends here ********/

endmodule
