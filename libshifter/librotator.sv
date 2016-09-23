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

import utility::max;

interface rotatorConnect #(
	parameter int INPUTWIDTH  = 32,
	parameter int OUTPUTWIDTH = INPUTWIDTH,
	parameter int SHIFTBITS_PER_STEP = 1
);

	localparam WIDEST_PORT = max(OUTPUTWIDTH, INPUTWIDTH);

	logic [INPUTWIDTH-1:0]  dataIn;
	logic [OUTPUTWIDTH-1:0] dataOut;
	logic [$clog2(WIDEST_PORT/SHIFTBITS_PER_STEP)-1:0] rotationRight;

	modport core (
		input  rotationRight,
		input  dataIn,
		output dataOut
		);
endinterface

module barrelShifterRight #(
	parameter int INPUTWIDTH = 32,
	parameter int OUTPUTWIDTH = INPUTWIDTH,
	parameter int SHIFTBITS_PER_STEP = 1,
	parameter logic OUTPUT_REGISTER = 0
)(
	input logic clk,
	rotatorConnect.core link
);

localparam WIDEST_PORT = max(OUTPUTWIDTH, INPUTWIDTH);
localparam PARTS       = WIDEST_PORT/SHIFTBITS_PER_STEP;
localparam STAGES      = $clog2(WIDEST_PORT/SHIFTBITS_PER_STEP);

logic [WIDEST_PORT-1:0] shifterStage [STAGES:0];

assign shifterStage[0] = link.dataIn;
	
generate
if(OUTPUT_REGISTER) begin
	logic [OUTPUTWIDTH-1:0]  dataOut_reg;
	
	always_ff @(posedge clk) begin : outputRegister
		dataOut_reg <= shifterStage[STAGES];
	end
	
	assign link.dataOut    = dataOut_reg;
end else begin
	assign link.dataOut    = shifterStage[STAGES];
end
endgenerate

for(genvar i=0; i<STAGES; ++i) begin
	always_comb begin : shifterStageComb
		if(link.rotationRight[i]) begin
			//TODO make direction a parameter
			shifterStage[i+1] = {shifterStage[i][(2**i)*SHIFTBITS_PER_STEP-1:0], shifterStage[i][WIDEST_PORT-1:(2**i)*SHIFTBITS_PER_STEP]};
			//shifterStage[i+1] = {shifterStage[i][(PARTS-(2**i))*SHIFTBITS_PER_STEP-1:0], shifterStage[i][WIDEST_PORT-1:(PARTS-(2**i))*SHIFTBITS_PER_STEP]};
		end else begin
			shifterStage[i+1] = shifterStage[i];
		end
	end
end

endmodule