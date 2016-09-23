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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;
use IEEE.numeric_std.all;

/*
 */
package tedUtility is
	function to_std_logic(x: in boolean) return std_logic;
	/*
		Functions to manipulate occurrences of values
		
		leading					first occurrence of element
		count					occurences of std_logic value in vector
		
		repeat					repeats a value n-times
		truncate				returns n last bits ("trunk")
		
		ceilLd					returns the ceil of log2
		floorLd					returns the floor of log2
	 */
	function leading(x: in std_logic_vector; t: in std_logic) return natural;
	function nthOf(x: in std_logic_vector; n: in positive; t: in std_logic) return natural;
	--TODO: add trailing (do reverse and leading? or pass the range to be iteratet as an additional parameter to a helper funciton and pass 'RANGE or 'REVERSED_RANGE)
	function count(x: in std_logic_vector; t: in std_logic) return natural;
	function repeat(t: in std_logic; n: in integer) return std_logic_vector;
	
	function slice(x: in std_logic_vector; step: in integer:=1; start: in integer:=-1; stop: in integer:=-1) return std_logic_vector;
	function truncate(x: in std_logic_vector; length: in integer) return std_logic_vector;
	function combine(x: in std_logic_vector; y: in std_logic_vector; bitsFromX: in natural) return std_logic_vector;
	
	function ceilLd(x: in unsigned) return natural;
	function ceilLd(x: in natural) return natural;
	/*
		Logical operators as functions for use in generics.
	 */
	function f_equal(x: in std_logic_vector; y: in std_logic_vector) return std_logic;
	function f_lt   (x: in std_logic_vector; y: in std_logic_vector) return std_logic;
	function f_leq  (x: in std_logic_vector; y: in std_logic_vector) return std_logic;
	function f_gt   (x: in std_logic_vector; y: in std_logic_vector) return std_logic;
	function f_geq  (x: in std_logic_vector; y: in std_logic_vector) return std_logic;
	
	/*
		Bitvector (std_logic_vector) manipulation.
	 */
	function tristate(x: in std_logic_vector; en: in std_ulogic) return std_logic_vector;
	function reverse(x:  in std_logic_vector) return std_logic_vector;
end package tedUtility;

package body tedUtility is
	/*
	 * BEGIN PACKAGE INTERNAL HELPER FUNCTIONS.
	 */
	/*
	 Calculates actual start index for a virtual start index.
	 
	 If start is -1, start is set to the left element(beginning), if it is another negative number
	 it is set to the right element(end). Otherwise it is adjusted to the nth element from the left.
	 */
	function UTIL_vec_start(vec: in std_logic_vector; start: in integer)
	return integer is
	begin
		if start=-1 then
			return vec'LEFT;
		elsif start<0 then
			return vec'RIGHT;
		else
			if vec'ASCENDING then
				return vec'LEFT+start;
			else
				return vec'LEFT-start;
			end if;
		end if;
	end;
	
	/*
	 Calculates actual stop index for a virtual stop index.
	 
	 If stop is -1, stop is set to the right element(end), if it is another negative number
	 it is set to the left element(start). Otherwise it is adjusted to the nth element from the left.
	 */
	function UTIL_vec_stop(vec: in std_logic_vector; stop: in integer)
	return integer is
	begin
		if stop=-1 then
			return vec'RIGHT;
		elsif stop<0 then
			return vec'LEFT;
		else
			if vec'ASCENDING then
				return vec'LEFT+stop;
			else
				return vec'LEFT-stop;
			end if;
		end if;
	end;
	/*
	 * END PACKAGE INTERNAL HELPER FUNCTIONS.
	 */
	/*
	 Boolean to std_logic conversion.
	 */
	function to_std_logic(x: in boolean)
	return std_logic is
	begin
		if x then
			return '1';
		else
			return '0';
		end if;
	end function;
	/*
	 position of the first occurrence of the value t in x.
	 
	 Starts counting at 1, 0 means there is no occurrence.
	 for vhdl 2008 use find_leftmost/find_rightmost from IEEE.numeric_std_unsigned
	*/
	function leading(x: in std_logic_vector; t: in std_logic)
	return natural is
	begin
		return nthOf(x, 1, t);
	end;
	
	/*
	 Returns the position of the nth occurrence of t in x from the left.
	 
	 Starts counting at 1, 0 means no occurrences
	 */
	 --TODO: shift this to -1 for not found and start counting at 0.
	function nthOf(x: in std_logic_vector; n: in positive; t: in std_logic)
	return natural is
		variable occurrences : natural := 0;
		--variable pos         : natural := 0;
	begin
		for i in x'RANGE loop
			if x(i) = t then
				occurrences := occurrences+1;
				
				if occurrences=n then
					if x'LEFT > x'RIGHT then
						return x'LEFT - i+1;
					else
						return i - x'LEFT+1;
					end if;
				end if;
			end if;
		end loop;
		--return pos;
		return 0; 
	end;
	
	/*
	 Returns the number of occurances of t in x.
	 */
	function count(x: in std_logic_vector; t: in std_logic)
	return natural is
		variable result : natural := 0;
	begin
		for i in x'RANGE loop
			if x(i) = t then
				result := result + 1;
			end if;
		end loop;
		
		return result;
	end;
	
	/*
	 Returns an Vector of length n with all elements set to t.
	 */
	function repeat(t: in std_logic; n: in integer)
	return std_logic_vector is
		variable vec   : std_logic_vector(n-1 downto 0);
	begin
		vec := (others  => t);
		return vec;
	end;
	
	/*
	 Returns a slice, similar to python slice.
	 
	 Returns every <step>-th element of <x>, starting from <start> and stoping
	 on or before <stop>.
	 */
	function slice(x: in std_logic_vector; step: in integer:=1; start: in integer:=-1; stop: in integer:=-1)
	return std_logic_vector is
		constant r_start : integer := UTIL_vec_start(x, start);
		constant r_stop  : integer := UTIL_vec_start(x, stop);
		constant length  : natural := abs(r_start-r_stop)+1;
		variable result  : std_logic_vector(0 to length/step-1);
	begin
		if step = 0 then  -- this case will fail in the length/step array constraining for result anyways ...
			assert false report "Step should never be 0 for ""slice""" severity ERROR;
		end if;
		
		if start < stop then
			assert step > 0 report "Step should be greater 0 if start < stop." severity ERROR;
		end if;
		
		if start > stop then
			assert step < 0 report "Step should be smaller 0 if start > stop." severity ERROR;
		end if;
		
		for i in 0 to length/step-1 loop
			result(i) := x(r_start+i*step);
		end loop;
		return result;
	end;
	
	/*
	 Returns the last length bits of x.
	 */
	function truncate(x: in std_logic_vector; length: in integer)
	return std_logic_vector is
		variable result : std_logic_vector(length-1 downto 0);
	begin
		result := x(length-1 downto 0);
		return result;
	end;
	
	/*
	 Combines two signals by taking bitsFromX bits from x and the rest from y.
	 
	 x vector 1 to combine
	 y vector 2 to combine, must be of same length as x
	 bitsFromX number of bits taken from x
	 */
	function combine(x: in std_logic_vector; y: in std_logic_vector; bitsFromX: in natural)
	return std_logic_vector is
		variable result : std_logic_vector(x'RANGE);
	begin
	    --we have to ignore this for simulation in xilinx's vivado....
		--assert x'LENGTH= y'LENGTH report "Attempt to combine different length vectors" & lf & "X: " & to_string(x'LENGTH) & "Y: " & to_string(y'LENGTH);
		result(x'LEFT downto x'LEFT-bitsFromX+1) := x(x'LEFT downto x'LEFT-bitsFromX+1);
		result(y'LEFT-bitsFromX downto y'RIGHT)  := y(y'LEFT-bitsFromX downto y'RIGHT);
		return result;
	end;
	
	/*
	 Returns ceil(log2(x)).
	 */
	function ceilLd(x: in unsigned)
	return natural is
	begin
		if count(std_logic_vector(x), '1')=0 then
			return 0;
		elsif count(std_logic_vector(x), '1')=1 then
			return x'LENGTH-leading(std_logic_vector(x), '1');
		else
			return x'LENGTH-leading(std_logic_vector(x), '1')+1;
		end if;
	end;
	
	/*
	 Returns ceil(log2(x)).
	 */
	function ceilLd(x: in natural)
	return natural is
	begin
		return ceilLd(to_unsigned(x, integer(ceil(log2(real(x+1))))));
	end;
	
	
	function f_equal(x: in std_logic_vector; y: in std_logic_vector)
	return std_logic is
	begin
		return to_std_logic(x=y);
	end;
	
	function f_lt(x: in std_logic_vector; y: in std_logic_vector)
	return std_logic is
	begin
		return to_std_logic(x<y);
	end;
	
	function f_leq(x: in std_logic_vector; y: in std_logic_vector)
	return std_logic is
	begin
		return to_std_logic(x<=y);
	end;
	
	function f_gt(x: in std_logic_vector; y: in std_logic_vector)
	return std_logic is
	begin
		return to_std_logic(x>y);
	end;
	
	function f_geq(x: in std_logic_vector; y: in std_logic_vector)
	return std_logic is
	begin
		return to_std_logic(x>=y);
	end;
	
	/*
		Makes a tristate output.
		
		If enable is high the data is put out, otherwise high Z is applied.
		
		@param x         input vector
		@param en        weather the output is enabled
	 */
	function tristate(x: in std_logic_vector; en: in std_ulogic)
	return std_logic_vector is
	begin
		if en then
			return x;
		else
			return repeat('Z', x'LENGTH);
		end if;
	end;
	
	/*
	 */
	function reverse(x:  in std_logic_vector)
	return std_logic_vector is
		variable result : std_logic_vector(x'REVERSE_RANGE);
	begin
		for i in x'RANGE loop
			result(i) := x(i);
		end loop;
		
		return result;
	end;
end package body tedUtility;