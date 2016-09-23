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

module pipeline #(
	parameter int unsigned WIDTH = 32,
	parameter int unsigned STAGES = 1,
	parameter logic RESET = 0
)(
	input logic clk,
	input logic reset,
	input logic [WIDTH-1:0] dataIn,
	output logic [WIDTH-1:0] dataOut
);

logic [WIDTH-1:0] dataRegister [STAGES:0]; 

assign dataRegister[0] = dataIn;
assign dataOut = dataRegister[STAGES];

generate
for(genvar i=0; i<STAGES; ++i) begin : pipelineStages
	if(RESET) begin
		always_ff @(posedge clk) begin : stage
			if(reset) begin
				dataRegister[i+1] <= '0;
			end else begin
				dataRegister[i+1] <= dataRegister[i];
			end
		end
	end else begin
		always_ff @(posedge clk) begin : stage
			dataRegister[i+1] <= dataRegister[i];
		end
	end
end
endgenerate

endmodule
