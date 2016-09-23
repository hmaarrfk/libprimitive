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

`timescale 1ns / 1ps

module TEST_leadingBits(
	input  logic [0:11] testVector,
	output logic  [3:0] leadCount
);
	
	leadingBits #(
		.BIT(1'b1),
		.WIDTH(12)
	) leadingOnes (
		.vector(testVector),
		.leadingCount(leadCount)
	);
	
endmodule
