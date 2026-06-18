interface mvm_if #(
    parameter IWIDTH            = 8,
    parameter OWIDTH            = 32,
    parameter MEM_DATAW         = IWIDTH * 8,
    parameter VEC_MEM_DEPTH     = 256,
    parameter VEC_ADDRW         = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH     = 512,
    parameter MAT_ADDRW         = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES        = 128
)(
    input logic clk,
    input logic rst
);
    // vector memory ports
  	logic [MEM_DATAW-1:0]   i_vec_wdata;
  	logic [VEC_ADDRW-1:0]   i_vec_waddr;
    logic                   i_vec_wen;

    // matrix memory ports
  	logic [MEM_DATAW-1:0]   i_mat_wdata;
  	logic [MAT_ADDRW-1:0]   i_mat_waddr;
  	logic [NUM_OLANES-1:0]  i_mat_wen;

    // control ports
    logic                   i_start;
  	logic [VEC_ADDRW-1:0]   i_vec_start_addr;
  	logic [VEC_ADDRW:0]     i_vec_num_words;
  	logic [MAT_ADDRW-1:0]   i_mat_start_addr;
  	logic [MAT_ADDRW:0]     i_mat_num_rows_per_olane;

    // output ports
    logic                           o_busy;
  	logic [OWIDTH*NUM_OLANES-1:0]   o_result;
    logic                           o_valid;
  
  // driver clocking block
  clocking drv_cb @(posedge clk);
    default input #1step output #1ns;
    output i_vec_wdata, i_vec_waddr, i_vec_wen, i_mat_wdata, i_mat_waddr, i_mat_wen, i_start, i_vec_start_addr, i_vec_num_words, i_mat_start_addr, i_mat_num_rows_per_olane;
    input  o_busy, o_result, o_valid;
  endclocking

  // monitor clocking block
  clocking mon_cb @(posedge clk);
    default input #1step;
    input i_vec_wdata, i_vec_waddr, i_vec_wen, i_mat_wdata, i_mat_waddr, i_mat_wen, i_start, i_vec_start_addr, i_vec_num_words, i_mat_start_addr, i_mat_num_rows_per_olane, o_busy, o_result, o_valid;
  endclocking
  
endinterface