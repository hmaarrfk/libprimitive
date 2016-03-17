import fifoPkg::*;


module fifoHalfwidthRead_tb;

	localparam WIDTH = 6;
	localparam DEPTH = 32;
	localparam OUTPUTS = fifoPkg::FIFO_VALID|FIFO_EMPTY|FIFO_ALMOST_EMPTY|FIFO_FULL|FIFO_ALMOST_FULL;
	localparam TRIGGERALMOSTFULL = 1;
	localparam TRIGGERALMOSTEMPTY = 1;
	localparam FIRSTWORD_FALLTHROUGH = 1;
	localparam CIRCULAR_HALFWAY = DEPTH>>1;
	localparam OUTPUTHALFWORDATEND = 0;

	reg clk;
	reg reset;
	reg circular;
	fifoConnectHalfWidth #(.WIDTH(WIDTH), .DEPTH(DEPTH)) link();

	fifoHalfwidthRead #(
		.WIDTH(WIDTH),
		.DEPTH(DEPTH),
		.OUTPUTS(OUTPUTS),
		.TRIGGERALMOSTFULL(TRIGGERALMOSTFULL),
		.TRIGGERALMOSTEMPTY(TRIGGERALMOSTEMPTY),
		.FIRSTWORD_FALLTHROUGH(FIRSTWORD_FALLTHROUGH),
		.CIRCULAR_HALFWAY(CIRCULAR_HALFWAY),
		.OUTPUTHALFWORDATEND(OUTPUTHALFWORDATEND)
	) dut (
		.clk(clk),
		.reset(reset),
		.circular(circular),
		.link(link)
	);
	
	initial
	begin
		clk = 0;
		reset = 1;
		circular = 0;
		link.onlyReadHalf = 0;
		link.read = 0;
		link.write = 0;
		link.datain = '0;
		
		#8;
		reset = 0;
		
		link.write = 1;
		link.datain = 6'b101001;
		
		#10;
		link.datain = 6'b110010;
		
		#10;
		link.write =0;
		link.datain <= '0;
		link.read = 1;
		
		#10;
		link.onlyReadHalf = 1;
		
		#10;
		link.read=0;
		link.onlyReadHalf=0;
		link.datain = 6'b111011;
		link.write = 1;
		
		#10;
		link.write = 0;
		link.read = 1;
		link.onlyReadHalf =1;
		
		#10;
		link.read=0;
		link.onlyReadHalf = 0;
		
	end

	always
		#5 clk = ! clk;

endmodule

