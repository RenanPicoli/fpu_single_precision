-- package for signed-digit (SD) binary numbers
library ieee;
use ieee.std_logic_1164.all;

package signed_digit_pkg is
        type signed_digit is array (1 downto 0) of std_logic;-- (1) -> x+; (0) -> x-
		  type sd_vector is array(natural range <>) of signed_digit;
end package;