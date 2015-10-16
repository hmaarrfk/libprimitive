module testbench();
	
	reg clk;
	reg reset;
	
	reg circular;
	
	fifoConnect fifo();
	
	always  #5  clk = ~clk;
	
	initial begin
		clk = 1'b1;
		reset <= 1'b1;
		circular <= 1'b0;
		fifo.read   <= 1'b0;
		fifo.write  <= 1'b0;		
		#1;
		#10;
		reset <= 1'b0;
		#10;
		fifo.write  <= 1'b1;
		fifo.read  <= 1'b1;
		fifo.datain <= 32'b1001;
		#10;
		fifo.datain <= 32'b1;
		#10;
		fifo.write  <= 1'b0;
		fifo.datain <= 32'b10;
		#10;
		fifo.read   <= 1'b1;
		fifo.datain <= 32'b11;
		#10;
		fifo.datain <= 32'b100;
		#10;
		fifo.datain <= 32'b101;
		#10;
		
		//Circular mode
		fifo.read   <= 1'b0;
		fifo.write  <= 1'b1;
		fifo.datain <= 32'b1010;
		#10;
		fifo.datain <= 32'b1110;
		#10;
		fifo.datain <= 32'b10001111111;
		#10;
		circular    <= 1'b1;
		fifo.write  <= 1'b0;
		fifo.read   <= 1'b1;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		fifo.write <= 1'b1;
		fifo.datain <= 32'b0;
		#10;
		fifo.write <= 1'b0;
		#60;
		
		$finish;
	end
	
	//fifo dut();
	fifo dut(
		.clk(clk),
		.reset(reset),
		.circular(circular),
		.link(fifo)
		);
	
	wire link;
endmodule