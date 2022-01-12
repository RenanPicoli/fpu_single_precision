--------------------------------------------------
--fast adder
--based on cascaded carry look ahead adders (CLA)
--Computes A+B+Cin
--generates sum S and carry output Cout
--by Renan Picoli de Souza
--treats A and B as unsigned integers
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;--ceil

entity fast_adder is
generic (N: natural );--N: operand sizes in bits
port (
	A: in std_logic_vector(N-1 downto 0);--unsigned integer
	B: in std_logic_vector(N-1 downto 0);--unsigned integer
	Cin: in std_logic;--input carry, allows cascading
	Cout:	out std_logic;
	S:		out std_logic_vector(N-1 downto 0)--A+B+Cin
);
end entity;

architecture bhv of fast_adder is
	--signal and component declarations
	--basic CLA
	component cla
		port (
			A: in std_logic_vector(3 downto 0);--unsigned integer
			B: in std_logic_vector(3 downto 0);--unsigned integer
			Cin: in std_logic;--input carry, allows cascading
			Cout:	out std_logic;
--			GG: out std_logic;
--			PG: out std_logic;
			S:		out std_logic_vector(3 downto 0)--A+B+Cin
		);
	end component;
	
	constant M: natural := 4;-- 4-bit adder
	constant N_CLA: natural := integer(ceil(real(N)/real(M)));--number of CLA's

--	signal P: std_logic_vector(N_CLA-1 downto 0);--carry propagation (between CLA's)
--	signal G: std_logic_vector(N_CLA-1 downto 0);--carry generation (between CLA's)
	signal C: std_logic_vector(N_CLA-1 downto 0);--C(n): carry of addition of n-th CLA
	signal expanded_A: std_logic_vector(N_CLA*M-1 downto 0);--expanded operand
	signal expanded_B: std_logic_vector(N_CLA*M-1 downto 0);--expanded operand
	signal expanded_S: std_logic_vector(N_CLA*M-1 downto 0);--expanded sum
	
	begin
	
	expanded_A <= (N_CLA*M-1 downto N => '1') & A;--filling A and B with ones and zeros garantees carry propagation, with no carry generation
	expanded_B <= (N_CLA*M-1 downto N => '0') & B;--filling A and B with ones and zeros garantees carry propagation, with no carry generation
	
	--generates combinatorial logic
	adders: for i in 0 to N-1 generate
		add_0: if i=0 generate
			cla_0: cla port map (
				A => expanded_A(M-1 downto 0),
				B => expanded_B(M-1 downto 0),
				Cin => Cin,
				Cout=>C(0),
--				GG	=> G(0),
--				PG	=> P(0),
				S	=> expanded_S(M-1 downto 0)--A+B+Cin
			);
		end generate;
		add_i: if (i> 0 and i < N_CLA) generate
			cla_i: cla port map (
				A => expanded_A(M*(i+1)-1 downto M*i),
				B => expanded_B(M*(i+1)-1 downto M*i),
				Cin => C(i-1),
				Cout=>C(i),
--				GG	=> G(i),
--				PG	=> P(i),
				S	=> expanded_S(M*(i+1)-1 downto M*i)--A+B+Cin
			);
		end generate;
	end generate;
	
	S <= expanded_S(N-1 downto 0);
	Cout <= C(N_CLA-1);
end bhv;