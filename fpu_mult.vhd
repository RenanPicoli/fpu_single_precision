--------------------------------------------------
--Floating Point MULTIPLIER implementation
--Combinatorial implementation (so it produces result in 1 clock cycle)
--by Renan Picoli de Souza
--Performs addition of NORMAL floats (IEEE 754-2008)
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer,shift_right

use work.single_precision_type.all;--float

entity fpu_mult is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	--FLAGS (zero, overflow, underflow, etc)
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end entity;

architecture bhv of fpu_mult is
--signal and component declarations
signal P: std_logic_vector(47 downto 0);--product's expanded mantissa
signal A_fp: float;
signal B_fp: float;
signal A_expanded_mantissa: std_logic_vector(23 downto 0);
signal B_expanded_mantissa: std_logic_vector(23 downto 0);
	
component generic_multiplier
	generic (N: integer);	
	port (A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			P: out std_logic_vector(2*N-1 downto 0));
end component;

begin

	A_expanded_mantissa <= '1' & A_fp.mantissa;
	B_expanded_mantissa <= '1' & B_fp.mantissa;
	
	A_fp <= (A(31),A(30 downto 23),A(22 downto 0));
	B_fp <= (B(31),B(30 downto 23),B(22 downto 0));

	instance: generic_multiplier 
	generic map (N => 24)--N: expanded_mantissas' size
	port map(A =>A_expanded_mantissa,
				B =>B_expanded_mantissa,
				P =>P
	);

process(A,B,A_fp,B_fp,P)
	variable shifted_A_expanded_mantissa: unsigned(23 downto 0);
	variable shifted_B_expanded_mantissa: unsigned(23 downto 0);
	variable res_expanded_mantissa: std_logic_vector(24 downto 0);
	variable res_mantissa: std_logic_vector(22 downto 0);
	variable res_exp_aux: std_logic_vector(8 downto 0);--1 additional bit for overflow/underflow detection
	variable overflow_aux: std_logic;--auxiliary variable
	variable underflow_aux: std_logic;--auxiliary variable
	variable res_sign: std_logic;	
	
	begin
	
	-- pre-multiplier
	if ((A_fp.exponent = x"FF" and A_fp.mantissa > 0) or
		(B_fp.exponent = x"FF" and B_fp.mantissa > 0)) then--check for NaN
			result <= NaN;	
	elsif ((A = positive_Inf or A = negative_Inf) or
			(B = positive_Inf or B = negative_Inf)) then--check for Inf
		if (A = positive_Inf or A = negative_Inf) then--A is Inf, must check B
			if (B = positive_Inf or B = negative_Inf) then--A and B are Inf
				if (A_fp.sign = B_fp.sign) then-- (+Inf * +Inf) or (-Inf * -Inf)
					result <= positive_Inf;
				else-- (-Inf) * Inf = -Inf
					result <= negative_Inf;
				end if;
			else--B is not Inf, only A is Inf, B might be zero or normal
				if (B = positive_zero or B = negative_zero) then--B is zero
					result <= NaN;
				else-- B is normal
					result <= A xor (B_fp.sign & "0000000000000000000000000000000");
				end if;
			end if;
		else--therefore, only B is Inf, A might be zero or normal
				if (A = positive_zero or A = negative_zero) then--A is zero
					result <= NaN;
				else-- A is normal
					result <= B xor (A_fp.sign & "0000000000000000000000000000000");
				end if;
		end if;
	elsif ((A = positive_zero or A = negative_zero) or
	(B = positive_zero or B = negative_zero)) then-- check for zero
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
	else
		res_sign := A_fp.sign xor B_fp.sign;
		
		res_exp_aux := ('0' & A_fp.exponent) + ('0' & B_fp.exponent) - EXP_BIAS;
		--normalization: only 2 cases: exp=A_exp+B_exp or exp=A_exp+B_exp+1
		if (P(47)='1') then--exp=A_exp+B_exp+1
			res_exp_aux := res_exp_aux + 1;
			res_mantissa := P(46 downto 24);
		else--exp=A_exp+B_exp
			--keep current res_exp
			res_mantissa := P(45 downto 23);--P(46) must be '1' if P(47)='0'
		end if;
		
		result <= res_sign & res_exp_aux(7 downto 0) & res_mantissa;
		
		--overflow/underflow detection. See ovflw_undflw.txt for explanation
		overflow_aux := res_exp_aux(8) and (not res_exp_aux(7));
		underflow_aux := res_exp_aux(8) and  res_exp_aux(7);
		overflow <= overflow_aux;
		underflow<= underflow_aux;
		--overflow/underflow handling
		if(overflow_aux='1') then--result is set to +/-Inf
			result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
		elsif (underflow_aux='1') then--result is set to +/-0
			result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
		end if;
	end if;
end process;
end bhv;