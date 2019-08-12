--------------------------------------------------
--Floating Point DIVIDER implementation
--Computes A/B
--by Renan Picoli de Souza
--Performs division of NORMAL floats (IEEE 754-2008)
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer,shift_right

use work.single_precision_type.all;--float

entity fpu_divider is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------FLAGS (div by zero, overflow, underflow, etc)
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)--A/B
);
end entity;

architecture bhv of fpu_divider is
--signal and component declarations
signal A_fp: float;
signal B_fp: float;
signal A_expanded_mantissa: std_logic_vector(23 downto 0);
signal B_expanded_mantissa: std_logic_vector(23 downto 0);
signal res_expanded_mantissa: std_logic_vector(23 downto 0);

--23 because expanded mantissais 24 bits long
type A_matrix is array (0 to 23) of std_logic_vector(24 downto 0);--precisa 1 bit a mais pq os restos intermediários são multiplicados por 2
signal A_inter: A_matrix;--dividendos intermediários
signal C: std_logic_vector(0 to 23);--resultado das comparações
type R_matrix is array (0 to 23) of std_logic_vector(24 downto 0);--a rigor, só precisa de 23 bit pq é o tamanho de B_expanded_mantissa
signal R: R_matrix;--restos intermediários

begin

	A_expanded_mantissa <= '1' & A_fp.mantissa;
	B_expanded_mantissa <= '1' & B_fp.mantissa;
	
	A_fp <= (A(31),A(30 downto 23),A(22 downto 0));
	B_fp <= (B(31),B(30 downto 23),B(22 downto 0));

--signal assignements
 lines: for n in 1 to 23 generate
	C(n) <= '1' when (A_inter(n) >= '0' & B_expanded_mantissa)
				else '0';
	
	R(n)	<= (A_inter(n-1) - ('0' & B_expanded_mantissa)) when (C(n-1) = '1')
				else A_inter(n-1);
					
	A_inter(n)	<= R(n)(23 downto 0) & '0';--multiplica o resto intermediário por 2

 end generate lines;
 --caso básico
 C(0) <= '1' when (A_expanded_mantissa >= B_expanded_mantissa)
			else '0';
 A_inter(0) <= '0' & A_expanded_mantissa;
 res_expanded_mantissa <= C;--C(0) might be '0', needs normalization below

process(A,B,A_fp,B_fp,res_expanded_mantissa)
	variable A_exp:integer;
	variable B_exp:integer; 
	variable shifted_A_expanded_mantissa: unsigned(23 downto 0);
	variable shifted_B_expanded_mantissa: unsigned(23 downto 0);
	variable res_mantissa: std_logic_vector(22 downto 0);
	variable res_exp: integer;
	variable res_sign: std_logic;	
	variable res_exp_aux: std_logic_vector(8 downto 0);--1 additional bit for overflow/underflow detection
	variable overflow_aux: std_logic;--auxiliary variable
	variable underflow_aux: std_logic;--auxiliary variable
	
	begin
	
	A_exp:= to_integer(unsigned(A_fp.exponent));
	B_exp:= to_integer(unsigned(B_fp.exponent));
	res_exp := A_exp - B_exp + EXP_BIAS;--this int varies from 0-255+127=-128=1'1000'0000 to 255-0+127=382=1'0111'1110
	
	--overflow/underflow detection. See ovflw_undflw.txt for explanation
	res_exp_aux := std_logic_vector(to_unsigned(res_exp,9));
	overflow_aux := res_exp_aux(8) and (not res_exp_aux(7));
	underflow_aux := res_exp_aux(8) and  res_exp_aux(7);
	overflow <= overflow_aux;
	underflow<= underflow_aux;
	
	-- pre-multiplier: trivial cases
	if ((A_fp.exponent = x"FF" and A_fp.mantissa > 0) or
		(B_fp.exponent = x"FF" and B_fp.mantissa > 0)) then--check for NaN
			result <= NaN;	
	elsif (((A = positive_Inf or A = negative_Inf) and
			(B = positive_Inf or B = negative_Inf)) or
			((A = positive_zero or A = negative_zero) and
			(B = positive_zero or B = negative_zero))) then--check for Inf/Inf or 0/0
			result <= NaN;
	elsif (A = positive_Inf or A = negative_Inf) then-- checking for Inf/0 or Inf/normal, Inf/Inf was already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
	elsif (B = positive_Inf or B = negative_Inf) then-- checking for 0/Inf or normal/Inf, Inf/Inf was already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
	elsif (A = positive_zero or A = negative_zero) then-- checking for 0/normal, 0/0 and 0/Inf cases were already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
	elsif (B = positive_zero or B = negative_zero) then-- checking for normal/0, 0/0 and Inf/0 cases were already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);

	-- division: normal case
	else
		-- normalization: only 2 cases: C0C1=1X or C0C1=01
		if res_expanded_mantissa(23)='1' then--no need for normalization
			result <= (A_fp.sign xor B_fp.sign) & std_logic_vector(to_unsigned(res_exp,8)) & res_expanded_mantissa(22 downto 0);
		else--C(0)='0' but C(1)='1'
			result <= (A_fp.sign xor B_fp.sign) & std_logic_vector(to_unsigned(res_exp-1,8)) & res_expanded_mantissa(21 downto 0) & '0';
		end if;

		--overflow/underflow handling
		if(overflow_aux='1') then--result is set to +/-Inf
			result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
		elsif (underflow_aux='1') then--result is set to +/-0
			result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
		end if;
	end if;
	
	--division by zero
	if ((B = positive_zero) or (B = negative_zero)) then 
		divideByZero <= '1';
	else
		divideByZero <= '0';
	end if;

end process;
end bhv;