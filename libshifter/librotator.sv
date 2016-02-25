function int max(int a, int b);
begin
	if(b>a) begin
		return b;
	end else begin
		return a;
	end
end
endfunction

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
			shifterStage[i+1] = {shifterStage[i][(2**i)*SHIFTBITS_PER_STEP-1:0], shifterStage[i][WIDEST_PORT-1:(2**i)*SHIFTBITS_PER_STEP]};
		end else begin
			shifterStage[i+1] = shifterStage[i];
		end
	end
end

endmodule