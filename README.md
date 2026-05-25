## ECE 327 Lab 4: Matrix-Vector Multiplication (MVM) Engine

### Overview
This repository contains the SystemVerilog implementation of a complete matrix-vector multiplication (MVM) engine for vectors and matrices of arbitrary sizes. The hardware architecture is similar to the Microsoft BrainWave deep learning accelerator. The circuit is optimized to meet timing constraints at 350 MHz on a Xilinx Kria FPGA board.

### Project Structure
| File | Description |
| :--- | :--- |
| `mvm.sv` | Top-level integration module containing the vector memory and NUM_OLANES compute lanes. |
| `ctrl.sv` | Finite-state machine (FSM) controller responsible for orchestrating memory reads, dot products, and accumulation. |
| `dot8.sv` | Fully pipelined 8-lane dot product unit. |
| `accum.sv` | Accumulator module designed for summing signed integer values. |
| `mem.sv` | Parameterizable simple dual-port memory block. |

### Mathematical Operations
* The core calculation driving the datapath is the dot product operation.
* For input vectors, the scalar result is calculated using the formula $o=\sum_{i=0}^{N-1}a_ib_i$.

### Development & Testing
* The hardware design, simulation, and debugging are executed within Vivado.
* Functional correctness and integration verification are tested using the `mvm_tb.sv` testbench.
* Running the implementation flow requires out-of-context synthesis (using the `-mode out_of_context` flag) to bypass the IO pin limitations of the FPGA on the Kria board.

### Authors
* Andrew Hansraj
* Leo Wang