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

module oneHotDecoder #(
	parameter int VALUES = 8
)(
	input  logic [VALUES-1:0] oneHotVector,
	output logic [max($clog2(VALUES)-1, 0):0] binary
);
	
	always_comb begin : decoder
		binary = '0;
	
		for(int i=0; i<VALUES; ++i) begin
			if(oneHotVector[i] == 1'b1) begin
				binary |= i; //ORing here, to avoid the generation of a priority decoder, since the system does not know it is a one hot vector
			end
		end
		
		//TODO: is Altera cookbooks method better? (see below)
		/*
		 * //Code taken from the altera cookbook:
		 * //baeckler - 11-14-2006
		 * 	for (j=0; j<BIN_WIDTH; j=j+1)
		 * begin : jl
		 * 		wire [ONEHOT_WIDTH-1:0] tmp_mask;
		 * 		for (i=0; i<ONEHOT_WIDTH; i=i+1)
		 * 		begin : il
		 * 			assign tmp_mask[i] = i[j];
		 * 		end	
		 * 		assign bin[j] = |(tmp_mask & onehot);
		 * end
		 */
	end
	
endmodule

