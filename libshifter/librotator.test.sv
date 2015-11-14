`timescale 1ns/1ns

parameter int INPUTWIDTH = 32;
parameter int OUTPUTWIDTH = 64;
parameter int SHIFTBITS_PER_STEP = 8;


module dut(
	logic [INPUTWIDTH-1:0] in,
	logic [OUTPUTWIDTH-1:0] out,
	logic [$clog2($ceil(OUTPUTWIDTH/SHIFTBITS_PER_STEP))-1:0] rotation
);
	rotatorConnect #(
		.INPUTWIDTH        (INPUTWIDTH),
		.OUTPUTWIDTH       (OUTPUTWIDTH),
		.SHIFTBITS_PER_STEP(SHIFTBITS_PER_STEP)
	) rotatorConnector ();
	
	assign rotatorConnector.dataIn = 'haa5533f0;//in;
	
	
	assign out = rotatorConnector.dataOut;
	
	initial begin
		for(int i=0; i<8; i++) begin
			rotatorConnector.rotationRight = i;
			#1;
		end
	end
	
	barrelShifterRight #(
		.INPUTWIDTH        (INPUTWIDTH),
		.OUTPUTWIDTH       (OUTPUTWIDTH),
		.SHIFTBITS_PER_STEP(SHIFTBITS_PER_STEP)
	) rotatorU (
		.link(rotatorConnector)
	);
endmodule