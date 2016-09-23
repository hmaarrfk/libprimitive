/*
Copyright 2014-2016 Malte Vesper

This file is part of libprimitive.

libprimitive is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

libprimitive is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with libprimitive.  If not, see <http://www.gnu.org/licenses/>.
*/

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
