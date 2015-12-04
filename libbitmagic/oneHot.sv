module oneHotDecoder #(
	parameter int VALUES = 8
)(
	input  logic [VALUES-1:0] oneHotVector,
	output logic [$clog2(VALUES)-1:0] binary
);
	
	always_comb begin : decoder
		binary = '0;
	
		for(int i=0; i<VALUES; ++i) begin
			if(oneHotVector[i] == 1'b1) begin
				binary |= i; //ORing here, to avoid the generation of a priority decoder, since the system does not know it is a one hot vector
			end
		end
	end
	
endmodule