--------------------------------------------------
--signed-digit adder
--carry propagation limited to 2 stages
--A and B encoded with 2 bits/digit (signed digits) as follows:
--	   x+| x-|  s |
-- 	0 | 0 |  0 |
-- 	0 | 1 | -1 |
-- 	1 | 1 |  0 |
-- 	1 | 0 | +1 |
--Computes A+B+Cin
--generates sum S and carry output Cout
--by Renan Picoli de Souza
---------------------------------------------------

--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.math_real.all;--ceil
--
--package signed_digit_pkg is
--        type signed_digit is array (1 downto 0) of std_logic;-- (1) -> x+; (0) -> x-
--		  type sd_vector is array(natural range <>) of signed_digit;
--end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;--ceil
--use work.all;
use work.signed_digit_pkg.all;

entity sd_adder is
generic (N: natural );--N: operand sizes in bits
port (
	A: in sd_vector(N-1 downto 0);--SD binary number
	B: in sd_vector(N-1 downto 0);--SD binary number
	Cin: in signed_digit;--input carry, allows cascading
	Cout:	out signed_digit;--output carry, allows cascading
	S:		out sd_vector(N-1 downto 0)--A+B+Cin, encoded as SD binary number
);
end entity;

architecture bhv of sd_adder is
	--signal and component declarations
	component sd_FA
		port (
			A: in signed_digit;--SD binary number
			B: in signed_digit;--SD binary number
			Cin: in signed_digit;--input carry, allows cascading
			Cout:	out signed_digit;--output carry, allows cascading
			S:		out signed_digit--A+B+Cin, encoded as SD binary number
		);
	end component;
	
	signal C: sd_vector(N-1 downto 0);--C(n): carry output of n-th full adder
	
	begin
	
	--generates cascaded sd full adders
	adders: for i in 0 to N-1 generate
		add_0: if i=0 generate
			sd_fa_0: sd_FA port map (
				A => A(0),
				B => B(0),
				Cin => Cin,
				Cout=>C(0),
				S	=> S(0)--A+B+Cin
			);
		end generate;
		add_i: if (i> 0 and i < N) generate
			sd_fa_i: sd_FA port map (
				A => A(i),
				B => B(i),
				Cin => C(i-1),
				Cout=>C(i),
				S	=> S(i)--A+B+Cin
			);
		end generate;
	end generate;
	
	Cout <= C(N-1);
end bhv;