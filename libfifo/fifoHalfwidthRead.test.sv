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

import fifoPkg::*;


module fifoHalfwidthRead_tb;

	localparam WIDTH = 6;
	localparam DEPTH = 32;
	localparam OUTPUTS = fifoPkg::FIFO_VALID|FIFO_EMPTY|FIFO_ALMOST_EMPTY|FIFO_FULL|FIFO_ALMOST_FULL;
	localparam TRIGGERALMOSTFULL = 1;
	localparam TRIGGERALMOSTEMPTY = 1;
	localparam FIRSTWORD_FALLTHROUGH = 1;
	localparam CIRCULAR_HALFWAY = DEPTH>>1;
	localparam OUTPUTHALFWORDATEND = 0;

	reg clk;
	reg reset;
	reg circular;
	fifoConnectHalfWidth #(.WIDTH(WIDTH), .DEPTH(DEPTH)) link();

	fifoHalfwidthRead #(
		.WIDTH(WIDTH),
		.DEPTH(DEPTH),
		.OUTPUTS(OUTPUTS),
		.TRIGGERALMOSTFULL(TRIGGERALMOSTFULL),
		.TRIGGERALMOSTEMPTY(TRIGGERALMOSTEMPTY),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY(CIRCULAR_HALFWAY),
		.OUTPUTHALFWORDATEND(OUTPUTHALFWORDATEND)
	) dut (
		.clk(clk),
		.reset(reset),
		.circular(circular),
		.link(link)
	);
	
	initial
	begin
		clk = 0;
		reset = 1;
		circular = 0;
		link.onlyReadHalf = 0;
		link.read = 0;
		link.write = 0;
		link.datain = '0;
		
		#8;
		reset = 0;
		
		link.write = 1;
		link.datain = 6'b101001;
		
		#10;
		link.datain = 6'b110010;
		
		#10;
		link.write =0;
		link.datain <= '0;
		link.read = 1;
		
		#10;
		link.onlyReadHalf = 1;
		
		#10;
		link.read=0;
		link.onlyReadHalf=0;
		link.datain = 6'b111011;
		link.write = 1;
		
		#10;
		link.write = 0;
		link.read = 1;
		link.onlyReadHalf =1;
		
		#10;
		link.read=0;
		link.onlyReadHalf = 0;
		
	end

	always
		#5 clk = ! clk;

endmodule

