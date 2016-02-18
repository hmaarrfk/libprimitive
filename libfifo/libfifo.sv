`timescale 1ns/1ns 

typedef struct {
	logic empty;
	logic almostEmpty;
	logic full;
	logic almostFull;
	logic valid;
	logic wrap;
	logic circularHalfway;
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

typedef logic [6:0] fifoOutputEnableFlags;
enum fifoOutputEnableFlags { FIFO_NONE = 7'b0000000, FIFO_VALID = 7'b0000001, FIFO_EMPTY = 7'b0000010, FIFO_ALMOST_EMPTY = 7'b0000100, FIFO_FULL = 7'b0001000, FIFO_ALMOST_FULL = 7'b0010000, FIFO_WRAP_INDICATOR = 7'b0100000, FIFO_CIRCULAR_HALFWAY = 7'b1000000} fifoOutputEnableFlags_constants;

//TODO: support non power of two: i.e. counters have to wrap.
module fifo # (
		parameter int WIDTH              = 32,
		parameter int DEPTH              = 32,
		parameter fifoOutputEnableFlags OUTPUTS = FIFO_VALID | FIFO_EMPTY | FIFO_ALMOST_EMPTY | FIFO_FULL | FIFO_ALMOST_FULL,
		parameter int TRIGGERALMOSTFULL  = 1, //generate full if X elements are free
		//generate almost empty if less than elements are there
		parameter int TRIGGERALMOSTEMPTY = 1,
		parameter logic FIRSTWORD_FALLTHROUGH = 1, //TODO: check the counter works for this
		parameter int CIRCULAR_HALFWAY   = DEPTH >> 1 //generate Halfway marker if more than this many entries have been read
	)(
		input logic clk,
		input logic reset,
		input logic circular,
		fifoConnect.core link
	);

	localparam DEPTHBITS             = $clog2(DEPTH);
	localparam FILLBITS              = $clog2(DEPTH+1);

	logic [WIDTH-1:0] memoryRegister;    //for the special case of DEPTH==1 to suppress warnings
	logic [WIDTH-1:0] memory[DEPTH-1:0];

	logic [FILLBITS-1:0] fill_comb;
	logic [FILLBITS-1:0] fill_reg;

	//endIndex, points behind the end
	logic [DEPTHBITS-1:0] endIndex_comb;
	logic [DEPTHBITS-1:0] endIndex_reg;
	logic [DEPTHBITS-1:0] beginIndex_comb;
	logic [DEPTHBITS-1:0] beginIndex_reg;
	logic [DEPTHBITS-1:0] next_comb;
	logic [DEPTHBITS-1:0] next_reg;
	logic [DEPTHBITS-1:0] nextCorrected_comb;

	assign link.fillLevel = fill_reg;
	
	//TODO: add 0 size fifo?

	always_comb begin : UPDATE_FILL
		fill_comb = fill_reg;
		//FIXME: do we fuck ourselves if we have fallthrough? i.e. we increase the count and it stays up. => we read a stale value twice.
		if(link.write && (!link.read || circular) && fill_reg != DEPTH) begin
			fill_comb = fill_reg + 1;
		end else if(link.read && !link.write && fill_reg != 0 && !circular) begin
			fill_comb = fill_reg - 1;
		end
		
		//TODO: overwrite fill_comb with reset here? => would allow us to simblify the valid/full/almost_full/... generation by combine general and reset case there...
	end

	always_comb begin : READ
		beginIndex_comb = beginIndex_reg;
		
		if(link.read && (fill_reg || link.write) && !reset) begin
			
			if(!circular) begin
				beginIndex_comb = beginIndex_reg + 1;
			end
			
		end
		
		if(link.read && (fill_reg || link.write)) begin
			next_comb = next_reg + 1;
		end else begin
			next_comb = next_reg;
		end
		
		/*if(circular && next_comb == endIndex_reg) begin //write read might screw this over...
			next_comb = beginIndex_reg;
		end*/
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
			next_reg              <= 0;
			fill_reg              <= 0;
		end else begin
			if(link.write) begin
				if(DEPTH > 1) begin
					memory[endIndex_reg] <= link.datain;
				end else begin
					memoryRegister       <= link.datain;
				end
			end
			
			endIndex_reg   <= endIndex_comb;
			beginIndex_reg <= beginIndex_comb;
			next_reg       <= next_comb;
			fill_reg       <= fill_comb;
		end
	end
	
	generate if(DEPTH>1) begin
		always_ff @(posedge clk) begin : DATAOUT_REGISTER
			if(circular && next_reg == endIndex_reg) begin //write read might screw this over by one missed loop...
				nextCorrected_comb = beginIndex_reg;
			end else begin
				nextCorrected_comb = next_reg;
			end
			
			if(fill_reg[$left(fill_reg):1]==0 && (!fill_reg[0] || link.read) && FIRSTWORD_FALLTHROUGH) begin //first word fall through
				link.dataout <= link.datain;
			end else begin
				link.dataout <= memory[nextCorrected_comb];
			end
		end
	end else begin
		always_ff @(posedge clk) begin : DATAOUT_REGISTER
			if(link.read) begin
				if(!fill_reg && FIRSTWORD_FALLTHROUGH) begin //first word fall through
					link.dataout <= link.datain;
				end else begin
					link.dataout <= memoryRegister;
				end
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
	
	generate if(OUTPUTS & FIFO_WRAP_INDICATOR) begin
		always_ff @(posedge clk) begin : WRAP
			if(reset) begin
				link.fillStatus.wrap <= 0;
			end else begin
				link.fillStatus.wrap <= (circular && next_reg == endIndex_reg) || (!circular && next_reg == 0);
			end
		end
	end else begin
		assign link.fillStatus.wrap = 0;
	end
	endgenerate
	
	generate if(OUTPUTS & FIFO_CIRCULAR_HALFWAY) begin
		always_ff @(posedge clk) begin : WRAP
			if(reset) begin
				link.fillStatus.circularHalfway <= 0;
			end else begin
				link.fillStatus.circularHalfway <= nextCorrected_comb == beginIndex_reg + FIFO_CIRCULAR_HALFWAY;
			end
		end
	end else begin
		assign link.fillStatus.circularHalfway = 0;
	end
	endgenerate

endmodule
