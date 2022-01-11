library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;--for uniform random number generation
use work.all;
use ieee.std_logic_textio.all;--for reading of std_logic_vectors

entity testbench is
end testbench;

architecture test of testbench is
-- "Time" that will elapse between test vectors we submit to the component.
constant TIME_DELTA : time := 10 ns;

signal  	A: std_logic_vector(31 downto 0);
signal	B: std_logic_vector(31 downto 0);
signal	Cin: std_logic_vector(0 downto 0);
signal	result: std_logic_vector(31 downto 0);
signal	Cout: std_logic;

signal CLK: std_logic;
signal expected_output: std_logic_vector(32 downto 0);--additional bit for overflow
signal error_flag: std_logic;

constant MAX_ITER: natural := 10;

begin

	DUT: entity work.cla
	generic map (N => 32)
	port map(A 		=> A,
				B	 	=> B,
				Cin 	=> Cin(0),
				Cout	=> Cout,
				S		=> result
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
			A <= rand_slv(32);
			B <= rand_slv(32);
			Cin <= rand_slv(1);
			
			wait until rising_edge(CLK);--rising_edge(CLK)
		end loop;
		wait; --?
	end process;
	
	expected_output <= ('0' & A) + ('0' & B) + Cin(0);
	
	test: process(expected_output,result,CLK)
	begin
		if(falling_edge(CLK)) then
			if (expected_output(31 downto 0) /= result) or (Cout /= expected_output(32)) then
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