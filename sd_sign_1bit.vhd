--------------------------------------------------
--comparator for 1-digit signed-digit (SD) binary numbers
--SD number A is encoded with 2 bits (signed digits) as follows:
--	   x+| x-|  s |
-- 	0 | 0 |  0 |
-- 	0 | 1 | -1 |
-- 	1 | 1 |  0 |
-- 	1 | 0 | +1 |
--output P is '1' if digit is strictly positive (+1)
--output N is '1' if digit is strictly negative (-1)
--by Renan Picoli de Souza
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;--ceil
--use work.all;
use work.signed_digit_pkg.all;

entity sd_sign_1bit is
port (
	A: in signed_digit;--SD binary digit
	P:	out std_logic;--is '1' if digit is strictly positive
	N:	out std_logic--is '1' if digit is strictly negative
);
end entity;

architecture bhv of sd_sign_1bit is
	--signal and component declarations
	
	begin

	process(A)
	begin
		if(A = "10") then-- A = +1				
			P <= '1';
		else-- A = +/-0 or A = -1		
			P <= '0';
		end if;
		
		if(A = "01") then-- A = -1				
			N <= '1';
		else-- A = +/-0 or A = +1	
			N <= '0';
		end if;
	end process;
	
end bhv;