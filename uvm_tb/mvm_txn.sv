class mvm_txn extends uvm_sequence_item;
    localparam IWIDTH = 8;
    localparam OWIDTH = 32;
    localparam NUM_OLANES = 8;

    // payload registers
    logic signed [IWIDTH-1:0] vector[];
    logic signed [IWIDTH-1:0] matrix[][];

    // matrix dimensions
    rand int M;
    rand int N;

    // padding dimensions (pre-added multiples of 8)
    int M_PADDED;
    int N_PADDED;

    // result to capture from the hardware
    logic signed [OWIDTH-1:0] hw_result[];

  	`uvm_object_utils(mvm_txn)

    // constrain the math problem to anywhere between 8 and 32
    constraint c_math_size {
      	M inside {[1:32]};
      	N inside {[1:32]};
    }

    // constructor
    function new(string name = "mvm_txn");
        super.new(name);
    endfunction

    // this runs after M and N are randomized
    function void post_randomize();
        // calculate the padded dimensions
        M_PADDED = (M % NUM_OLANES == 0) ? M : M + (NUM_OLANES - (M % NUM_OLANES));
        N_PADDED = (N % 8 == 0) ? N : N + (8 - (N % 8));

        // size the arrays to the physical hardware size
        vector = new[N_PADDED];
        matrix = new[M_PADDED];
        foreach(matrix[i]) matrix[i] = new[N_PADDED];

        // fill the matrix arrays: random data for valid math, zeros for padding
        for (int j = 0; j < M_PADDED; j++) begin
            for (int i = 0; i < N_PADDED; i++) begin
                if (i < N && j < M) begin
                    matrix[j][i] = $urandom;
                end else begin
                    matrix[j][i] = 0;  // pad extra hardware space with zeros
                end
            end
        end
        
        // fill the vector array
        for (int i = 0; i < N_PADDED; i++) begin
            vector[i] = (i < N) ? $urandom : 0; 
        end
    endfunction
  
  	virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("M", M, 32, UVM_DEC);
        printer.print_field("N", N, 32, UVM_DEC);
        printer.print_field("M_PADDED", M_PADDED, 32, UVM_DEC);
        printer.print_field("N_PADDED", N_PADDED, 32, UVM_DEC);
    endfunction
endclass