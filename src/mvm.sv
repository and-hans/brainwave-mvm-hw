/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* Matrix Vector Multiplication (MVM) Module           */
/*******************************************************/

module mvm # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter MEM_DATAW = IWIDTH * 8,
    parameter VEC_MEM_DEPTH = 256,
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH = 512,
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES = 128
)(
    input clk,
    input rst,
    input [MEM_DATAW-1:0] i_vec_wdata,
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
    input i_start,
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words,
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane,
    output o_busy,
    output [OWIDTH*NUM_OLANES-1:0] o_result,
    output o_valid
);

/******* Your code starts here *******/

localparam MEM_STAGES = 2+1+2; // raddr fanout(1) + memory read(1) + vector pipeline(2)
localparam DOT_STAGES = 8;
localparam TOTAL_STAGES = MEM_STAGES + DOT_STAGES;

logic [MEM_DATAW-1:0] vec0;

logic [OWIDTH*NUM_OLANES-1:0] result;
logic ovalid[0:NUM_OLANES-1];

logic [VEC_ADDRW-1:0] vec_ra, vec_ra_reg[0:1];
logic [MAT_ADDRW-1:0] mat_ra;

logic dot_valid, valid_stage1[0:7];
logic [MEM_STAGES-2:0] valid_pipe;
logic acc_first, acc_last;
logic busy;
logic [TOTAL_STAGES-1:0] busy_pipe;

mem # (
    .DATAW(MEM_DATAW),
    .DEPTH(VEC_MEM_DEPTH)
) vector_mem (
    .clk(clk),
    .wdata(i_vec_wdata),
    .waddr(i_vec_waddr),
    .wen(i_vec_wen),
    .raddr(vec_ra_reg[1]),
    .rdata(vec0)
);

genvar i;
generate
for (i = 0; i < NUM_OLANES; i++) begin
    logic [MAT_ADDRW-1:0] mat_ra_reg[0:1];
    (* dont_touch = "true" *) logic [MEM_DATAW-1:0] vec0_reg[0:1];
    logic [MEM_DATAW-1:0] vec1, vec1_reg[0:1];
    logic [OWIDTH-1:0] res;
    logic valid;
    logic [TOTAL_STAGES-1:0] first_pipe, last_pipe;
    
    always_ff @(posedge clk) begin
        vec0_reg[0] <= vec0;
        vec0_reg[1] <= vec0_reg[0];
        
        vec1_reg[0] <= vec1;
        vec1_reg[1] <= vec1_reg[0];
        
        mat_ra_reg[0] <= mat_ra;
        mat_ra_reg[1] <= mat_ra_reg[0];
        
        first_pipe <= {first_pipe[TOTAL_STAGES-2:0], acc_first};
        last_pipe <= {last_pipe[TOTAL_STAGES-2:0], acc_last};
    end

    mem # (
        .DATAW(MEM_DATAW),
        .DEPTH(MAT_MEM_DEPTH)
    ) matrix_mem (
        .clk(clk),
        .wdata(i_mat_wdata),
        .waddr(i_mat_waddr),
        .wen(i_mat_wen[i]),
        .raddr(mat_ra_reg[1]),
        .rdata(vec1)
    );
    
    (* keep_hierarchy = "yes" *)
    dot8 # (
        .IWIDTH(IWIDTH),
        .OWIDTH(OWIDTH)
    ) dot (
        .clk(clk),
        .rst(rst),
        .vec0(vec0_reg[1]),
        .vec1(vec1_reg[1]),
        .ivalid(valid_stage1[i%8]),
        .result(res),
        .ovalid(valid)
    );
    
    accum # (
        .DATAW(OWIDTH),
        .ACCUMW(OWIDTH)
    ) acc (
        .clk(clk),
        .rst(rst),
        .data(res),
        .ivalid(valid),
        .first(first_pipe[TOTAL_STAGES-1]),
        .last(last_pipe[TOTAL_STAGES-1]),
        .result(result[OWIDTH*i +: OWIDTH]),
        .ovalid(ovalid[i])
    );
end
endgenerate

ctrl # (
    .VEC_ADDRW(VEC_ADDRW),
    .MAT_ADDRW(MAT_ADDRW)
) controller (
    .clk(clk),
    .rst(rst),
    .start(i_start),
    .vec_start_addr(i_vec_start_addr),
    .vec_num_words(i_vec_num_words),
    .mat_start_addr(i_mat_start_addr),
    .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
    .vec_raddr(vec_ra),
    .mat_raddr(mat_ra),
    .accum_first(acc_first),
    .accum_last(acc_last),
    .ovalid(dot_valid),
    .busy(busy)
);

always_ff @(posedge clk) begin
    vec_ra_reg[0] <= vec_ra;
    vec_ra_reg[1] <= vec_ra_reg[0];
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 8; i++)
            valid_stage1[i] <= 0;
        valid_pipe <= '0;
        busy_pipe <= '0;
    end else begin
        for (int i = 0; i < 8; i++)
            valid_stage1[i] <= valid_pipe[MEM_STAGES-2];
        valid_pipe <= {valid_pipe[MEM_STAGES-3:0], dot_valid};
        
        busy_pipe <= {busy_pipe[TOTAL_STAGES-2:0], busy};
    end
end

assign o_busy = busy_pipe[TOTAL_STAGES-1];
assign o_result = result;
assign o_valid = ovalid[0];

/******* Your code ends here ********/

endmodule
