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


module tb_dot();

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

    localparam ROWS = 3;
    localparam COLS = 4;

    localparam [31:0] weights [0:ROWS-1] [0:COLS-1] = '{
       '{$shortrealtobits(1.0),$shortrealtobits(2.0),$shortrealtobits(3.0),$shortrealtobits(4.0)},
       '{$shortrealtobits(5.0),$shortrealtobits(6.0),$shortrealtobits(7.0),$shortrealtobits(8.0)},
       '{$shortrealtobits(9.0),$shortrealtobits(10.0),$shortrealtobits(11.0),$shortrealtobits(12.0)}
    };

    //used to access the FP tests table    
    bit [31:0] fp_hex;
    //used to access the FP Solutions table
    bit [31:0] sol_hex;
 
    dot DUT ( 
        .clk, 
        .rst, 

        .weights(weights),
        
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
    
//     Python3
//     import numpy as np
    
//    weights = np.array( [[1,2,3,4],[5,6,7,8],[9,10,11,12]], dtype=np.float32)
//    inputs = np.array([[0.1,0.2,0.3]], dtype=np.float32)
//    outs = np.dot(inputs, weights)
    
//    flts = inputs[0]
//    flts_bits = list(map( lambda x: '$shortrealtobits(' + str(x) + ')', flts))
//    offset=4
//    print ('static bit [31:0] fpHex [0:' + str(len(flts)-1) + '] = {')
//    for i in range(0, len(flts), offset):
//        print (' ' + ', '.join(flts_bits[i:i+offset] ), end='')
//        print (',' if i < len(flts) - offset else ' ')
//    print ('};')
//    print ('static int MAX_SIZE = %d;' % len(flts))

    task inputs_table_lookup(
        input integer id,
        output bit [31:0] hex
        );
        
        static bit [31:0] fpHex [0:2] = {
            $shortrealtobits(0.1),
            $shortrealtobits(0.2),
            $shortrealtobits(0.3)
        };
        static int MAX_SIZE = 3;

        assert(id < MAX_SIZE) else $fatal(1, "Bad id");
        hex = fpHex[id];
    endtask : inputs_table_lookup  
    
//    Python3
//    import numpy as np
    
//    weights = np.array( [[1,2,3,4],[5,6,7,8],[9,10,11,12]], dtype=np.float32)
//    inputs = np.array([[0.1,0.2,0.3]], dtype=np.float32)
//    outs = np.dot(inputs, weights)
    
//    flts = outs[0]
//    flts_bits = list(map( lambda x: '$shortrealtobits(' + str(x) + ')', flts))
//    offset=4
//    print ('static bit [31:0] fpHex [0:' + str(len(flts)-1) + '] = {')
//    for i in range(0, len(flts), offset):
//        print (' ' + ', '.join(flts_bits[i:i+offset] ), end='')
//        print (',' if i < len(flts) - offset else ' ')
//    print ('};')
//    print ('static int MAX_SIZE = %d;' % len(flts))    
    task outputs_table_lookup(
        input integer id,
        output bit [31:0] hex
        );

        static bit [31:0] fpHex [0:3] = {
            $shortrealtobits(3.8000002), $shortrealtobits(4.4), $shortrealtobits(5.0), $shortrealtobits(5.6000004)
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

       

    //Main process
    initial begin
 
        
        $timeformat (-12, 1, " ps", 1);      

        $display("Simulation Setup");
        init();
        
        $display("Holding Reset");
        for (i = 0; i < 20; i++) 
        @(negedge clk);

        rst = 0;        

        repeat(2) @(negedge clk);
        
        $display("Starting Simulation"); 

                                
        $display("Sending Input Vector");                
        for (i = 0; i < 3; ++i) begin
            inputs_table_lookup(i, fp_hex);
            $display( "Sending %h (%f)", fp_hex, $bitstoshortreal(fp_hex) ); 
            send_word_axi4stream(fp_hex, i == 2);
        end                
              
        $display("Receiving Output Vector");
        for (i = 0; i < 4; ++i) begin
            outputs_table_lookup(i, sol_hex);
            
            recv_word_axi4stream(fp_hex);
            
            $display( "Received %h (%f)",
                fp_hex, $bitstoshortreal(fp_hex)); 
            assert( fp_hex == sol_hex ) else
                $fatal(1, "Bad Test Response %h (%f), Expected %h (%f)", 
                    fp_hex, $bitstoshortreal(fp_hex), sol_hex, $bitstoshortreal(sol_hex)); 
            
        end
        
        repeat(20) @(negedge clk);     
        
        $display("@@@Passed");
        
        $finish;

    end

endmodule
