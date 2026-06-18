package mvm_pkg;
    // import the base UVM class library types
    import uvm_pkg::*;

    // include the standard UVM utility macros
    `include "uvm_macros.svh"

    // Data Layer (Transactions & Sequences)
    `include "mvm_txn.sv"           // the transaction object must compile first because all components use it
    `include "mvm_base_sequence.sv"      // the sequence follows immediately because it generates these transactions
    
    // Interface Layer (Agent Components)
    `include "mvm_driver.sv"        // the driver and monitor compile next, referencing 'mvm_txn'
    `include "mvm_monitor.sv"
    `include "mvm_agent.sv"         // the agent wraps them, so it must compile after the driver and monitor exist
    
    // System Layer (Environment & Test)
    `include "mvm_scoreboard.sv"    // the scoreboard calculates results, needing 'mvm_txn'
    `include "mvm_env.sv"           // the environment instantiates the agent and scoreboard, so it sits above them
    `include "mvm_test.sv"          // the test builds the environment and triggers the sequence, sitting at the top
endpackage