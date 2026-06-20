import math
import random

import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

# define clock period to be used in simulation
CLK_PERIOD: int = 4		

# DUT parameters
IWIDTH: int = 8
OWIDTH: int = 32
MEM_DATAW: int = IWIDTH * 8
VEC_DATAW: int = IWIDTH * 8
MAT_DATAW: int = IWIDTH * 8
NUM_OLANES: int = 8

# test parameters
M: int = 128  # matrix height
N: int = 128  # matrix width or vector length
M_PADDED: int = int(math.ceil(1.0 * M // NUM_OLANES) * NUM_OLANES)
N_PADDED: int = int(math.ceil(1.0 * N // 8) * 8)
VEC_MEM_DEPTH: int = N_PADDED // 8 if ((N_PADDED // 8) > 256) else 256
VEC_ADDRW: int = math.ceil(math.log2(VEC_MEM_DEPTH))
MAT_MEM_DEPTH: int = N_PADDED * M_PADDED // 8 // NUM_OLANES if ((N_PADDED * M_PADDED // 8 // NUM_OLANES) > 512) else 512
MAT_ADDRW: int = math.ceil(math.log2(MAT_MEM_DEPTH))

# test data containers
test_vector: np.array = np.zeros(N_PADDED, dtype=np.int32)
test_matrix: np.array = np.zeros((M_PADDED, N_PADDED), dtype=np.int32)
golden_result: np.array = np.zeros(M_PADDED, dtype=np.int32)

# random localized generators
matrix_rng: random.Random = random.Random(1)
vector_rng: random.Random  = random.Random(2)

# fill the matrix non-padded cells with random values and padded cells with zeros
for j in range(M_PADDED):
    for i in range(N_PADDED):
        if (i < N and j < M):
            test_matrix[j][i] = matrix_rng.randint(-128, 127)
        else :
            test_matrix[j][i] = 0

# fill the vector array with random values
for i in range(N_PADDED):
    test_vector[i] = vector_rng.randint(-128, 127) if (i < N) else 0

# compute the golden results
for j in range(M_PADDED):
    for i in range(N_PADDED):
        golden_result[j] += test_vector[i] * test_matrix[j][i]


@cocotb.test()
async def mvm_test(dut):
    """Drives inputs, triggers computation, and verifies outputs against the golden model."""

    # generate 2 ns clock
    clock = Clock(dut.clk, CLK_PERIOD, unit="ns")
    cocotb.start_soon(clock.start())

    # initialize interface
    dut.rst.value = 1
    dut.i_vec_wdata.value = 0
    dut.i_vec_waddr.value = 0
    dut.i_vec_wen.value = 0
    dut.i_mat_wdata.value = 0
    dut.i_mat_waddr.value = 0
    dut.i_mat_wen.value = 0
    dut.i_start.value = 0
    dut.i_vec_start_addr.value = 0
    dut.i_vec_num_words.value = 0
    dut.i_mat_start_addr.value = 0
    dut.i_mat_num_rows_per_olane.value = 0

    # hold reset
    for _ in range(50):
        await RisingEdge(dut.clk)
    
    # turn off reset and update inputs
    await FallingEdge(dut.clk)
    dut.rst.value = 0
    dut.i_vec_start_addr.value = 0
    dut.i_mat_start_addr.value = 0
    dut.i_vec_num_words.value = N_PADDED // 8
    dut.i_mat_num_rows_per_olane.value = M_PADDED // NUM_OLANES
    await FallingEdge(dut.clk)

    # write vector data to hardware
    dut._log.info("Streaming Vector Data...")
    for w in range(N_PADDED // 8):
        packed_vec_word = 0
        for e in range(8):
            base = e * IWIDTH
            src_val = int(test_vector[w * 8 + e])
            masked_data = src_val & ((1 << IWIDTH) - 1)
            packed_vec_word |= (masked_data << base)
        
        # drive the fully assembled 64-bit word to the hardware
        dut.i_vec_wdata.value = packed_vec_word
        dut.i_vec_waddr.value = dut.i_vec_start_addr.value.to_unsigned() + w
        dut.i_vec_wen.value = 1
        await RisingEdge(dut.clk)
    
    # stop writing to vector 
    dut.i_vec_wen.value = 0
    await RisingEdge(dut.clk)

    # write matrix data to hardware
    dut._log.info("Streaming Matrix Data...")
    for r in range(M_PADDED):
        for w in range(N_PADDED // 8):
            packed_mat_word = 0
            for e in range(8):
                base = e * IWIDTH
                src_val = int(test_matrix[r][w * 8 + e])
                masked_data = src_val & ((1 << IWIDTH) - 1)
                packed_mat_word |= (masked_data << base)
            
            # drive the fully assembled 64-bit word to the hardware
            dut.i_mat_wdata.value = packed_mat_word
            dut.i_mat_waddr.value = dut.i_mat_start_addr.value.to_unsigned() + (r // NUM_OLANES * N_PADDED // 8) + w
            dut.i_mat_wen.value = (1 << (r % NUM_OLANES))
            await RisingEdge(dut.clk)
    
    dut.i_mat_wen.value = 0
    await RisingEdge(dut.clk)

    dut._log.info("Triggering Computation...")
    dut.i_start.value = 1
    await RisingEdge(dut.clk)

    dut.i_start.value = 0

    dut._log.info("Waiting for hardware to process...")
    results_captured: int = 0

    # provide a timeout safeguard to prevent an infinite loop if the FSM stalls
    timeout_counter: int = 0
    MAX_TIMEOUT: int = 10000

    while (results_captured < M_PADDED):
        await RisingEdge(dut.clk)
        timeout_counter += 1

        if timeout_counter > MAX_TIMEOUT:
            assert False, "Simulation timed out waiting for o_valid"
        
        if (dut.o_valid.value.is_resolvable and dut.o_valid.value == 1):
            # read the entire 256-but wide output bus
            full_out_bus: int = dut.o_result.value.to_unsigned()

            # sift through the parallel output lanes
            for i in range(NUM_OLANES):
                row_idx: int = results_captured + i

                # bit-slice out the specific 32-bit lane
                hw_val_unsigned: int = (full_out_bus >> (i * OWIDTH)) & ((1 << OWIDTH) - 1)

                # apply two's complement sign extension for python
                if hw_val_unsigned & (1 << (OWIDTH - 1)):
                    hw_val_signed = hw_val_unsigned - (1 << OWIDTH)
                else:
                    hw_val_signed = hw_val_unsigned

                golden_val = golden_result[row_idx]

                if hw_val_signed != golden_val:
                    dut._log.error(f"Mismatch at Row {row_idx}: Expected {golden_val}, Got {hw_val_signed}")
                    assert False, "Test Failed due to data mismatch."
                else:
                    dut._log.debug(f"Row {row_idx} Match: Expected {golden_val}, Got {hw_val_signed}")
            
            results_captured += NUM_OLANES

            # reset timeout since we got valid data
            timeout_counter = 0
    
    # flush pileine before ending
    for _ in range(10):
        await RisingEdge(dut.clk)
    
    dut._log.info(f"TEST PASSED! Successfully verified all {M_PADDED} padded rows.")
