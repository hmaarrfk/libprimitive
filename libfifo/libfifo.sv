`timescale 1ns/1ns 

typedef struct {
	logic empty;
	logic almostEmpty;
	logic full;
	logic almostFull;
	logic valid;
} fillStatus;

interface fifoConnect #(
		parameter WIDTH = 32,
		parameter DEPTH = 32
	);

	localparam ADDRESSBITS = $clog2(DEPTH);
	localparam FILLBITS    = $clog2(DEPTH+1);

	logic [WIDTH-1:0] datain;
	logic [WIDTH-1:0] dataout;
	fillStatus fillStatus;
	//NOTE: if fill Level = 0, check full bit, to see if it is actually empty or
	// filled to the TOP. For integer power of 2: fillLevelActual = {full,
	// fillLevel}
	logic [FILLBITS-1:0] fillLevel;
	logic read;
	logic write;
	
	task idle();
		datain = 0;
		read = 0;
		write = 0;
	endtask

	modport core(
		input  datain,
		output dataout,
		output fillStatus,
		output fillLevel,
		input  read,
		input  write
	);

	modport reader(
		output datain,
		input  dataout,
		input  fillStatus,
		input  fillLevel,
		output read,
		output write
	);
	
endinterface

typedef logic [4:0] fifoOutputEnableFlags;
enum fifoOutputEnableFlags { FIFO_NONE = 5'b00000, FIFO_VALID = 5'b00001, FIFO_EMPTY = 5'b00010, FIFO_ALMOST_EMPTY = 5'b00100, FIFO_FULL = 5'b01000, FIFO_ALMOST_FULL = 5'b10000} fifoOutputEnableFlags_constants;

//TODO: support non power of two: i.e. counters have to wrap.
module fifo # (
		parameter int WIDTH              = 32,
		parameter int DEPTH              = 32,
		parameter fifoOutputEnableFlags OUTPUTS = FIFO_VALID | FIFO_EMPTY | FIFO_ALMOST_EMPTY | FIFO_FULL | FIFO_ALMOST_FULL,
		parameter int TRIGGERALMOSTFULL  = 1, //generate full if X elements are free
		//generate almost empty if less than elements are there
		parameter int TRIGGERALMOSTEMPTY = 1,
		parameter logic FIRSTWORD_FALLTHROUGH = 1 //TODO: check the counter works for this
	)(
		input logic clk,
		input logic reset,
		input logic circular,
		fifoConnect.core link
	);

	localparam DEPTHBITS             = $clog2(DEPTH);
	localparam FILLBITS              = $clog2(DEPTH+1);

	logic [WIDTH-1:0] memory[DEPTH-1:0];

	logic [FILLBITS-1:0] fill_comb;
	logic [FILLBITS-1:0] fill_reg;

	//endIndex, points behind the end
	logic [DEPTHBITS-1:0] endIndex_comb;
	logic [DEPTHBITS-1:0] endIndex_reg;
	logic [DEPTHBITS-1:0] beginIndex_comb;
	logic [DEPTHBITS-1:0] beginIndex_reg;
	logic [DEPTHBITS-1:0] current_comb;
	logic [DEPTHBITS-1:0] current_reg;

	assign link.fillLevel = fill_reg;
	
	//TODO: add 0 size fifo?

	always_comb begin : UPDATE_FILL
		fill_comb = fill_reg;
		//FIXME: do we fuck ourselves if we have fallthrough? i.e. we increase the count and it stays up. => we read a stale value twice.
		if(link.read && link.write && fill_reg) begin
		end else if(link.write && fill_reg != DEPTH) begin
			fill_comb = fill_reg + 1;
		end else if(link.read && fill_reg != 0 && !circular) begin
			fill_comb = fill_reg - 1;
		end
		
		//TODO: overwrite fill_comb with reset here? => would allow us to simblify the valid/full/almost_full/... generation by combine general and reset case there...
	end

	always_comb begin : READ
		beginIndex_comb = beginIndex_reg;
		current_comb    = current_reg;
		
		if(link.read && fill_reg && !reset) begin
			current_comb      = current_reg + 1;
			
			if(circular) begin
				if(current_reg+1 == endIndex_reg) begin
					current_comb = beginIndex_reg;
				end
			end else begin
				beginIndex_comb = beginIndex_reg + 1;
			end
			
		end
	end

	always_comb begin : WRITE
		if(link.write && fill_reg != DEPTH) begin //TODO protect against overwriting indexes?
			endIndex_comb        = endIndex_reg + 1;
		end else begin
			endIndex_comb        = endIndex_reg;
		end
	end

	always_ff @(posedge clk) begin : REGISTERS
		if(reset) begin
			endIndex_reg          <= 0;
			beginIndex_reg        <= 0;
			current_reg           <= 0;
			fill_reg              <= 0;
		end else begin
			if(link.write) begin
				memory[endIndex_reg] <= link.datain;
			end
			
			endIndex_reg   <= endIndex_comb;
			beginIndex_reg <= beginIndex_comb;
			fill_reg       <= fill_comb;
			current_reg    <= current_comb;
		end
	end
	
	generate if(DEPTH>1) begin
		always_ff @(posedge clk) begin : DATAOUT_REGISTER
			if(fill_reg[$left(fill_reg):1]==0 && (!fill_reg[0] || link.read) && FIRSTWORD_FALLTHROUGH) begin //first word fall through
				link.dataout <= link.datain;
			end else begin
				link.dataout <= memory[current_comb];
			end
		end
	end else begin
		always_ff @(posedge clk) begin : DATAOUT_REGISTER
			if((!fill_reg[0] || link.read) && FIRSTWORD_FALLTHROUGH) begin //first word fall through
				link.dataout <= link.datain;
			end else begin
				link.dataout <= memory[current_comb];
			end
		end
	end
	endgenerate
	
	generate if(OUTPUTS & FIFO_VALID) begin
		always_ff @(posedge clk) begin : VALID
			if(reset) begin
				link.fillStatus.valid <= 0;
			end else begin
				link.fillStatus.valid <= fill_comb || link.write;
			end
		end
	end else begin
		assign link.fillStatus.valid = 0;
	end
	endgenerate
	
	generate if(OUTPUTS & FIFO_EMPTY) begin
		always_ff @(posedge clk) begin : EMPTY
			if(reset) begin
				link.fillStatus.empty <= 1;
			end else begin
				link.fillStatus.empty <= fill_comb == 0;
			end
		end
	end else begin
		assign link.fillStatus.empty = 0;
	end
	endgenerate

	generate if(OUTPUTS & FIFO_ALMOST_EMPTY) begin
		always_ff @(posedge clk) begin : ALMOST_EMPTY
			if(reset) begin
				link.fillStatus.almostEmpty <= 0 <= TRIGGERALMOSTEMPTY;
			end else begin
				link.fillStatus.almostEmpty <= fill_comb <= TRIGGERALMOSTEMPTY;
			end
		end
	end else begin
		assign link.fillStatus.almostEmpty = 0;
	end
	endgenerate
	
	generate if(OUTPUTS & FIFO_FULL) begin
		always_ff @(posedge clk) begin : FULL
			if(reset) begin
				link.fillStatus.full <= 0;
			end else begin
				link.fillStatus.full <= fill_comb == DEPTH;
			end
		end
	end else begin
		assign link.fillStatus.full = 0;
	end
	endgenerate

	generate if(OUTPUTS & FIFO_ALMOST_FULL) begin
		always_ff @(posedge clk) begin : ALMOST_FULL
			if(reset) begin
				link.fillStatus.almostFull <= 0 >= DEPTH-TRIGGERALMOSTFULL;
			end else begin
				link.fillStatus.almostFull <= fill_comb >= DEPTH-TRIGGERALMOSTFULL;
			end
		end
	end else begin
		assign link.fillStatus.almostFull = 0;
	end
	endgenerate

endmodule
