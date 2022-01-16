--------------------------------------------------
--Floating Point DIVIDER implementation
--uses sd_adders to decrease latency
--Computes A/B
--by Renan Picoli de Souza
--Performs division of NORMAL floats (IEEE 754-2008)
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer,shift_right

use work.single_precision_type.all;--float
use work.signed_digit_pkg.all;--signed digit numbers

entity fpu_fast_divider_sd is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	-------FLAGS (div by zero, overflow, underflow, etc)
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:			out std_logic_vector(31 downto 0)--A/B
);
end entity;

architecture bhv of fpu_fast_divider_sd is
--signal and component declarations
component sd_adder
generic (N: natural );--N: operand sizes in bits
port (
	A: in sd_vector(N-1 downto 0);--SD binary number
	B: in sd_vector(N-1 downto 0);--SD binary number
	Cin: in signed_digit;--input carry, allows cascading
	Cout:	out signed_digit;--output carry, allows cascading
	S:		out sd_vector(N-1 downto 0)--A+B+Cin, encoded as SD binary number
);
end component;

component sd_geq_zero
generic (N: natural);--number of digits
port (
	A: in sd_vector;--SD binary number
	S:	out std_logic--is '1' if A is greater or equal than zero
);
end component;

signal A_fp: float;
signal B_fp: float;
signal A_expanded_mantissa: std_logic_vector(23 downto 0);
signal B_expanded_mantissa: std_logic_vector(23 downto 0);

type A_matrix is array (0 to 26) of sd_vector(24 downto 0);--precisa 1 digito a mais pq os restos intermediários são multiplicados por 2
signal A_inter: A_matrix;--dividendos intermediários
signal C: std_logic_vector(0 to 26);--resultado das comparações + 1bit para arrendondamento (quociente)
type R_matrix is array (0 to 26) of sd_vector(24 downto 0);--a rigor, só precisa de 23 digitos pq é o tamanho de B_expanded_mantissa
signal R: R_matrix;--restos intermediários
type D_matrix is array (0 to 26) of sd_vector(24 downto 0);--a rigor, só precisa de 23 bit pq é o tamanho de B_expanded_mantissa
signal D: D_matrix;--resultados de diferenças

signal sd_B: sd_vector(24 downto 0);
signal neg_sd_B: sd_vector(24 downto 0);-- all bits of sd_B are negated (represents -B)

signal geq_0: std_logic_vector(0 to 26);-- geq_0(i) ='1' means D(n) >= 0

begin

	A_expanded_mantissa <= '1' & A_fp.mantissa;
	B_expanded_mantissa <= '1' & B_fp.mantissa;
	
	A_fp <= (A(31),A(30 downto 23),A(22 downto 0));
	B_fp <= (B(31),B(30 downto 23),B(22 downto 0));
	
	--generates adders for subtractions ( A_inter(n) - ('0' & B_expanded_mantissa) )
	differences: for i in 0 to 26 generate
		sub: sd_adder generic map (N => 25)
		port map (A => A_inter(i),
					 B => neg_sd_B,-- not ('0' & B_expanded_mantissa)+1
					 Cin => "00",
					 Cout => open,
					 S => D(i));
		
		geq_zero_n: sd_geq_zero generic map (N => 25)
		port map (
				A => D(i),
				S => geq_0(i)
		);
	end generate differences; 

--signal assignments
 lines: for n in 1 to 26 generate
	--D(n) <= A_inter(n) - ('0' & B_expanded_mantissa);
	--TODO: create a comparator, line below is not enough
--	C(n) <= '1' when D(n)(24)="00"-- A_inter(n) >= '0' & B_expanded_mantissa
	C(n) <= '1' when geq_0(n)='1'-- A_inter(n) >= '0' & B_expanded_mantissa
				else '0';
	
	R(n)	<= D(n-1) when (C(n-1) = '1')
				else A_inter(n-1);
					
	A_inter(n)	<= R(n)(23 downto 0) & "00";--multiplica o resto intermediário por 2

 end generate lines;
 --caso básico
-- D(0) <= ('0' & A_expanded_mantissa) - ('0' & B_expanded_mantissa);
C(0) <= '1' when (D(0)(24)="00" or D(0)(24)="11") -- this means A_expanded_mantissa >= B_expanded_mantissa
			else '0';
			
 -- A_inter(0) <= '0' & A_expanded_mantissa
 -- sd_B <= '0' & B_expanded_mantissa
 init: for i in 23 downto 0 generate
	A_inter(0)(i) <= A_expanded_mantissa(i) & '0';
	sd_B(i) <= B_expanded_mantissa(i) & '0';
 end generate;
 A_inter(0)(24) <= "00";
 sd_B(24) <= "00";
 
 -- all bits of sd_B are negated (represents -B)
 init_neg_sd_B: for i in 24 downto 0 generate
	neg_sd_B(i)(1) <= not sd_B(i)(1);
	neg_sd_B(i)(0) <= not sd_B(i)(0);
 end generate;
 
process(A,B,A_fp,B_fp,C,R)
	variable res_expanded_mantissa: std_logic_vector(26 downto 0);--1 bit de overflow + 24 bits de mantissa expandida + 2bit para arrendondamento
	variable truncated_bits: std_logic_vector(-1+256 downto 0);
	variable res_exp_aux: std_logic_vector(8 downto 0);--1 additional bit for overflow/underflow detection
	variable overflow_aux: std_logic;--auxiliary variable
	variable underflow_aux: std_logic;--auxiliary variable
	
	begin

	--this int varies from 0-255+127=-128=1'1000'0000 to 255-0+127=382=1'0111'1110
	res_exp_aux := ('0' & A_fp.exponent) - ('0' & B_fp.exponent) + EXP_BIAS;
	res_expanded_mantissa := '0' & C(0 to 25);--C(0) might be '0', needs normalization below
	
	-- pre-multiplier: trivial cases
	if ((A_fp.exponent = x"FF" and A_fp.mantissa > 0) or
		(B_fp.exponent = x"FF" and B_fp.mantissa > 0)) then--check for NaN
			result <= NaN;
			overflow_aux := '0';
			underflow_aux:= '0';
	elsif (((A = positive_Inf or A = negative_Inf) and
			(B = positive_Inf or B = negative_Inf)) or
			((A = positive_zero or A = negative_zero) and
			(B = positive_zero or B = negative_zero))) then--check for Inf/Inf or 0/0
			result <= NaN;
			overflow_aux := '0';
			underflow_aux:= '0';
	elsif (A = positive_Inf or A = negative_Inf) then-- checking for Inf/0 or Inf/normal, Inf/Inf was already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
		overflow_aux := '0';
		underflow_aux:= '0';
	elsif (B = positive_Inf or B = negative_Inf) then-- checking for 0/Inf or normal/Inf, Inf/Inf was already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
		overflow_aux := '0';
		underflow_aux:= '0';
	elsif (A = positive_zero or A = negative_zero) then-- checking for 0/normal, 0/0 and 0/Inf cases were already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
		overflow_aux := '0';
		underflow_aux:= '0';
	elsif (B = positive_zero or B = negative_zero) then-- checking for normal/0, 0/0 and Inf/0 cases were already checked
		result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
		overflow_aux := '0';
		underflow_aux:= '0';

	-- division: normal case
	else
		-- normalization: only 2 cases: C0C1=1X or C0C1=01
		if res_expanded_mantissa(25)='1' then--no need for normalization, only rounding
			res_exp_aux := res_exp_aux;
			res_expanded_mantissa := res_expanded_mantissa;
		else--C(0)='0' but C(1)='1'
			res_exp_aux := res_exp_aux - 1;--might produce underflow
			res_expanded_mantissa := res_expanded_mantissa(25 downto 0) & C(26);
		end if;
		
		--roundTiesToEven
		if (res_expanded_mantissa(1)='0') then-- first non encoded bit
			--round down
			res_expanded_mantissa := res_expanded_mantissa;				
		elsif (res_expanded_mantissa(1)='1' and R(24) /= (24 downto 0 =>"00")) then
			--round up
			res_expanded_mantissa(25 downto 2) := res_expanded_mantissa(25 downto 2) + 1;--might need normalization again
			res_expanded_mantissa (1 downto 0) := "00";
		else-- tie: rounds to nearest even mantissa
			if (res_expanded_mantissa(2)/='0') then
				res_expanded_mantissa(25 downto 2) := res_expanded_mantissa(25 downto 2) + 1;
				res_expanded_mantissa (1 downto 0) := "00";
			end if;				
		end if;
			
		--since rounding might increase value by one, we need normalize again
		if (res_expanded_mantissa(26)='1') then
			res_exp_aux := res_exp_aux + 1;
			res_expanded_mantissa := '0' & res_expanded_mantissa (26 downto 1);
		end if;
			
		result <= (A_fp.sign xor B_fp.sign) & res_exp_aux(7 downto 0) & res_expanded_mantissa(24 downto 2);

		-- overflow/underflow detection. See ovflw_undflw.txt for explanation
		--	overflow_aux := res_exp_aux(8) and (not res_exp_aux(7));
		--	underflow_aux := res_exp_aux(8) and res_exp_aux(7);
		if ((res_exp_aux(8 downto 7) = "10") or (res_exp_aux(7 downto 0) = (7 downto 0 => '1'))) then
			overflow_aux := '1';
		else
			overflow_aux := '0';
		end if;
		
		if (res_exp_aux(8 downto 7) = "11") then
			underflow_aux := '1';
		else
			underflow_aux := '0';
		end if;

	end if;
	
	overflow <= overflow_aux;
	underflow<= underflow_aux;			
	--overflow/underflow handling
	if(overflow_aux='1') then--result is set to +/-Inf
		result <= (A_fp.sign xor B_fp.sign) & positive_Inf(30 downto 0);
	elsif (underflow_aux='1') then--result is set to +/-0
		result <= (A_fp.sign xor B_fp.sign) & positive_zero(30 downto 0);
	end if;
	
	--division by zero
	if ((B = positive_zero) or (B = negative_zero)) then 
		divideByZero <= '1';
	else
		divideByZero <= '0';
	end if;

end process;
end bhv;