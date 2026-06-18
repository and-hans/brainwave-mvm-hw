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
    // 4-stage pipelined multiplier
    logic signed [IWIDTH-1:0] a_reg, b_reg;
    logic signed [2*IWIDTH-1:0] m_reg;
    logic signed [OWIDTH-1:0] p_reg1;
    logic signed [OWIDTH-1:0] p_reg2;

    always_ff @(posedge clk) begin
        if (rst) begin
            a_reg  <= '0;
            b_reg  <= '0;
            m_reg  <= '0;
            p_reg1 <= '0;
            p_reg2 <= '0;
        end else begin
            // stage 1: input registers
            a_reg <= ain;
            b_reg <= bin;

            // stage 2: multiplier register
            m_reg <= a_reg * b_reg;

            // stage 3: first output register
            p_reg1 <= OWIDTH'(m_reg);
            
            // stage 4: second output register
            p_reg2 <= p_reg1;
        end
    end

    assign pout = p_reg2;

endmodule