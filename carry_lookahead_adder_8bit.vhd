--------------------------------------------------
-- 8-bit carry look ahead adder (CLA)
--Computes A+B+Cin
--generates sum S and carry output Cout
--outputs GG and PG are group generation and group propagation of carry, respectively for cascading
--by Renan Picoli de Souza
--treats A and B as unsigned integers
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cla_8bit is
		port (
			A: in std_logic_vector(7 downto 0);--unsigned integer
			B: in std_logic_vector(7 downto 0);--unsigned integer
			Cin: in std_logic;--input carry, allows cascading
			Cout:	out std_logic;
--			GG: out std_logic;
--			PG: out std_logic;
			S:		out std_logic_vector(7 downto 0)--A+B+Cin
		);
end entity;

architecture bhv of cla_8bit is
	--signal and component declarations
	signal P: std_logic_vector(7 downto 0);--carry propagation
	signal G: std_logic_vector(7 downto 0);--carry generation
	signal C: std_logic_vector(7 downto 0);--C(n): carry of addition of n-th bits
	
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
		C(4) <=	G(4) or 
				 (P(4) and G(3)) or
				 (P(4) and P(3) and G(2)) or
				 (P(4) and P(3) and P(2) and G(1)) or
				 (P(4) and P(3) and P(2) and P(1) and G(0)) or 
				 (P(4) and P(3) and P(2) and P(1) and P(0) and Cin);
		C(5) <=	G(5) or
				 (P(5) and G(4)) or 
				 (P(5) and P(4) and G(3)) or
				 (P(5) and P(4) and P(3) and G(2)) or
				 (P(5) and P(4) and P(3) and P(2) and G(1)) or
				 (P(5) and P(4) and P(3) and P(2) and P(1) and G(0)) or 
				 (P(5) and P(4) and P(3) and P(2) and P(1) and P(0) and Cin);
		C(6) <=	G(6) or
				 (P(6) and G(5)) or
				 (P(6) and P(5) and G(4)) or
				 (P(6) and P(5) and P(4) and G(3)) or
				 (P(6) and P(5) and P(4) and P(3) and G(2)) or
				 (P(6) and P(5) and P(4) and P(3) and P(2) and G(1)) or
				 (P(6) and P(5) and P(4) and P(3) and P(2) and P(1) and G(0)) or
				 (P(6) and P(5) and P(4) and P(3) and P(2) and P(1) and P(0) and Cin);
		C(7) <=	G(7) or
				 (P(7) and G(6)) or
				 (P(7) and P(6) and G(5)) or
				 (P(7) and P(6) and P(5) and G(4)) or
				 (P(7) and P(6) and P(5) and P(4) and G(3)) or
				 (P(7) and P(6) and P(5) and P(4) and P(3) and G(2)) or	
				 (P(7) and P(6) and P(5) and P(4) and P(3) and P(2) and G(1)) or
				 (P(7) and P(6) and P(5) and P(4) and P(3) and P(2) and P(1) and G(0)) or 
				 (P(7) and P(6) and P(5) and P(4) and P(3) and P(2) and P(1) and P(0) and Cin);
		
--		GG <= v_GG;
--		PG <= v_PG;
	end process;
	
	S <= P xor C(6 downto 0) & Cin;
	Cout <= C(7);
end bhv;