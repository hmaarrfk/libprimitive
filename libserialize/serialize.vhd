-- Copyright 2014-2016 Malte Vesper
--
-- This file is part of libprimitive.
--
-- libprimitive is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- libprimitive is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with libprimitive.  If not, see <http://www.gnu.org/licenses/>.


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library xil_defaultlib;
use xil_defaultlib.tedUtility.all;

entity deserializer is
	/*generic(
		inputWidth : integer;
		outputWidth: integer
	);*/
	port(
		clk     : in  std_ulogic;
		rst     : in  std_ulogic;
		inValid : in  std_ulogic;
		inReady : out std_ulogic;
		dataIn  : in  std_ulogic_vector;
		outValid: out std_ulogic;
		outReady: in  std_ulogic;
		dataOut : out std_ulogic_vector
	);
end;

architecture behavioral of deserializer is
	constant WORDS: positive := ceilLd(dataOut'LENGTH/dataIn'Length);
	
	type deserializer_State_t is (RUNNING, WAIT_OUTPUT);
	
	signal count_reg  : unsigned(WORDS - 1 downto 0);
	signal count_cmb  : unsigned(WORDS - 1 downto 0);
	
	signal state_reg  : deserializer_State_t := RUNNING;
	signal state_cmb  : deserializer_State_t := RUNNING;
	
	signal shiftIn    : std_ulogic;
	
	signal valid_reg  : std_ulogic;
begin
	registers : process(all)
	begin
		if rising_edge(clk) then
			if rst then
				count_reg <= (others => '0');
				state_reg <= RUNNING;
				valid_reg <= '0';
			else
				count_reg <= count_cmb;
				state_reg <= state_cmb;
				valid_reg <= inValid;
			end if;
			
			if shiftIn then
				dataOut       <= dataOut(dataOut'LEFT-dataIn'LENGTH downto 0) & dataIn;
			end if;
		end if;
	end process;
	
	comb : process(all)
	begin
		state_cmb <= state_reg;
		count_cmb <= count_reg;
		
		shiftIn   <= '0';
		
		outValid  <= '0';
		inReady   <= '0';
		
		-- state could be replaced by count_reg == WORDS 
		case state_reg is
			when RUNNING =>
				inReady <= '1';
				
				if valid_reg then --inValid then
					shiftIn <= '1';
					
					count_cmb <= count_reg + 1;
					
					if count_reg = WORDS then
						state_cmb <= WAIT_OUTPUT;
					end if;
				end if;
			when WAIT_OUTPUT =>
				outValid <= '1';
				
				
				if outReady then
					count_cmb <= (others => '0');
					state_cmb <= RUNNING;
				end if;
		end case;		
	end process;
	
end architecture;