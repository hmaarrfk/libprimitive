`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.09.2015 11:55:47
// Design Name: 
// Module Name: TEST_leadingBits
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TEST_leadingBits(
	input  logic [0:11] testVector,
	output logic  [3:0] leadCount
);
	
	leadingBits #(
		.BIT(1'b1),
		.WIDTH(12)
	) leadingOnes (
		.vector(testVector),
		.leadingCount(leadCount)
	);
	
endmodule
