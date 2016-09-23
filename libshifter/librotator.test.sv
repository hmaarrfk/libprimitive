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

`timescale 1ns/1ns

parameter int INPUTWIDTH = 32;
parameter int OUTPUTWIDTH = 64;
parameter int SHIFTBITS_PER_STEP = 8;


module dut(
	logic [INPUTWIDTH-1:0] in,
	logic [OUTPUTWIDTH-1:0] out,
	logic [$clog2($ceil(OUTPUTWIDTH/SHIFTBITS_PER_STEP))-1:0] rotation
);
	rotatorConnect #(
		.INPUTWIDTH        (INPUTWIDTH),
		.OUTPUTWIDTH       (OUTPUTWIDTH),
		.SHIFTBITS_PER_STEP(SHIFTBITS_PER_STEP)
	) rotatorConnector ();
	
	assign rotatorConnector.dataIn = 'haa5533f0;//in;
	
	
	assign out = rotatorConnector.dataOut;
	
	initial begin
		for(int i=0; i<8; i++) begin
			rotatorConnector.rotationRight = i;
			#1;
		end
	end
	
	barrelShifterRight #(
		.INPUTWIDTH        (INPUTWIDTH),
		.OUTPUTWIDTH       (OUTPUTWIDTH),
		.SHIFTBITS_PER_STEP(SHIFTBITS_PER_STEP)
	) rotatorU (
		.link(rotatorConnector)
	);
endmodule