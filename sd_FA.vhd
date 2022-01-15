--------------------------------------------------
--signed-digit 1-bit full adder
--A and B encoded with 2 bits (signed digits) as follows:
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

entity sd_FA is
port (
	A: in signed_digit;--SD binary number
	B: in signed_digit;--SD binary number
	Cin: in signed_digit;--input carry, allows cascading
	Cout:	out signed_digit;--output carry, allows cascading
	S:		out signed_digit--A+B+Cin, encoded as SD binary number
);
end entity;

architecture bhv of sd_FA is
	--signal and component declarations
	
	begin

	process(A,B,Cin)
	begin
		if(Cin = "01") then-- Cin = -1
			
			if(A = "01") then-- A = -1
				
				if(B = "01") then-- B = -1
					S <= "01";-- S = -1
					Cout <= "01";-- Cout = -1
				elsif (B = "10") then-- B = +1
					S <= "01";-- S = -1
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "00";-- S = 0
					Cout <= "01";-- Cout = -1
				end if;
			elsif (A = "10") then-- A = +1
				
				if(B = "01") then-- B = -1
					S <= "01";-- S = 0
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				end if;
			else-- A = +/-0
				
				if(B = "01") then-- B = -1
					S <= "00";-- S = 0
					Cout <= "01";-- Cout = -1
				elsif (B = "10") then-- B = +1
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "01";-- S = -1
					Cout <= "00";-- Cout = 0
				end if;
			end if;
		elsif (Cin = "10") then-- Cin = +1
			
			if(A = "01") then-- A = -1
				
				if(B = "01") then-- B = -1
					S <= "01";-- S = -1
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				end if;
			elsif (A = "10") then-- A = +1
				
				if(B = "01") then-- B = -1
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "10";-- S = +1
					Cout <= "10";-- Cout = +1
				else-- B = +/-0
					S <= "00";-- S = 0
					Cout <= "10";-- Cout = +1
				end if;
			else-- A = +/-0
				
				if(B = "01") then-- B = -1
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "00";-- S = 0
					Cout <= "10";-- Cout = +1
				else-- B = +/-0
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				end if;
			end if;
		else-- Cin = +/-0
			
			if(A = "01") then-- A = -1
				
				if(B = "01") then-- B = -1
					S <= "00";-- S = 0
					Cout <= "01";-- Cout = -1
				elsif (B = "10") then-- B = +1
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "01";-- S = -1
					Cout <= "00";-- Cout = 0
				end if;
			elsif (A = "10") then-- A = +1
				
				if(B = "01") then-- B = -1
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "00";-- S = 0
					Cout <= "10";-- Cout = +1
				else-- B = +/-0
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				end if;
			else-- A = +/-0
				
				if(B = "01") then-- B = -1
					S <= "01";-- S = -1
					Cout <= "00";-- Cout = 0
				elsif (B = "10") then-- B = +1
					S <= "10";-- S = +1
					Cout <= "00";-- Cout = 0
				else-- B = +/-0
					S <= "00";-- S = 0
					Cout <= "00";-- Cout = 0
				end if;
			end if;
		end if;
	end process;
	
end bhv;