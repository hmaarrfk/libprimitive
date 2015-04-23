typedef struct {
	logic empty;
	logic almostEmpty;
	logic full;
	logic almostFull;
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
	localparam DEPTHISTRUEPOWEROFTWO = 1; //FIXME: this should be calculated
	localparam FILLBITS              = $clog2(DEPTH+1);

	reg [WIDTH-1:0] memory[DEPTH-1:0];

	logic [FILLBITS-1:0] fill;
	reg   [FILLBITS-1:0] fillReg;

	//endIndex, points behind the end
	logic [DEPTHBITS-(DEPTHISTRUEPOWEROFTWO!=0?1:0):0] endIndex;
	logic [DEPTHBITS-(DEPTHISTRUEPOWEROFTWO!=0?1:0):0] beginIndex;
	logic [DEPTHBITS-(DEPTHISTRUEPOWEROFTWO!=0?1:0):0] current;

	assign link.fillLevel            = fillReg;

	//RESET
	always @(posedge clk) begin
		if(reset) begin
			endIndex   <= 0;
			beginIndex <= 0;
			current    <= 0;
			fillReg    <= 0;
		end
	end

	//UPDATE FILL
	always @(posedge clk) begin
		if(!reset) begin
			fill = fillReg;
			if(link.read && link.write) begin
			end else if(link.read && fillReg != 0 && !circular) begin
				fill = fillReg - 1;
			end else if(link.write && fillReg != DEPTH) begin
				fill = fillReg + 1;
			end

			fillReg          <= fill;
			link.fillStatus.empty       <= fillReg == 0;
			link.fillStatus.full        <= fillReg == DEPTH;

			link.fillStatus.almostEmpty <= fillReg <= TRIGGERALMOSTEMPTY;
			link.fillStatus.almostFull  <= fillReg >= DEPTH-TRIGGERALMOSTFULL;
		end
	end

	//READ
	always @(posedge clk) begin
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

	//WRITE
	always @(posedge clk) begin
		if(link.write && !(!fill && link.read) && !reset) begin
			memory[endIndex] <= link.datain;
			endIndex         <= endIndex + 1;
		end
	end



endmodule
