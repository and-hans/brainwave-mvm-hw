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

## UVM Verification Environment
This project features a robust, standard-compliant Universal Verification Methodology (UVM) testbench designed to verify the functional correctness of the MVM engine using constrained random stimulus and automated checking.

### Key Features of the Testbench
* **Constrained Random Stimulus:** The transaction item (`mvm_txn`) dynamically randomizes matrix dimensions ($M \times N$, sized between 1 and 32). It automatically calculates hardware padding limits and populates the stimulus arrays with random 8-bit signed integers, padding the remaining hardware space with zeros.
* **Golden Reference Scoreboard:** The `mvm_scoreboard` utilizes a software-based golden reference model. It computes the expected dot-product accumulation natively in SystemVerilog and uses TLM Analysis FIFOs to compare the expected values against the hardware results dynamically.
* **Cycle-Accurate Drivers & Monitors:** 
  * The **Driver** carefully packs the randomized 8-bit data into the wide memory interfaces and streams the padded matrices and vectors into the DUT.
  * The **Monitor** waits for the `o_valid` flag, captures the 256-bit output bus, and bit-slices it into 8 parallel output lanes before broadcasting the results to the scoreboard.

### UVM Architecture
The verification environment is fully encapsulated and follows a standard UVM hierarchical topology:
* **`mvm_test`**: Initializes the environment and launches the `mvm_base_sequence` (generating 10 back-to-back randomized MVM operations).
* **`mvm_env`**: Contains the active agent and the scoreboard.
* **`mvm_agent`**: Encapsulates the Sequencer, Driver, and Monitor, routing TLM analysis ports to the environment level.

### Running the Simulation
**Browser-Based Execution:**
You can run this UVM testbench directly in your browser without compiling anything locally by using this [EDA Playground](https://www.edaplayground.com/x/wCAd)  link. 

**Local Execution:**
To run the verification suite on your own machine, you can use any UVM 1.2 compliant simulator (such as Vivado XSim, VCS, Questa, or Xcelium). Ensure your simulator is configured to compile the UVM library. 

```bash
# Example compilation and execution using VCS
vcs -sverilog -ntb_opts uvm-1.2 -f filelist.f
./simv +UVM_TESTNAME=mvm_test
```

**Notes:**
* The simulated engine is functionally identical to the FPGA implementation. However, to support generic simulation, it replaces the hardware-specific Xilinx DSP48E2 primitive (3-stage pipeline) with a behavioral dsp_mult module (4-stage pipeline).
* **Source Files:** All files used in this online environment are available locally in the `edaplayground_src/` and `uvm_tb/` directories.

## Python Verification (Cocotb)
* In addition to SystemVerilog UVM, this project includes a complete Python-based testbench using [Cocotb](https://docs.cocotb.org/).
* **Golden Model:** The testbench leverages `numpy` to generate randomized stimulus and compute the exact expected dot-product results natively in software.
* **Automated Checking:** The script safely packs 8-bit slices into 64-bit words to avoid simulator delays, monitors the valid signal, and asserts the parallel hardware outputs against the software calculations.
* **Execution:** Run locally via `make SIM=icarus` (requires Python, `cocotb`, `numpy`, and a simulator like Icarus Verilog), or run it directly in your browser using the EDA Playground.
* **EDA Playground:** If you want to run the testbench via EDA Playground, the `Makefile` and `run.bash` files are located in the `coco_tb` directory. This testbench utilizes the source files available in `edaplayground_src`.

### Authors
* Andrew Hansraj
* Leo Wang
