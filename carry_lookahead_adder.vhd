--------------------------------------------------
--carry look ahead adder (CLA)
--Computes A+B+Cin
--generates sum S and carry output Cout
--outputs GG and PG are group generation and group propagation of carry, respectively for cascading
--by Renan Picoli de Souza
--treats A and B as unsigned integers
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cla is
port (
	A: in std_logic_vector(3 downto 0);--unsigned integer
	B: in std_logic_vector(3 downto 0);--unsigned integer
	Cin: in std_logic;--input carry, allows cascading
	Cout:	out std_logic;
--	GG: out std_logic;
--	PG: out std_logic;
	S:		out std_logic_vector(3 downto 0)--A+B+Cin
);
end entity;

architecture bhv of cla is
	--signal and component declarations
	signal P: std_logic_vector(3 downto 0);--carry propagation
	signal G: std_logic_vector(3 downto 0);--carry generation
	signal C: std_logic_vector(3 downto 0);--C(n): carry of addition of n-th bits
	
	begin
	P <= A xor B;
	G <= A and B;
	
	--generates combinatorial logic
	process(P,G,Cin)
--		variable v_GG: std_logic;
--		variable v_PG: std_logic;
	begin
		C(0) <= 	G(0) or
					(P(0) and Cin);
		C(1) <=	G(1) or 
					(P(1) and G(0)) or 
					(P(1) and P(0) and Cin);
		C(2) <=	G(2) or 
					(P(2) and G(1)) or 
					(P(2) and P(1) and G(0)) or 
					(P(2) and P(1) and P(0) and Cin);
		C(3) <=	G(3) or 
					(P(3) and G(2)) or 
					(P(3) and P(2) and G(1)) or 
					(P(3) and P(2) and P(1) and G(0)) or 
					(P(3) and P(2) and P(1) and P(0) and Cin);
--		GG <= v_GG;
--		PG <= v_PG;
	end process;
	
	S <= P xor C(2 downto 0) & Cin;
	Cout <= C(3);
end bhv;