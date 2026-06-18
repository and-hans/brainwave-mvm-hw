class mvm_base_sequence extends uvm_sequence #(mvm_txn);
    `uvm_object_utils(mvm_base_sequence)

    // constructor
    function new(string name = "mvm_base_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting 10 randomized MVM operations...", UVM_LOW)
	
        // run 10 consecutive, randomized mvm operations 
        repeat(10) begin
          	req = mvm_txn::type_id::create("req");

          	start_item(req);
          
          	if(!req.randomize()) begin
                `uvm_fatal("SEQ_ERROR", "Failed to randomize MVM transaction")
            end
          
          	`uvm_info("SEQ", $sformatf("Sending Matrix: %0dx%0d (Padded: %0dx%0d)", 
                                       req.M, req.N, req.M_PADDED, req.N_PADDED), UVM_HIGH)
          
          	finish_item(req);
        end
      
      	`uvm_info("SEQ", "Finished MVM operations.", UVM_LOW)
    endtask
endclass