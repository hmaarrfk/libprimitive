/*
Copyright 2014-2016 Malte Vesper

This file is part of libprimitive.

libprimitive is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

libprimitive is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with libprimitive.  If not, see <http://www.gnu.org/licenses/>.
*/

module testbench();
	
	reg clk;
	reg reset;
	
	reg circular;
	
	fifoConnect #(.DEPTH(4)) fifo();
	
	always  #5  clk = ~clk;
	
	initial begin
		clk = 1'b1;
		reset <= 1'b1;
		circular <= 1'b0;
		fifo.read   <= 1'b0;
		fifo.write  <= 1'b0;		
		#5;
		#10;
		reset <= 1'b0;
		#10;
		fifo.write  <= 1'b1;
		fifo.read  <= 1'b0;
		fifo.datain <= 32'b1001;
		#10;
		
		//fifo.write <= 1'b0;
		
		fifo.datain <= 32'b1;
		#10;
		fifo.write <= 0;
		#10;
		fifo.read <= 1;
		#30;
		
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
	fifo #(
		.DEPTH(4),
		.FIRSTWORD_FALLTHROUGH(1)
	) dut(
		.clk(clk),
		.reset(reset),
		.circular(circular),
		.link(fifo)
		);
	
	wire link;
endmodule