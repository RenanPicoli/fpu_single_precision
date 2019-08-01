--Full adder generico
-------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FA is
	generic	(N: integer);
	port(	A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			Ci: in std_logic;
			Co: out std_logic;
			S: out std_logic_vector(N-1 downto 0)
	);
end entity;

architecture add_bhv of FA is

component singlebit_FA
	port (A: in std_logic;
			B: in std_logic;
			Ci: in std_logic;
			Co: out std_logic;
			S: out std_logic);
end component;

signal carry: std_logic_vector(N downto 0);

begin

	cascade: for i in 0 to N-1 generate
		some_label: singlebit_FA port map (A => A(i),
								B => B(i),
								Ci=> carry(i),
								Co=> carry(i+1),
								S => S(i)
		);
	end generate cascade;

	carry(0) <= Ci;
	Co <= carry(N);
end add_bhv;

----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity singlebit_FA is
	port (A: in std_logic;
			B: in std_logic;
			Ci: in std_logic;
			Co: out std_logic;
			S: out std_logic);
end entity;

architecture bhv of singlebit_FA is

begin
	S <= (A xor B xor Ci);
	Co<= (A and B) or (B and Ci) or (A and Ci);
end bhv;