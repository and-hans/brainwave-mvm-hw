class mvm_test extends uvm_test;
    `uvm_component_utils(mvm_test)

    // enviornment handle
    mvm_env env;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // build phase 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = mvm_env::type_id::create("env", this);  // instantiate the enviornment
    endfunction

    // run phase
    task run_phase(uvm_phase phase);
        mvm_base_sequence seq;  // handle for the stimulus generator script
		
      	// set drain time for this phase to be 500 ns
      	phase.get_objection().set_drain_time(this, 500ns);
      
        // raise objection (prevents the UVM simulation engine from ending prematurely)
        phase.raise_objection(this);

        // instantiate the test scenario 
        seq = mvm_base_sequence::type_id::create("seq");

        `uvm_info("TEST", "Starting MVM Base Sequence...", UVM_LOW)

        // start the sequence (hands the script over to the agent's sequencer 'sqr')
        // this triggers the sequence's body() task to begin gnerating transactions
        seq.start(env.agent.sqr);
      
      	`uvm_info("TEST", "Sequence finished generating stimulus. Waiting for hardware pipeline to drain...", UVM_LOW)
      	

        // drop objection (signals that this test thread has finished its work)
        // once all raised objections in the system drop to zero, UVM ends the simulation safely
        phase.drop_objection(this);
    endtask
endclass