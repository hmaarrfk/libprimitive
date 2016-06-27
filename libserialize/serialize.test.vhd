library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.tedUtility.all;
use work.serialization.deserializer;

entity wayTestbench is
end entity;

architecture testbench of wayTestbench is
	constant period : time     := 20 ns;
	constant inwidth: positive := 4;
	constant outwidth: positive := 12;
	constant testvectors: positive := 6;
	
	signal clk      : std_ulogic;
	signal rst      : std_ulogic;
	signal inValid  : std_ulogic;
	signal inReady  : std_ulogic;
	signal dataIn   : std_ulogic_vector(inwidth-1 downto 0);
	signal outValid : std_ulogic;
	signal outReady : std_ulogic;
	signal dataOut  : std_ulogic_vector(outwidth-1 downto 0);
	
	type memory_t  is array (natural range <>) of std_ulogic_vector(inwidth-1 downto 0);
	signal memoryData        : memory_t(0 to testvectors-1);
begin
	u_deserializer : COMPONENT deserializer
		PORT MAP (
			clk      => clk,
			rst      => rst,
			inValid  => inValid,
			inReady  => inReady,
			dataIn   => dataIn,
			outValid => outValid,
			outReady => outReady,
			dataOut  => dataOut
		);
	
	clk_driver : process
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process;
	
	test: process
	begin
		--initialize
		rst      <= '1';
		inValid  <= '0';
		dataIn   <= std_ulogic_vector(to_unsigned(0, inwidth));
		outReady <= '0';
		
		for i in memoryData'RANGE loop
			memoryData(i) <= std_logic_vector(to_unsigned(i, inwidth));
		end loop;
		
		-- offset our changing of signals slightly from edge
		wait for period / 4;
		
		wait for period;
		
		rst <= '0';
		inValid <= '1';
		
		for i in memoryData'RANGE loop
			dataIn    <= memoryData(i);
			
			wait for period;
		end loop;
			
		wait for period/2;
		
		assert dataOut = memoryData(memoryData'RIGHT) report "data lost from cache, or valid BIT writethrough not working";
		wait;
	end process;
end architecture;