class mvm_agent extends uvm_agent;
    `uvm_component_utils(mvm_agent)

    // sub-component handles
    uvm_sequencer #(mvm_txn) sqr;
    mvm_driver               drv;
    mvm_monitor              mon;
  	
  	// analysis port handles
  	uvm_analysis_port #(mvm_txn) result_ap;
	uvm_analysis_port #(mvm_txn) stimulus_ap;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      
      	result_ap = new("result_ap", this);
      	stimulus_ap = new("stimulus_ap", this);
      
      	mon = mvm_monitor::type_id::create("mon", this);

        // allocate memory for each component if the agent is active
      	if (get_is_active() == UVM_ACTIVE) begin
          sqr = uvm_sequencer#(mvm_txn)::type_id::create("sqr", this);
          drv = mvm_driver::type_id::create("drv", this);
        end
    endfunction

    // connect phase 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
      
      	mon.ap.connect(this.result_ap);

        // establishes the TLM handshake channel between driver and sequencer is the agent is active
      	if (get_is_active() == UVM_ACTIVE) begin
        	drv.seq_item_port.connect(sqr.seq_item_export);
          	drv.ap.connect(this.stimulus_ap);
      	end
    endfunction
endclass