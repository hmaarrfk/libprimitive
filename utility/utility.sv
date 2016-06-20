package utility;
	//TODO: Have not found a way to make the following tip work... 
	//You should use the let statement instead of a function to handle values of any type.
	//let max(a,b) = (a > b) ? a : b;
	
	
	function int max(int a, int b);
	begin
		if(b>a) begin
			return b;
		end else begin
			return a;
		end
	end
	endfunction
endpackage
