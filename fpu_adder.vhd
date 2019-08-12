--------------------------------------------------
--Floating Point ADDER implementation
--Combinatorial implementation (so it produces result in 1 clock cycle)
--by Renan Picoli de Souza
--Performs addition of NORMAL floats (IEEE 754-2008)
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer,shift_right
--use ieee.numeric_std.unsigned;--unsigned
--use ieee.std_logic_arith.all;-- DONT USE, use numeric_std.all instead

use work.single_precision_type.all;--float

entity fpu_adder is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	--FLAGS (overflow, underflow, etc)
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:buffer std_logic_vector(31 downto 0)
);
end entity;

architecture bhv of fpu_adder is
--signal and component declarations
signal A_fp: float;
signal B_fp: float;

begin

A_fp <= (A(31),A(30 downto 23),A(22 downto 0));
B_fp <= (B(31),B(30 downto 23),B(22 downto 0));

process(A,B,A_fp,B_fp)
	variable A_exp:integer;
	variable B_exp:integer;
	variable A_expanded_mantissa: std_logic_vector(23 downto 0);
	variable B_expanded_mantissa: std_logic_vector(23 downto 0);
	variable shifted_A_expanded_mantissa: unsigned(23 downto 0);
	variable shifted_B_expanded_mantissa: unsigned(23 downto 0);
	variable res_expanded_mantissa: std_logic_vector(24 downto 0);
	variable res_mantissa: std_logic_vector(22 downto 0);
	variable res_exp: integer;
	variable res_sign: std_logic;
	variable count: integer;
	variable res_exp_aux: std_logic_vector(8 downto 0);--1 additional bit for overflow/underflow detection
	variable overflow_aux: std_logic;--auxiliary variable
	variable underflow_aux: std_logic;--auxiliary variable

	begin
	A_exp:= to_integer(unsigned(A_fp.exponent));
	B_exp:= to_integer(unsigned(B_fp.exponent));
	A_expanded_mantissa := '1' & A_fp.mantissa;
	B_expanded_mantissa := '1' & B_fp.mantissa;
	shifted_A_expanded_mantissa := unsigned(A_expanded_mantissa);--initial value
	shifted_B_expanded_mantissa := unsigned(B_expanded_mantissa);--initial value
	
	--overflow/underflow detection. See ovflw_undflw.txt for explanation
	res_exp_aux := std_logic_vector(to_unsigned(res_exp,9));
	overflow_aux := res_exp_aux(8) and (not res_exp_aux(7));
	underflow_aux := res_exp_aux(8) and  res_exp_aux(7);
	overflow <= overflow_aux;
	underflow<= underflow_aux;
	
	-- pre-adder
	if ((A = positive_zero or A = negative_zero) or
	(B = positive_zero or B = negative_zero)) then-- check for zero
		if (A = positive_zero or A = negative_zero) then
			result <= B;
		else--B must be zero
			result <= A;
		end if;
	elsif ((A_fp.exponent = x"FF" and A_fp.mantissa > 0) or
	(B_fp.exponent = x"FF" and B_fp.mantissa > 0)) then--check for NaN
		result <= NaN;
	elsif ((A = positive_Inf or A = negative_Inf) or
	(B = positive_Inf or B = negative_Inf)) then--check for Inf
		if (A = positive_Inf or A = negative_Inf) then--A is Inf, must check B
			if (B = positive_Inf or B = negative_Inf) then
				if (A_fp.sign = B_fp.sign) then-- (+Inf + +Inf) or (-Inf + -Inf)
					result <= A;
				else--Inf - Inf = NaN
					result <= NaN;
				end if;
			else--B is not Inf
				result <= A;
			end if;
		else--therefore, only B is Inf
			result <= B;
		end if;
	else
		if (A_fp.sign xor B_fp.sign)='0' then--same sign
			res_sign := A_fp.sign;
			if(A_exp > B_exp) then-- |A| > |B|
				--B needs to be shifted
				shifted_B_expanded_mantissa := shift_right(unsigned(B_expanded_mantissa),A_exp-B_exp);
				B_expanded_mantissa := std_logic_vector(shifted_B_expanded_mantissa);--shiftar mantissas até exponentes serem iguais
				res_exp := A_exp;
			else-- |A| =< |B|
				--A needs to be expanded
				shifted_A_expanded_mantissa := shift_right(unsigned(A_expanded_mantissa),B_exp-A_exp);
				A_expanded_mantissa := std_logic_vector(shifted_A_expanded_mantissa);--shiftar mantissas até exponentes serem iguais
				res_exp := B_exp;
			end if;
			res_expanded_mantissa := ('0'& A_expanded_mantissa) + ('0' & B_expanded_mantissa);
			if(res_expanded_mantissa(24)='1')then--normalizacao
				res_exp := res_exp + 1;
				res_mantissa := res_expanded_mantissa (23 downto 1);
			else
				res_mantissa := res_expanded_mantissa(22 downto 0);
			end if;
			result <= res_sign & std_logic_vector(to_unsigned(res_exp,8)) & res_mantissa;
			
		else --different signs
		
			if((A_exp > B_exp) or ((A_exp=B_exp)and(A_expanded_mantissa > B_expanded_mantissa))) then--this ensures |A| > |B|
				res_sign := A_fp.sign;
				res_exp  := A_exp;

				shifted_B_expanded_mantissa := shift_right(unsigned(B_expanded_mantissa),A_exp-B_exp);
				B_expanded_mantissa := std_logic_vector(shifted_B_expanded_mantissa);--shiftar mantissas até exponentes serem iguais
				res_expanded_mantissa := ('0' & A_expanded_mantissa) - ('0' & B_expanded_mantissa);
			else-- |A| <= |B|
				res_sign := B_fp.sign;
				res_exp  := B_exp;
				
				shifted_A_expanded_mantissa := shift_right(unsigned(A_expanded_mantissa),B_exp-A_exp);
				A_expanded_mantissa := std_logic_vector(shifted_A_expanded_mantissa);--shiftar mantissas até exponentes serem iguais
				res_expanded_mantissa := ('0' & B_expanded_mantissa) - ('0' & A_expanded_mantissa);
			end if;
			
			count := 23;--used in normalization, points to possible msb
			while ((res_expanded_mantissa(23)='0') and (count>=0)) loop--normalization
				res_exp := res_exp - 1;--pode ficar menor que 0
				count := count - 1;
				res_expanded_mantissa := res_expanded_mantissa (23 downto 0) & '0';--sll
			end loop;
			if(count>=0 and res_exp > 0)then--normalization succeeded
				res_mantissa := res_expanded_mantissa (22 downto 0);
			else--result is zero (0x00000000)
				res_mantissa := (others=>'0');
				res_exp := 0;
			end if;
			result <= res_sign & std_logic_vector(to_unsigned(res_exp,8)) & res_mantissa;
			
			--overflow/underflow handling
			if(overflow_aux='1') then--result is set to +/-Inf
				result <= res_sign & positive_Inf(30 downto 0);
			elsif (underflow_aux='1') then--result is set to +/-0
				result <= res_sign & positive_zero(30 downto 0);
			end if;
		
		end if;
	end if;	

end process;

end bhv;