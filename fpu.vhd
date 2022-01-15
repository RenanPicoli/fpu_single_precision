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
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end entity;

architecture bhv of fpu is
--signal and component declarations
signal fpu_adder_res: std_logic_vector(31 downto 0);
signal fpu_adder_overflow: std_logic;
signal fpu_adder_underflow: std_logic;
signal A_adder: std_logic_vector(31 downto 0);
signal B_adder: std_logic_vector(31 downto 0);

signal fpu_mult_res:	std_logic_vector(31 downto 0);
signal fpu_mult_overflow: std_logic;
signal fpu_mult_underflow: std_logic;

signal fpu_div_res: 	std_logic_vector(31 downto 0);
signal fpu_div_overflow: std_logic;
signal fpu_div_underflow: std_logic;
signal fpu_div_divideByZero: std_logic;

constant EN_FAST_DIV: boolean := true;
constant EN_SIGNED_DIGIT: boolean := true;

component fpu_adder
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------NEED ADD FLAGS (overflow, underflow, etc)
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end component;

component fpu_mult
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------NEED ADD FLAGS (overflow, underflow, etc)
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end component;

component fpu_divider
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	--FLAGS (overflow, underflow, etc)
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end component;

--uses fast adders (carry look ahead)
component fpu_fast_divider
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	--FLAGS (overflow, underflow, etc)
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end component;

component fpu_fast_divider_sd
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------FLAGS (div by zero, overflow, underflow, etc)
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:			out std_logic_vector(31 downto 0)--A/B
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
		overflow	=> fpu_adder_overflow,
		underflow=> fpu_adder_underflow,
		result=> fpu_adder_res
	);
	
	multiplier: fpu_mult port map(
		A  	=> A,
		B  	=> B,
		overflow	=> fpu_mult_overflow,
		underflow=> fpu_mult_underflow,
		result=> fpu_mult_res
	);

	--can't use if generate with ELSE
	fast_divider: if EN_FAST_DIV and not EN_SIGNED_DIGIT generate
		f_div: fpu_fast_divider port map(
			A  	=> A,
			B  	=> B,
			overflow	=> fpu_div_overflow,
			underflow=> fpu_div_underflow,
			divideByZero=> fpu_div_divideByZero,
			result=> fpu_div_res
		);
	end generate fast_divider;
	
	--can't use if generate with ELSE
	fast_divider_sd: if EN_FAST_DIV and EN_SIGNED_DIGIT generate
		f_div: fpu_fast_divider_sd port map(
			A  	=> A,
			B  	=> B,
			overflow	=> fpu_div_overflow,
			underflow=> fpu_div_underflow,
			divideByZero=> fpu_div_divideByZero,
			result=> fpu_div_res
		);
	end generate fast_divider_sd;

	--can't use if generate with ELSE
	divider: if not EN_FAST_DIV generate
		common_div: fpu_divider port map(
			A  	=> A,
			B  	=> B,
			overflow	=> fpu_div_overflow,
			underflow=> fpu_div_underflow,
			divideByZero=> fpu_div_divideByZero,
			result=> fpu_div_res
		);
	end generate divider;
	
	result<= fpu_adder_res when (op = "00") else--addition
				fpu_adder_res when (op = "01") else--subtraction
				fpu_mult_res  when (op = "10") else--multiplication
				fpu_div_res   when (op = "11") else--division
				(others=>'X');
				
	overflow <=	fpu_adder_overflow when (op = "00") else--addition
					fpu_adder_overflow when (op = "01") else--subtraction
					fpu_mult_overflow  when (op = "10") else--multiplication
					fpu_div_overflow   when (op = "11") else--division
					'X';
					
	underflow <=fpu_adder_underflow when (op = "00") else--addition
					fpu_adder_underflow when (op = "01") else--subtraction
					fpu_mult_underflow  when (op = "10") else--multiplication
					fpu_div_underflow   when (op = "11") else--division
					'X';
					
	divideByZero <='0' when (op = "00") else--addition
						'0' when (op = "01") else--subtraction
						'0' when (op = "10") else--multiplication
						fpu_div_divideByZero when (op = "11") else--division
						'X';	
end bhv;