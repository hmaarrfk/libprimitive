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

//TODO: support non power of two: i.e. counters have to wrap.
module fifo # (
		parameter WIDTH              = 32,
		parameter DEPTH              = 32,
		parameter TRIGGERALMOSTFULL  = 1, //generate full if X elements are free
		//generate almost empty if less than elements are there
		parameter TRIGGERALMOSTEMPTY = 1
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
	logic [FILLBITS-1:0] endIndex_comb;
	logic [FILLBITS-1:0] endIndex_reg;
	logic [FILLBITS-1:0] beginIndex_comb;
	logic [FILLBITS-1:0] beginIndex_reg;
	logic [FILLBITS-1:0] current_comb;
	logic [FILLBITS-1:0] current_reg;

	logic [WIDTH-1:0] readData;

	//UPDATE FILL
	always_comb begin : UPDATE_FILL
		fill_comb = fill_reg;
		
		if(link.read && link.write && fill_reg) begin
		end else if(link.write && fill_reg != DEPTH) begin
			fill_comb = fill_reg + 1;
		end else if(link.read && fill_reg != 0 && !circular) begin
			fill_comb = fill_reg - 1;
		end
	end

	//READ
/*	always @(posedge clk) begin
		if(link.read && fillReg && !reset) begin
			current      <= current + 1;
			
			if(circular) begin
				if(current+1 == endIndex) begin
					current <= beginIndex;
				end
			end else begin
				beginIndex <= beginIndex + 1;
			end
			
		end

		if(fillReg) begin
			link.dataout <= memory[current];
		end else begin
			link.dataout <= link.datain;
		end

	end
*/

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
		if(link.write) begin //TODO: fix synchronous read?/what if read is retracted: !(!fill_comb && link.read) && 
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
			
			link.fillStatus.empty       <= 1;
			link.fillStatus.full        <= 0;

			link.fillStatus.almostEmpty <= 0 <= TRIGGERALMOSTEMPTY;
			link.fillStatus.almostFull  <= 0 >= DEPTH-TRIGGERALMOSTFULL;
			
			link.fillLevel              <= 0;
			link.fillStatus.valid <= 0;
		end else begin
			if(link.write) begin
				memory[endIndex_reg] <= link.datain;
			end
			
			endIndex_reg   <= endIndex_comb;
			beginIndex_reg <= beginIndex_comb;
			fill_reg       <= fill_comb;
			current_reg    <= current_comb;
			
			link.fillStatus.empty       <= fill_comb == 0;
			link.fillStatus.full        <= fill_comb == DEPTH;

			link.fillStatus.almostEmpty <= fill_comb <= TRIGGERALMOSTEMPTY;
			link.fillStatus.almostFull  <= fill_comb >= DEPTH-TRIGGERALMOSTFULL;
			
			link.fillLevel              <= fill_comb;  //should be an alias of fill_reg
			link.fillStatus.valid <= | fill_comb || link.write;
		end
		
		if(fill_reg[$left(fill_reg):1]==0 && (!fill_reg[0] || link.read)) begin //first word fall through
			link.dataout <= link.datain;
		end else begin
			link.dataout <= memory[current_comb];
		end
	end

endmodule
