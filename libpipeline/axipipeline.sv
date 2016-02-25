interface axiPipelineConnect #(
	parameter int unsigned WIDTH = 32
);
	
logic [WIDTH-1:0] data;
logic valid;
logic ready;
	
modport source(
	output data,
	output valid,
	input  ready
);

modport pipeline(
	input data,
	input valid,
	output ready
);

endinterface

module aciPipeline #(
	parameter int unsigned STAGES = 1,
	parameter int unsigned WIDTH = 32
)(
	input logic clk,	
	input logic reset,
	axiPipelineConnect.pipeline source,
	axiPipelineConnect.source sink
);

axiPipelineConnect #(.WIDTH(WIDTH)) stageSource [STAGES]();
axiPipelineConnect #(.WIDTH(WIDTH)) stageSink [STAGES]();
	
assign sink.data  = stageSink[STAGES-1].data;
assign sink.valid = stageSink[STAGES-1].valid;
assign stageSink[STAGES-1].ready = sink.ready;
	
assign stageSource[0].data  = source.data;
assign stageSource[0].valid = source.valid;
assign source.ready = stageSource[0].ready;

generate
for(genvar i=0; i<STAGES; ++i) begin : stage
	axiPipelineStage #(
		.WIDTH(WIDTH)
	)
	u_pipelineStage (
		.clk   (clk),
		.reset (reset),
		.source(stageSource[0]),
		.sink  (stageSink[0])
	);
end
endgenerate

endmodule

module axiPipelineStage #(
	parameter int unsigned WIDTH = 32
)(
	input logic clk,	
	input logic reset,
	axiPipelineConnect.pipeline source,
	axiPipelineConnect.source sink
);

logic ready_comb;

logic valid_comb;
logic valid_reg;
	
logic [WIDTH-1:0] data_comb;
logic [WIDTH-1:0] data_reg;

assign sink.valid = valid_reg;
assign sink.data  = data_reg;

always_ff @(posedge clk) begin : register
	if(reset) begin
		valid_reg <= 0;
	end else begin
		valid_reg <= valid_comb;
	end
	
	data_reg     <= data_comb;
	source.ready <= ready_comb;
end

always_comb begin : pipelineLogic
	if(!valid_reg || sink.ready) begin
		valid_comb = source.valid;
		data_comb  = source.data;
		ready_comb = 1;
	end else begin
		valid_comb = valid_reg;
		data_comb  = data_reg;
		ready_comb = 0;
	end
end

endmodule