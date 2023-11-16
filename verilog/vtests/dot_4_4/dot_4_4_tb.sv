`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Created for Indiana University's E315 Class
//
// 
// Andrew Lukefahr
// lukefahr@iu.edu
//
// 2021-03-24
//
//////////////////////////////////////////////////////////////////////////////////


module dot_4_4_tb();

    integer                     i;
    
    // Clock signal
    bit                         clk;
    // Reset signal
    bit                         rst;

    // Incomming Matrix AXI4-Stream
    reg [31:0]                  INPUT_AXIS_TDATA;
    reg                         INPUT_AXIS_TLAST;
    reg                         INPUT_AXIS_TVALID;
    wire                        INPUT_AXIS_TREADY;
    
    // Outgoing Vector AXI4-Stream 		
    wire [31:0]                 OUTPUT_AXIS_TDATA;
    wire                        OUTPUT_AXIS_TLAST;
    wire                        OUTPUT_AXIS_TVALID;
    reg                         OUTPUT_AXIS_TREADY;


    //used to access the FP tests table    
    bit [31:0] fp_hex;
    //used to access the FP Solutions table
    bit [31:0] sol_hex;
 
    axis_dot_4_4 DUT ( 
        .aclk(clk), 
        .aresetn(~rst), 

        .INPUT_AXIS_TDATA,
        .INPUT_AXIS_TLAST,
        .INPUT_AXIS_TVALID,
        .INPUT_AXIS_TREADY,
        
        .OUTPUT_AXIS_TDATA,
        .OUTPUT_AXIS_TLAST,
        .OUTPUT_AXIS_TVALID,
        .OUTPUT_AXIS_TREADY

    );  


    always #10 clk <= ~clk;
    
    task inputs_table_lookup(
        input integer id,
        output bit [31:0] hex
        );

        static bit [31:0] fpHex [0:3] = {
         $shortrealtobits(0.1), $shortrealtobits(0.2), $shortrealtobits(0.3), $shortrealtobits(0.4) 
        };
        static int MAX_SIZE = 4;

        assert(id < MAX_SIZE) else $fatal(1, "Bad id");
        hex = fpHex[id];
    endtask : inputs_table_lookup  
    
    // see python/dot_20_10.py for values
    task outputs_table_lookup(
        input integer id,
        output bit [31:0] hex
        );

        static bit [31:0] fpHex [0:3] = {
          $shortrealtobits(9.0), $shortrealtobits(10.0), $shortrealtobits(11.0), $shortrealtobits(12.0) 
        };
        static int MAX_SIZE = 4;
                
        assert(id <MAX_SIZE) else $fatal(1, "Bad id");
        hex = fpHex[id];
    endtask: outputs_table_lookup
    
    
    task send_word_axi4stream(
        input logic [31:0] data,
        input logic last
    );
    
        INPUT_AXIS_TDATA = data;
        INPUT_AXIS_TVALID='h1;
        INPUT_AXIS_TLAST = last;
        #1;
        while( INPUT_AXIS_TREADY == 'h0)  begin
            @(negedge clk);
            #1;
        end
        
        @(negedge clk);
        INPUT_AXIS_TVALID='h0;
        INPUT_AXIS_TLAST='h0;

    endtask

    task recv_word_axi4stream(
        output logic [31:0] data
    );
    
        OUTPUT_AXIS_TREADY = 'h1;
        #1;
        while (OUTPUT_AXIS_TVALID == 'h0) begin
            @(negedge clk);
            #1;
        end
        
        data = OUTPUT_AXIS_TDATA;
        @(negedge clk);
        OUTPUT_AXIS_TREADY = 'h0;
    
    endtask    

    task init();

        clk = 'h0;
        rst = 'h1;

        INPUT_AXIS_TDATA = 'h0;
        INPUT_AXIS_TLAST = 'h0;
        INPUT_AXIS_TVALID = 'h0;
        
        OUTPUT_AXIS_TREADY = 'h0;
      
       i = 0;
    endtask

    task compute();
        $display("Sending Input Vector");                
        for (i = 0; i < ROWS; ++i) begin
            inputs_table_lookup(i, fp_hex);
            $display( "Sending %h (%f)", fp_hex, $bitstoshortreal(fp_hex) ); 
            send_word_axi4stream(fp_hex, i == 19);
        end                
              
        $display("Receiving Output Vector");
        for (i = 0; i < COLS; ++i) begin
            real error; 
            
            outputs_table_lookup(i, sol_hex);
            
            recv_word_axi4stream(fp_hex);
            
            $display( "Received %h (%f)",
                fp_hex, $bitstoshortreal(fp_hex));
                
            //skip bit 0 to tolerate off-by-1-LSB rounding errors
            error = $bitstoshortreal(fp_hex) - $bitstoshortreal(sol_hex);
            $display("Error: %f", error);
            
            assert( (error > -0.000001) && (error < +0.000001) ) else
                $fatal(1, "Bad Test Response %h (%f), Expected %h (%f) Error:%f", 
                    fp_hex, $bitstoshortreal(fp_hex), sol_hex, $bitstoshortreal(sol_hex), error); 
            
        end
    endtask

    task timeit (
        output int cycles
        );
        
        cycles = 0;
        while ( ! (
            (OUTPUT_AXIS_TREADY === 'h1) && 
            (OUTPUT_AXIS_TVALID === 'h1) && 
            (OUTPUT_AXIS_TLAST === 'h1) ) ) begin
            cycles += 1;
            
            @(posedge clk);
            
            assert (cycles < 44100) else 
                $fatal(1, "Running too long, check OUTPUT_AXIS?");
        end
                        
    endtask
    

    //Main process
    initial begin
 
        int cycles;
        
        $timeformat (-12, 1, " ps", 1);      

        $display("Simulation Setup");
        init();
        
        $display("Holding Reset");
        for (i = 0; i < 20; i++) 
        @(negedge clk);

        rst = 0;        

        repeat(2) @(negedge clk);
        
        $display("Starting Simulation"); 
        
        fork
            compute();
            timeit(cycles);
        join                                                  
        
        $display("@@@Passed in %d Cycles (was 2210)", cycles);
        
        $finish;

    end

endmodule
