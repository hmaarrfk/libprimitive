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

module fifoByteEnable # (
	parameter int BYTES              = 32,
	parameter int DEPTH              = 32,
	parameter fifoOutputEnableFlags OUTPUTS = FIFO_VALID | FIFO_EMPTY | FIFO_ALMOST_EMPTY | FIFO_FULL | FIFO_ALMOST_FULL,
	parameter int TRIGGERALMOSTFULL  = 1, //generate full if X elements are free
	//generate almost empty if less than elements are there
	parameter int TRIGGERALMOSTEMPTY = 1,
	parameter logic FIRSTWORD_FALLTHROUGH = 1,
	parameter int CIRCULAR_HALFWAY   = DEPTH >> 1, //generate Halfway marker if more than this many entries have been read.
	parameter int BYTEWIDTH = 8
)(
	input logic clk,
	input logic reset,
	input logic circular,
	fifoConnect.core link
);

	fifoConnect #(
		.WIDTH(BYTEWIDTH),
		.DEPTH(DEPTH),
		.PARTS(1)
	)
	masterConnector ();
	
	assign masterConnector.datain      = link.datain[BYTEWIDTH-1:0];
	assign masterConnector.read        = link.read[0];
	assign masterConnector.write       = link.write[0];
	
	assign link.dataout[BYTEWIDTH-1:0] = masterConnector.dataout;
	assign link.fillLevel              = masterConnector.fillLevel;
	assign link.fillStatus             = masterConnector.fillStatus;

	fifo #(
		.WIDTH                (BYTEWIDTH),
		.DEPTH                (DEPTH),
		.OUTPUTS              (OUTPUTS),
		.TRIGGERALMOSTFULL    (TRIGGERALMOSTFULL),
		.TRIGGERALMOSTEMPTY   (TRIGGERALMOSTEMPTY),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY     (CIRCULAR_HALFWAY)
	)
	masterFifo (
		.clk     (clk),
		.reset   (reset),
		.circular(circular),
		.link    (masterConnector)
	);

for(genvar i=1; i<BYTES; i++) begin : subfifos
	fifoConnect #(
		.WIDTH(BYTEWIDTH),
		.DEPTH(DEPTH),
		.PARTS(1)
	)
	connector ();
	
	assign connector.datain = link.datain[BYTEWIDTH*(i+1)-1:BYTEWIDTH*i];
	assign connector.write  = link.write[i];
	assign connector.read   = link.read[i];
	
	assign link.dataout[BYTEWIDTH*(i+1)-1:BYTEWIDTH*i] = connector.dataout;
	
	fifo #(
		.WIDTH                (BYTEWIDTH),
		.DEPTH                (DEPTH),
		.OUTPUTS              (FIFO_NONE),
		.TRIGGERALMOSTFULL    (0),
		.TRIGGERALMOSTEMPTY   (0),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY     (0)
	)
	subFifo (
		.clk     (clk),
		.reset   (reset),
		.circular(circular),
		.link    (connector)
	);
end

endmodule