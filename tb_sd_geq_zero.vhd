library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;--for uniform random number generation
use work.all;
use work.signed_digit_pkg.all;-- MUST BE INCLUDED even though this package apperas under "work" library in modelsim
use ieee.std_logic_textio.all;--for reading of std_logic_vectors

entity testbench is
end testbench;

architecture test of testbench is
-- "Time" that will elapse between test vectors we submit to the component.
constant TIME_DELTA : time := 10 ns;

signal CLK: std_logic;
signal expected_output: std_logic;
signal error_flag: std_logic;

constant MAX_ITER: natural := 10;

signal  	A   : std_logic_vector(32 downto 0);--two's complement: 1 aditional bit because of simetric range
signal  	A_sd: sd_vector(31 downto 0);
signal	geq0: std_logic;

signal	A_p: std_logic_vector(31 downto 0);
signal	A_n: std_logic_vector(31 downto 0);

begin
	--convert inputs to SD numbers
	to_sd: for i in 31 downto 0 generate
		A_sd(i) <= A_p(i) & A_n(i);
	end generate;
	
	A <= ('0' & A_p) - ('0' & A_n);
--	expected_output <= '1' when (to_integer(signed(A)) >= 0) else '0';
	expected_output <= not A(32); --just checking the sign bit
 
	DUT: entity work.sd_geq_zero
	generic map (N => 32)
	port map(A 		=> A_sd,
				S		=> geq0
	);
	
	-----------------------------------------------------------
	--	this process creates a test case,
	--	pass it to the DUT, perform addition
	-----------------------------------------------------------
	process--parses input text file
		variable i: natural := 0;--iteration
		
		--function and variables from https://vhdlwhiz.com/random-numbers/
		variable seed1, seed2 : integer := 999;
		impure function rand_slv(len : integer) return std_logic_vector is
		  variable r : real;
		  variable slv : std_logic_vector(len - 1 downto 0);
		begin
		  for i in slv'range loop
			 uniform(seed1, seed2, r);
			 if r > 0.5 then
				slv(i) := '1';
			 else
				slv(i) := '0';
			 end if;
		  end loop;
		  return slv;
		end function;
		
	begin
		
		while i < MAX_ITER loop			
			A_p <= rand_slv(32);
			A_n <= rand_slv(32);
			
			wait until rising_edge(CLK);--rising_edge(CLK)
		end loop;
		wait; --?
	end process;
	
	test: process(expected_output,geq0,CLK)
	begin
		if(falling_edge(CLK)) then
			if (expected_output /= geq0)then
				error_flag <= '1';
			else
				error_flag <= '0';
			end if;
		end if;
	end process;
	
	clock: process--100MHz input clock
	begin
		CLK <= '1';
		wait for 5 ns;
		CLK <= '0';
		wait for 5 ns;
	end process clock;
end architecture test;
