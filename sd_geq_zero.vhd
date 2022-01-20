--------------------------------------------------
--comparator for arbitrary legth signed-digit (SD) binary numbers
--SD number A is encoded with 2 bits (signed digits)/per digit as follows:
--	   x+| x-|  s |
-- 	0 | 0 |  0 |
-- 	0 | 1 | -1 |
-- 	1 | 1 |  0 |
-- 	1 | 0 | +1 |
--output S is '1' if A is greater or equal than zero
--output S is '0' if A is negative
--by Renan Picoli de Souza
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;--ceil, log
use work.signed_digit_pkg.all;

entity sd_geq_zero is
generic (N: natural);--number of digits
port (
	A: in sd_vector(N-1 downto 0);--SD binary number
	S:	out std_logic--is '1' if A is greater or equal than zero
);
end entity;

architecture bhv of sd_geq_zero is
	--signal and component declarations

		component sd_sign_1bit
		port (
			A: in signed_digit;--SD binary digit
			P:	out std_logic;--is '1' if digit is strictly positive
			N:	out std_logic--is '1' if digit is strictly negative
		);
		end component;
		
		constant D: natural := integer(ceil(log2(real(N))));-- D+1 is the number of comparator "layers"
		type p_matrix is array (D downto 0) of std_logic_vector(0 to (2**D-1));
		signal p: p_matrix := (others=> (others => '0'));--indexes: depth and breadth, respectively
		type n_matrix is array (D downto 0) of std_logic_vector(0 to (2**D-1));
		signal neg: n_matrix := (others=> (others => '0'));--indexes: depth and breadth, respectively
	
	begin

	depth: for i in D downto 0 generate
			i_D: if i=D generate
				breadth: for j in (N-1) downto 0 generate
					comparator_D_j: sd_sign_1bit port map(
						A => A(j),
						P => p(D)(j),
						N => neg(D)(j)
					);
				end generate;
			end generate;
			i_others: if i/=D generate
				breadth: for j in 0 to (2**i-1) generate
					p(i)(j) <= p(i+1)(2*j+1) or (not neg(i+1)(2*j+1) and p(i+1)(2*j));
					neg(i)(j) <= neg(i+1)(2*j+1) or (not p(i+1)(2*j+1) and neg(i+1)(2*j));
				end generate;
			end generate;
	end generate;
	
	S <= p(0)(0) or (not neg(0)(0));
	
end bhv;