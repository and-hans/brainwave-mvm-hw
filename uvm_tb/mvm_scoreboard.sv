class mvm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mvm_scoreboard)

    // analysis fifo handles
    uvm_tlm_analysis_fifo #(mvm_txn) stimulus_fifo;
    uvm_tlm_analysis_fifo #(mvm_txn) result_fifo;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);

        stimulus_fifo = new("stimulus_fifo", this);
        result_fifo = new("result_fifo", this);
    endfunction

    // run phase
  task run_phase(uvm_phase phase);
        mvm_txn stim_txn;
        mvm_txn res_txn;
    logic signed [31:0] expected_result[];  // stores calculated golden results 
        bit match;

        // infinite loop keeps the checking mechanism alive during the test run
        forever begin
            // exection pauses here until both FIFOs contain at least one matched pair of transaction to process
            stimulus_fifo.get(stim_txn);
            result_fifo.get(res_txn);

            match = 1;  // assume the check will pass until a mismatch proves otherwise
            expected_result = new[stim_txn.M_PADDED];  // allocate array size to match the matrix rows

            // golden model (software reference math)
            for (int j = 0; j < stim_txn.M_PADDED; j++) begin
                expected_result[j] = 0;  // clear accumulator for current row
                for (int i = 0; i < stim_txn.N_PADDED; i++) begin
                    // accumulate the dot product of the input vector and matrix row
                  	expected_result[j] += 32'(signed'(stim_txn.vector[i])) * 32'(signed'(stim_txn.matrix[j][i]));
                end
            end

            // compares the calculated golden results against the hardware values 
            for (int j = 0; j < stim_txn.M_PADDED; j++) begin
                // case-inequality (!==) checks for a strict match, catching unintended X/Z states
                if (res_txn.hw_result[j] !== expected_result[j]) begin
                    `uvm_error("MVM_FAIL", $sformatf("Row %0d: Expected %0d, Got %0d",
                                j, expected_result[j], res_txn.hw_result[j]))
                    match = 0;
                end else begin
                  	`uvm_info("MVM_PASS", $sformatf("Row %0d: Expected %0d, Got %0d",
                                                    j, expected_result[j], res_txn.hw_result[j]), UVM_LOW)
                end
            end

            // if all elements in the vector match, log a success message
            if (match) begin 
              `uvm_info("MVM_PASS", $sformatf("Successfully verified %0d padded rows.",
                          stim_txn.M_PADDED), UVM_LOW)
            end
        end
  	endtask
endclass