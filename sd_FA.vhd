--------------------------------------------------
--signed-digit 1-bit full adder
--A and B encoded with 2 bits (signed digits) as follows:
--	   A+| A-|  s |
-- 	0 | 0 |  0 |
-- 	0 | 1 | -1 |
-- 	1 | 1 |  0 |
-- 	1 | 0 | +1 |
--Computes A+B+Cin
--generates sum S and carry output Cout

--based on work "A New Algorithm for Carry-Free Addition of
--Binary Signed-Digit Numbers" (Klaus Schneider and Adrian Willenb¨ucher)
--available at https://es.cs.uni-kl.de/publications/datarsg/ScWi14a.pdf

--NOTE: their work uses a different encoding
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;--ceil
--use work.all;
use work.signed_digit_pkg.all;

entity sd_FA is
port (
	A: in signed_digit;--SD binary number
	B: in signed_digit;--SD binary number
	lin: in boolean;
	tin: in signed_digit;
	lout:	out boolean;
	tout:	out signed_digit;
	S:		out signed_digit--sum digit encoded as SD binary number
);
end entity;

architecture bhv of sd_FA is
	--signal and component declarations
	signal w1,w2,w3,w4,w: boolean;
	signal u1,u0: std_logic;
	
	function to_std_logic(L: boolean) return std_ulogic is
		variable output: std_ulogic;
	begin
		if L then
			output := '1';
		else
			output := '0';
		end if;
		
		return output;
	end function to_std_logic;
	
begin

	process(A,B,lin,tin,w1,w2,w3,w4,w,u0,u1)
	begin
		w1 <= (A="00" or A="11") and (B="10"); -- A==0 and B==+1
		w2 <= (A="00" or A="11") and (B="01"); -- A==0 and B==-1
		w3 <= (B="00" or B="11") and (A="10"); -- B==0 and A==+1
		w4 <= (B="00" or B="11") and (A="01"); -- B==0 and A==-1
		w <= w1 or w2 or w3 or w4;
		u1 <= to_std_logic((not lin) and w); -- tin!=-1 and critical input
		u0 <= to_std_logic(lin and w); -- tin!=+1 and critical input
		-- determine lout := A=-1 or B=-1
		lout <= (A="01") or (B="01");
		-- tout- holds iff A=B=-1 or tin!=+1 and A+B=-1
		tout(0) <= ((not A(1) and A(0)) and (not (B(1) and B(0)))) or to_std_logic(lin and (w2 or w4));
		-- tout+ holds iff A=B=+1 or tin!=-1 and A+B=+1
		tout(1) <= ((A(1) and not A(0)) and (B(1) and not B(0))) or to_std_logic((not lin) and (w1 or w3));
		-- determine sum digit
		S(0) <= (tin(0) and (not u0)) or (u1 and (not tin(1)));
		S(1) <= (tin(1) and (not u1)) or (u0 and (not tin(0)));
	end process;
	
end bhv;