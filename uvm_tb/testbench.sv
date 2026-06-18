// used for EDAPlayground
`include "mvm_if.sv"

package mvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "mvm_txn.sv"
    `include "mvm_base_sequence.sv"
    `include "mvm_driver.sv"
    `include "mvm_monitor.sv"
    `include "mvm_agent.sv"
    `include "mvm_scoreboard.sv"
    `include "mvm_env.sv"
    `include "mvm_test.sv"
endpackage

`timescale 1 ns / 1 ps  // 1ns time resolution, 1ps precision
`include "uvm_macros.svh"

module top;
    import uvm_pkg::*;  // import base types and macros required by the verification methodology
    import mvm_pkg::*;  // import custom verification components, sequences, and tests
	
    parameter int IWIDTH = 8;
    parameter int OWIDTH = 32;
    parameter int MEM_DATAW = IWIDTH * 8;
    parameter int VEC_MEM_DEPTH = 256;
    parameter int MAT_MEM_DEPTH = 512;
    parameter int VEC_ADDRW = $clog2(VEC_MEM_DEPTH);
    parameter int MAT_ADDRW = $clog2(MAT_MEM_DEPTH);
    parameter int NUM_OLANES = 8; // Locked to 8 lanes
  
    bit clk;
    logic rst;
    
    // clock generation loop
    initial begin
        clk = 0;
        // toggles every 2ns, establishing a complete 4ns clock period (250 MHz)
        forever #2 clk = ~clk;
    end

    // power-on reset sequence
    initial begin
        rst = 1;    // assert active-high reset at time 0
        #20;        // hold reset asserted for 20ns
        rst = 0;    // deassert reset to allow the DUT to run normally
    end

    // instantiate interface
    mvm_if #(
        .IWIDTH(IWIDTH),
        .OWIDTH(OWIDTH),
        .MEM_DATAW(MEM_DATAW),
        .VEC_MEM_DEPTH(VEC_MEM_DEPTH),
        .VEC_ADDRW(VEC_ADDRW),
        .MAT_MEM_DEPTH(MAT_MEM_DEPTH),
        .MAT_ADDRW(MAT_ADDRW),
        .NUM_OLANES(NUM_OLANES)
    ) vif (
        .clk(clk),
        .rst(rst)
    );

    // instantiate DUT
    mvm #(
        .IWIDTH(IWIDTH),
        .OWIDTH(OWIDTH),
        .MEM_DATAW(MEM_DATAW),
        .VEC_MEM_DEPTH(VEC_MEM_DEPTH),
        .VEC_ADDRW(VEC_ADDRW),
        .MAT_MEM_DEPTH(MAT_MEM_DEPTH),
        .MAT_ADDRW(MAT_ADDRW),
        .NUM_OLANES(NUM_OLANES)
    ) dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .i_vec_wdata(vif.i_vec_wdata),
        .i_vec_waddr(vif.i_vec_waddr),
        .i_vec_wen(vif.i_vec_wen),
        .i_mat_wdata(vif.i_mat_wdata),
        .i_mat_waddr(vif.i_mat_waddr),
        .i_mat_wen(vif.i_mat_wen),
        .i_start(vif.i_start),
        .i_vec_start_addr(vif.i_vec_start_addr),
        .i_vec_num_words(vif.i_vec_num_words),
        .i_mat_start_addr(vif.i_mat_start_addr),
        .i_mat_num_rows_per_olane(vif.i_mat_num_rows_per_olane),
        .o_busy(vif.o_busy),
        .o_result(vif.o_result),
        .o_valid(vif.o_valid)
    );

    // bootstrap UVM
    initial begin
      	$dumpfile("dump.vcd");
      	$dumpvars(0, top);
      
        // store the physical interface instance ('vif') into the central database
      	uvm_config_db#(virtual mvm_if #(.NUM_OLANES(NUM_OLANES)))::set(null, "*", "vif", vif);

        // command the UVM core engine to instantiate, phase, and launch "mvm_test" (starts simulation)
        run_test("mvm_test");  
    end
endmodule