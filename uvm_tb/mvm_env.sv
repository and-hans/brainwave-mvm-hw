class mvm_env extends uvm_env;
    `uvm_component_utils(mvm_env)

    // structural component handles
    mvm_agent       agent;
    mvm_scoreboard  scoreboard;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // build phase 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // instantiate the agent and scoreboard
        agent = mvm_agent::type_id::create("agent", this);
        scoreboard = mvm_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // connects the agents exterior port to the scoreboard's result FIFO
        agent.result_ap.connect(scoreboard.result_fifo.analysis_export);

        // connects the agents exterior port to the scoreboard's stimulus FIFO
        agent.stimulus_ap.connect(scoreboard.stimulus_fifo.analysis_export);
    endfunction
endclass