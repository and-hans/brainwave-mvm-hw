module ctrl # (
    parameter VEC_ADDRW = 8,
    parameter MAT_ADDRW = 9,
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
    
)(
    input  clk,
    input  rst,
    input  start,
    input  [VEC_ADDRW-1:0] vec_start_addr,
    input  [VEC_SIZEW-1:0] vec_num_words,
    input  [MAT_ADDRW-1:0] mat_start_addr,
    input  [MAT_SIZEW-1:0] mat_num_rows_per_olane,
    output [VEC_ADDRW-1:0] vec_raddr,
    output [MAT_ADDRW-1:0] mat_raddr,
    output accum_first,
    output accum_last,
    output ovalid,
    output busy
);

// input registers
// note: rvec_words and rmat_rows are stored as the actual value-1, to save computation
logic [VEC_ADDRW-1:0] rvec_start, rvec_start_val;
logic [VEC_SIZEW-1:0] rvec_words, rvec_words_val;
logic [MAT_ADDRW-1:0] rmat_start, rmat_start_val;
logic [MAT_SIZEW-1:0] rmat_rows, rmat_rows_val;

// output registers and wires
logic rfirst, rlast, rbusy;
logic rvalid;
logic rfirst_val, rlast_val, rvalid_val, rbusy_val;
logic [VEC_ADDRW-1:0] vec_ra, vec_ra_val;
logic [MAT_ADDRW-1:0] mat_ra, mat_ra_val;

// states and fsm logic
enum {IDLE, COMPUTE} state, next_state;
logic [VEC_SIZEW-1:0] vcnt, vcnt_val; // vector raddr counter
logic [MAT_SIZEW-1:0] rcnt, rcnt_val; // row counter

always_ff @(posedge clk) begin
    if (rst) begin
        // inputs
        rvec_start <= '0; rvec_words <= '0;
        rmat_start <= '0; rmat_rows <= '0;
        // outputs
        rfirst <= 0; rlast <= 0; rbusy <= 0;
        rvalid <= 0;
        vec_ra <= '0; mat_ra <= '0;
        // states
        state <= IDLE;
        vcnt <= '0; rcnt <= '0;
    end else begin
        // inputs
        rvec_start <= rvec_start_val;
        rvec_words <= rvec_words_val;
        rmat_start <= rmat_start_val;
        rmat_rows <= rmat_rows_val;
        // outputs
        rfirst <= rfirst_val;
        rlast <= rlast_val;
        rbusy <= rbusy_val;
        rvalid <= rvalid_val;
        vec_ra <= vec_ra_val;
        mat_ra <= mat_ra_val;
        // states
        state <= next_state;
        vcnt <= vcnt_val;
        rcnt <= rcnt_val;
    end
end

always_comb begin: state_decoder
    case (state)
        IDLE: next_state = (start) ? COMPUTE : IDLE;
        COMPUTE: begin
            next_state = (rcnt == rmat_rows && vcnt == rvec_words) ? IDLE : COMPUTE;
        end
        default: next_state = IDLE;
    endcase
end

always_comb begin: output_decoder
    case (state)
        IDLE: begin
            rvec_start_val = vec_start_addr;
            rvec_words_val = vec_num_words-1;
            rmat_start_val = mat_start_addr;
            rmat_rows_val = mat_num_rows_per_olane-1;
            
            vcnt_val = '0;
            rcnt_val = '0;
            
            rfirst_val = 0;
            rlast_val = 0;
            rbusy_val = 0;
            rvalid_val = 0;

            vec_ra_val = '0;
            mat_ra_val = '0;
        end
        COMPUTE: begin
            rvec_start_val = rvec_start;
            rvec_words_val = rvec_words;
            rmat_start_val = rmat_start;
            rmat_rows_val = rmat_rows;

            vcnt_val = (vcnt == rvec_words) ? 0 : (vcnt + 1);
            rcnt_val = (vcnt == rvec_words) ? (rcnt + 1) : rcnt;
            
            rfirst_val = (vcnt == 0) ? 1 : 0;
            rlast_val = (vcnt == rvec_words) ? 1 : 0;
            rbusy_val = 1;
            rvalid_val = 1;
            
            vec_ra_val = rvec_start + vcnt;
            mat_ra_val = (vcnt == 0 && rcnt == 0) ? rmat_start : (mat_ra + 1);
        end
    endcase
end

assign accum_first = rfirst;
assign accum_last = rlast;
assign ovalid = rvalid;
assign busy = rbusy;
assign vec_raddr = vec_ra;
assign mat_raddr = mat_ra;

endmodule