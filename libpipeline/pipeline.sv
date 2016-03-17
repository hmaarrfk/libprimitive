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
