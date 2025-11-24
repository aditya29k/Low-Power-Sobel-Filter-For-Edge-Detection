`ifndef ROW_WIDTH
	`define ROW_WIDTH 256
`endif

`ifndef DATA_ROW_WIDTH
	`define DATA_ROW_WIDTH $clog2(`ROW_WIDTH)
`endif 

`ifndef HEIGHT
	`define HEIGHT 256
`endif

`ifndef DATA_HEIGHT
	`define DATA_HEIGHT $clog2(`HEIGHT)
`endif

`ifndef DATA_WIDTH
	`define DATA_WIDTH 8
`endif

interface sobel_intf;
  
  logic clk, rst;
  logic recv_data;
  logic [`DATA_WIDTH-1:0] pixel;
  logic [10:0] gradient;
  logic gradient_valid;
  
endinterface

module tb();
  
  sobel_intf intf();
  
  sobel_filter DUT (.clk(intf.clk), .rst(intf.rst), .recv_data(intf.recv_data), .pixel(intf.pixel), .gradient(intf.gradient), .gradient_valid(intf.gradient_valid)
  );
  
  integer file;
  
  initial begin 
    intf.clk <= 1'b0;
  end
  
  always #10 intf.clk <= ~intf.clk;
  
  reg [`DATA_WIDTH-1:0] mem [0:`HEIGHT*`ROW_WIDTH-1];
  
  task reset();
    intf.rst <= 1'b1;
    intf.recv_data <= 1'b0;
    intf.pixel <= 0;
    repeat(10)@(posedge intf.clk);
    intf.rst <= 1'b0;
    $display("%0t: System Reseted", $time);
  endtask   
  
  function void store_data();
    $readmemh("image1.mem", mem);
    if(mem[0] !== 8'bx) begin
      $display("%0t Succesfully Stored Data in Memory", $time);
    end
    else begin
      $display("%0t Error in storing Data", $time);
    end
  endfunction
  
  task send_data();
    intf.recv_data <= 1'b1;
    //@(posedge intf.clk);
    for(int i = 0; i < `ROW_WIDTH*`HEIGHT - 1; i++) begin
      intf.pixel <= mem[i];
      @(posedge intf.clk);
    end
  endtask
  
  task write_data();
    file = $fopen("result.mem", "a");
    forever begin
      if(intf.gradient_valid) begin
		  $fdisplay(file, "%0h", intf.gradient);
      end
      if(DUT.row == `HEIGHT-1  && DUT.col == `ROW_WIDTH-1) begin
        $fclose(file);
        $finish(2);
      end
      @(posedge intf.clk);
    end
    
  endtask
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
  end
  
  initial begin
    reset();
    store_data();
    fork 
    	send_data();
    	write_data();
    join
    //$finish();
  end
  
endmodule
