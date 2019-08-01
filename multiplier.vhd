--I will start with a 4 bit version of a single cycle multiplier,
--then i will expand to 32 bits
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity multiplier is
	port(	A: in std_logic_vector(31 downto 0);
			B: in std_logic_vector(31 downto 0);
			P: out std_logic_vector(63 downto 0)
	);
end entity;

architecture bhv of multiplier is

component generic_multiplier
	generic (N: integer);	
	port (A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			P: out std_logic_vector(2*N-1 downto 0));
end component;

begin
	instance: generic_multiplier 
	generic map (N => 32)
	port map(A =>A,
				B =>B,
				P =>P
	);
	
end bhv;

-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity generic_multiplier is
	generic	(N: integer);
	port(	A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			P: out std_logic_vector(2*N-1 downto 0)
	);
end entity;

architecture gen_bhv of generic_multiplier is

component FA
	generic	(N: integer);
	port(	A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			Ci:in std_logic;
			Co:out std_logic;
			S: out std_logic_vector(N-1 downto 0)
	);
end component;

type prod_matrix is array (0 to N-1, 0 to N-1) of std_logic;
type carry_matrix is array (0 to N-1, 0 to N) of std_logic;
type sum_matrix is array (1 to N, 0 to N) of std_logic_vector(0 downto 0);
type A_matrix is array (0 to N-1, 0 to N-1) of std_logic_vector(0 downto 0);

signal prod: prod_matrix;
signal A_adder: A_matrix;
signal carry: carry_matrix;
signal S: sum_matrix;

begin
	--gera os produtos de A pelos bits de B
	lines: for i in 0 to N-1 generate--B index
		columns: for j in 0 to N-1 generate--A index
			prod(i,j) <= A(j) and B(i);
			A_adder(i,j)(0) <= prod(i,j);
		end generate columns;	
	end generate lines;
	
	lines_fa: for i in 1 to N-1 generate--B index
		columns_fa: for j in 0 to N-1 generate--A index
			full_adder: FA generic map (N => 1)
						port map(A => A_adder(i,j),
									B => S(i,j+1),
									Ci=> carry(i,j),
									Co=> carry(i,j+1),
									S => S(i+1,j)
			);
		end generate columns_fa;
	end generate lines_fa;
	
	left_column: for i in 2 to N-1 generate--B index
		S(i,N)(0) <= carry(i-1,N);
	end generate left_column;
	
	right_column: for i in 1 to N-1 generate
		carry(i,0) <= '0';
	end generate right_column;
	
	upper_row: for j in 1 to N-1 generate
		S(1,j) <= A_adder(0,j);
	end generate upper_row;
	
	S(1,N) <= (others=>'0');
	
	lsb: for k in 1 to N-1 generate
		P(k)	<=	S(k+1,0)(0);
	end generate lsb;
	
	msb: for k in 0 to N-2 generate
		P(k+N)<=	S(N,k+1)(0);
	end generate msb;
	
	P(0) <= prod(0,0);
	P(2*N-1) <= carry(N-1,N);
	
end gen_bhv;