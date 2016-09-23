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

module reverse #(
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [WIDTH-1:0] reversed
);

always_comb begin
	for(int i=0; i<WIDTH; i=i+1) begin
		reversed[i] = vector[WIDTH-1-i];
	end
end
	
endmodule

// Assuming the vector has downto notation, that means $left(vector) > $right(vector), i.e. logic [5:0].
module leadingBits #(
	parameter BIT = 1'b1,
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [$clog2(WIDTH)-1:0] leadingCount
);

always_comb begin
	leadingCount=0;
	
	for(int i=0; i<=$left(vector); i=i+$increment(vector)) begin
		if(vector[i+:1]==BIT) begin
			leadingCount = leadingCount + 1;
		end else begin
			leadingCount = 0;
		end
	end
end

endmodule

module leadingOnes #(
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [$clog2(WIDTH)-1:0] leadingCount
);

leadingBits #(
	.BIT(1'b1),
	.WIDTH(WIDTH)
) detector (
	.vector(vector),
	.leadingCount(leadingCount)
);

endmodule

module leadingZeros #(
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [$clog2(WIDTH)-1:0] leadingCount
);

leadingBits #(
	.BIT(1'b0),
	.WIDTH(WIDTH)
) detector (
	.vector(vector),
	.leadingCount(leadingCount)
);

endmodule

module trailingOnes #(
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [$clog2(WIDTH)-1:0] trailingCount
);

logic [WIDTH-1:0] reversed;

reverse #(
	.WIDTH(WIDTH)
) reverso (
	.vector(vector),
	.reversed(reversed)
);

leadingBits #(
	.BIT(1'b1),
	.WIDTH(WIDTH)
) detector (
	.vector(reversed),
	.leadingCount(trailingCount)
);

endmodule

module trailingZeros #(
	parameter WIDTH
)(
	input  logic [WIDTH-1:0] vector,
	output logic [$clog2(WIDTH)-1:0] trailingCount
);

logic [WIDTH-1:0] reversed;

reverse #(
	.WIDTH(WIDTH)
) reverso (
	.vector(vector),
	.reversed(reversed)
);

leadingBits #(
	.BIT(1'b0),
	.WIDTH(WIDTH)
) detector (
	.vector(reversed),
	.leadingCount(trailingCount)
);

endmodule