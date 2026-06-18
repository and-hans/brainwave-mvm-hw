class mvm_driver extends uvm_driver #(mvm_txn);
    `uvm_component_utils(mvm_driver)
  
    localparam NUM_OLANES = 8;
    localparam IWIDTH = 8;  

    virtual mvm_if #(.NUM_OLANES(NUM_OLANES)) vif;
  
    uvm_analysis_port #(mvm_txn) ap;

    // constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // build phase
    function void build_phase(uvm_phase phase);
        ap = new("ap", this);
        
        super.build_phase(phase);
        if (!uvm_config_db #(virtual mvm_if #(.NUM_OLANES(NUM_OLANES)))::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in config_db")
    endfunction

    // run phase 
    task run_phase(uvm_phase phase);
        wait(vif.rst == 1'b0);
      
        @(vif.drv_cb);
      
        vif.drv_cb.i_vec_wen <= 0;
        vif.drv_cb.i_mat_wen <= 0;
        vif.drv_cb.i_start   <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_mvm(req);
            ap.write(req);
            seq_item_port.item_done();
        end
    endtask

    // unpacks matrix/vector elements and streams them into memory blocks
    task drive_mvm(mvm_txn txn);
        logic [(8*IWIDTH)-1:0] packed_vec_word;
        logic [(8*IWIDTH)-1:0] packed_mat_word;

        vif.drv_cb.i_vec_start_addr <= 0;
        vif.drv_cb.i_mat_start_addr <= 0;
        vif.drv_cb.i_vec_num_words <= txn.N_PADDED / 8;  
        vif.drv_cb.i_mat_num_rows_per_olane <= txn.M_PADDED / NUM_OLANES;  
        @(vif.drv_cb);

        // pack and stream vector memory
        for (int w = 0; w < txn.N_PADDED/8; w++) begin
            packed_vec_word = '0;
            for (int e = 0; e < 8; e++) begin
                packed_vec_word[e*IWIDTH +: IWIDTH] = txn.vector[w*8 + e];
            end
            vif.drv_cb.i_vec_wdata <= packed_vec_word; // drive as single clean block
            vif.drv_cb.i_vec_waddr <= 0 + w;  
            vif.drv_cb.i_vec_wen <= 1;  
            @(vif.drv_cb);
        end
        vif.drv_cb.i_vec_wen <= 0;  

        // pack and stream matrix memory
        for (int r = 0; r < txn.M_PADDED; r++) begin
            for (int w = 0; w < txn.N_PADDED/8; w++) begin
                packed_mat_word = '0;
                for (int e = 0; e < 8; e++) begin
                    packed_mat_word[e*IWIDTH +: IWIDTH] = txn.matrix[r][w*8 + e]; 
                end
                vif.drv_cb.i_mat_wdata <= packed_mat_word; // drive as single clean block
                vif.drv_cb.i_mat_waddr <= 0 + (r/NUM_OLANES * (txn.N_PADDED/8)) + w;
                vif.drv_cb.i_mat_wen <= (1 << (r % NUM_OLANES));
              
                @(vif.drv_cb);
            end
        end
        vif.drv_cb.i_mat_wen <= 'd0;  
        @(vif.drv_cb);

        // trigger computation
        vif.drv_cb.i_start <= 1;  
        @(vif.drv_cb);
        vif.drv_cb.i_start <= 0;

      	do @(vif.drv_cb); while (vif.drv_cb.o_busy == 1'b0); // wait for wake up
      	do @(vif.drv_cb); while (vif.drv_cb.o_busy == 1'b1); // wait for computation finish
    endtask
endclass