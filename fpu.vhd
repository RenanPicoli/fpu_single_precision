-----------------------------------------------------------------------------------------------
--Floating Point Unit implementation
--Combinatorial implementation (so it produces result in 1 clock cycle)
--by Renan Picoli de Souza
--supports addition, subtraction, multiplication and division of NORMAL floats (IEEE 754-2008)
-----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer

entity fpu is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	op:in std_logic_vector(1  downto 0);--4 operations: add,subtract, multiply,divide
	-------NEED ADD FLAGS (overflow, underflow, etc)
	result:out std_logic_vector(31 downto 0)
);
end entity;

architecture bhv of fpu is
--signal and component declarations
signal fpu_adder_res: std_logic_vector(31 downto 0);
signal A_adder: std_logic_vector(31 downto 0);
signal B_adder: std_logic_vector(31 downto 0);

signal fpu_mult_res:	std_logic_vector(31 downto 0);
signal fpu_div_res: 	std_logic_vector(31 downto 0);

component fpu_adder
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------NEED ADD FLAGS (overflow, underflow, etc)
	result:out std_logic_vector(31 downto 0)
);
end component;

component fpu_mult
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------NEED ADD FLAGS (overflow, underflow, etc)
	result:out std_logic_vector(31 downto 0)
);
end component;

component fpu_divider
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------NEED ADD FLAGS (overflow, underflow, etc)
	result:out std_logic_vector(31 downto 0)
);
end component;

begin
	A_adder <= A;
	B_adder <= B when (op="00") else-- addition
					(not B(31) & B(30 downto 0)) when (op="01") else--subtraction
					(others=>'-');

	adder: fpu_adder port map (
		A  	=> A_adder,
		B  	=> B_adder,
		result=> fpu_adder_res
	);
	
	multiplier: fpu_mult port map(
		A  	=> A,
		B  	=> B,
		result=> fpu_mult_res
	);

	divider: fpu_divider port map(
		A  	=> A,
		B  	=> B,
		result=> fpu_div_res
	);
	
	result<= fpu_adder_res when (op = "00") else--addition
				fpu_adder_res when (op = "01") else--subtraction
				fpu_mult_res  when (op = "10") else--multiplication
				fpu_div_res   when (op = "11") else--division
				(others=>'X');
	
end bhv;