library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 

package single_precision_type is

	type float is record
	sign		:std_logic;
	exponent	:std_logic_vector(7 downto 0);--BIASED exponent
	mantissa	:std_logic_vector(22 downto 0);--mantissa with the '1' in the left suppressed
	end record float;
	
	constant EXP_BIAS: natural := 127;
	
	constant positive_zero: std_logic_vector(31 downto 0):= x"0000_0000";
	constant negative_zero: std_logic_vector(31 downto 0):= x"8000_0000";
	constant positive_Inf : std_logic_vector(31 downto 0):= x"7F80_0000";
	constant negative_Inf : std_logic_vector(31 downto 0):= x"FF80_0000";
	constant NaN			 : std_logic_vector(31 downto 0):= x"FFFF_FFFF";
	
end package single_precision_type;