class mvm_monitor extends uvm_monitor;
    `uvm_component_utils(mvm_monitor)
  
  	localparam int NUM_OLANES = 8;
    localparam int OWIDTH = 32;
	
  	// virtual interface handle
  	virtual mvm_if #(.NUM_OLANES(NUM_OLANES)) vif;
  
  	uvm_analysis_port #(mvm_txn) ap;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      	if(!uvm_config_db#(virtual mvm_if #(.NUM_OLANES(NUM_OLANES)))::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in config_db")
    endfunction
          
    // run phase
    task run_phase(uvm_phase phase);
        mvm_txn txn;
        int expected_passes;  // total number of clock cycles/valid steps needed to capture all data
        int current_pass;  // counter to track the progress of the active collection cycle

        forever begin
            // wait for the driver to pulse the start line high
          	do begin
              @(vif.mon_cb);
            end while (vif.mon_cb.i_start !== 1'b1);
            
            // capture the runtime loop dimensions directly from the input configurations
          	expected_passes = vif.mon_cb.i_mat_num_rows_per_olane; 
            current_pass = 0;

            txn = mvm_txn::type_id::create("txn");  // allocate a new transaction container

            // flattend dynamic array allocation (total rows = passes * active exection lanes)
            txn.hw_result = new[expected_passes * NUM_OLANES];
            
            // data collection loop, block here until every calculation row is safely parsed
            while (current_pass < expected_passes) begin
              	@(vif.mon_cb);  // sync to the clock edge
                
                // only capture and sample pins if the DUT asserts its output valid qualifier
                if (vif.mon_cb.o_valid) begin
                    // sift through the parallel lanes layout burst word
                    for (int i = 0; i < NUM_OLANES; i++) begin
                        // bit-slice out each lane's individual 32-bit output result, cast sign-extension, and map it into the flattened results array
                        txn.hw_result[(current_pass * NUM_OLANES) + i] = $signed(vif.mon_cb.o_result[i * OWIDTH +: OWIDTH]);
                    end
                    current_pass++;  // increment pass index once all parallel lanes are stored
                end
            end
            // hand over the fully populated hardware results data package to the scoreboard 
            ap.write(txn);
        end
    endtask
endclass