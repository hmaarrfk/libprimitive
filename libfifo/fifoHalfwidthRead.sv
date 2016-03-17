import fifoPkg::*;

typedef struct {
	logic empty;
	logic almostEmpty;
	logic full;
	logic almostFull;
	logic valid;
	logic halfvalid;
	logic wrap;
	logic circularHalfway;
} fillStatusHalfWidth;

interface fifoConnectHalfWidth #(
		parameter WIDTH = 32,
		parameter DEPTH = 32
	);

	localparam FILLBITS    = $clog2(DEPTH*2+1);

	logic [WIDTH-1:0] datain;
	logic [WIDTH-1:0] dataout;
	fillStatusHalfWidth fillStatus;
	//NOTE: if fill Level = 0, check full bit, to see if it is actually empty or
	// filled to the TOP. For integer power of 2: fillLevelActual = {full,
	// fillLevel}
	logic [FILLBITS-1:0] fillLevel;
	logic read;
	logic onlyReadHalf;
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
		input  onlyReadHalf,
		input  write
	);

	modport reader(
		output datain,
		input  dataout,
		input  fillStatus,
		input  fillLevel,
		output read,
		output onlyReadHalf,
		output write
	);
	
endinterface

module fifoHalfwidthRead # (
		parameter int WIDTH              = 32,
		parameter int DEPTH              = 32,
		parameter fifoOutputEnableFlags OUTPUTS = FIFO_VALID | FIFO_EMPTY | FIFO_ALMOST_EMPTY | FIFO_FULL | FIFO_ALMOST_FULL,
		parameter int TRIGGERALMOSTFULL  = 1, //generate full if X elements are free
		//generate almost empty if less than elements are there
		parameter int TRIGGERALMOSTEMPTY = 1,
		parameter logic FIRSTWORD_FALLTHROUGH = 1, //TODO: check the counter works for this
		parameter int CIRCULAR_HALFWAY   = DEPTH >> 1, //generate Halfway marker if more than this many entries have been read
		parameter logic OUTPUTHALFWORDATEND = 0 //Usually we put out the halfword we read in the lower bits, this moves it to the upper bits
	)(
		input logic clk,
		input logic reset,
		input logic circular,
		fifoConnectHalfWidth.core link
	);
	
	fifoConnect #(
		.WIDTH(WIDTH/2),
		.DEPTH(DEPTH)
	)
	frontFifo ();
	
	fifoConnect #(
		.WIDTH(WIDTH/2),
		.DEPTH(DEPTH)
	)
	backFifo ();
	
	fifo #(
		.WIDTH                (WIDTH/2),
		.DEPTH                (DEPTH),
		.OUTPUTS              (OUTPUTS),
		.TRIGGERALMOSTFULL    (TRIGGERALMOSTFULL),
		.TRIGGERALMOSTEMPTY   (TRIGGERALMOSTEMPTY),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY     (CIRCULAR_HALFWAY)
	)
	fifoFrontHalf (
		.clk     (clk),
		.reset   (reset),
		.circular(circular),
		.link    (frontFifo)
	);
	
	fifo #(
		.WIDTH                (WIDTH/2),
		.DEPTH                (DEPTH),
		.OUTPUTS              (OUTPUTS),
		.TRIGGERALMOSTFULL    (TRIGGERALMOSTFULL),
		.TRIGGERALMOSTEMPTY   (TRIGGERALMOSTEMPTY),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY     (CIRCULAR_HALFWAY)
	)
	fifoBackHalf (
		.clk     (clk),
		.reset   (reset),
		.circular(circular),
		.link    (backFifo)
	);

	localparam FILLBITS              = $clog2(DEPTH*2+1); //we count half fills + Zero

	logic halfWordRead_comb;
	logic halfWordRead_reg;
	
	logic [FILLBITS-1:0] fill_comb;
	logic [FILLBITS-1:0] fill_reg;
	
	always_ff @(posedge clk) begin : register
		if(reset) begin
			halfWordRead_reg <= 0;
			fill_reg    <= 0;
		end else begin
			halfWordRead_reg <= halfWordRead_comb;
			fill_reg    <= fill_comb;
		end
	end
	
	always_comb begin : fillCounter
		unique casez({link.read, link.onlyReadHalf, link.write, fill_reg < DEPTH*2-1, fill_reg != 0, fill_reg > 1})
			6'b0?0???:
				//Noop
				fill_comb = fill_reg;
			6'b100??1:
				//read
				fill_comb = fill_reg - 2;
			6'b110?1?:
				//Read half
				fill_comb = fill_reg - 1;
			6'b101???:
				//read & write
				fill_comb = fill_reg;
			6'b111???:
				//read half+write
				fill_comb = fill_reg + 1;
			6'b0?11??:
				//write
				fill_comb = fill_reg + 2;
			default:
				//read not enough data/write no space
				fill_comb = fill_reg;
		endcase
	end
	
	always_comb begin : crossbar
		logic crossBarSwitch;
		halfWordRead_comb = halfWordRead_reg ^ link.onlyReadHalf; //only if read?
		
		frontFifo.write = link.write;
		backFifo.write  = link.write;
		
		frontFifo.datain = link.datain[WIDTH/2-1:0];
		backFifo.datain  = link.datain[WIDTH-1:WIDTH/2];
		
		//Overestimate empty and full. Use fuller FIFO for status estimation, except valid
		link.fillStatus.empty       = backFifo.fillStatus.empty;
		link.fillStatus.almostEmpty = backFifo.fillStatus.almostEmpty;
		link.fillStatus.full        = backFifo.fillStatus.full;
		link.fillStatus.almostFull  = backFifo.fillStatus.almostFull;
		link.fillStatus.halfvalid   = backFifo.fillStatus.valid;
		
		link.fillStatus.valid       = frontFifo.fillStatus.valid;
		link.fillStatus.circularHalfway = frontFifo.fillStatus.circularHalfway;
		link.fillStatus.wrap        = frontFifo.fillStatus.wrap;
		
		link.fillLevel  = fill_reg;
		
		if(OUTPUTHALFWORDATEND) begin
			crossBarSwitch = halfWordRead_comb;
		end else begin
			crossBarSwitch = halfWordRead_reg;
		end
		
		if(!crossBarSwitch) begin
			//straight
			link.dataout = {backFifo.dataout, frontFifo.dataout};
		end else begin
			//crossover
			link.dataout = {frontFifo.dataout, backFifo.dataout};
		end
		
		if(!halfWordRead_reg) begin
			//straight
			frontFifo.read = link.read;
			backFifo.read  = link.read & !link.onlyReadHalf;
		end else begin
			//crossover
			frontFifo.read = link.read & !link.onlyReadHalf;
			backFifo.read  = link.read;
		end
	end

endmodule 
