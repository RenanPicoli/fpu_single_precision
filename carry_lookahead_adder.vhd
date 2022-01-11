--------------------------------------------------
--carry look ahead adder
--Computes A+B+Cin
--generates sum S and carry output Cout
--by Renan Picoli de Souza
--treats A and B as unsigned integers
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cla is
generic (N: natural);
port (
	A: in std_logic_vector(N-1 downto 0);--unsigned integer
	B: in std_logic_vector(N-1 downto 0);--unsigned integer
	Cin: in std_logic;--input carry, allows cascading
	Cout:	out std_logic;
	S:		out std_logic_vector(N-1 downto 0)--A+B+Cin
);
end entity;

architecture bhv of cla is
	--signal and component declarations
	signal P: std_logic_vector(N-1 downto 0);--carry propagation
	signal G: std_logic_vector(N-1 downto 0);--carry generation
	signal C: std_logic_vector(N-1 downto 0);--C(n): carry of addition of n-th bits
	
	begin
	P <= A xor B;
	G <= A and B;
	
	--generates combinatorial logic
	process(P,G,C,Cin)
	begin
		for i in 0 to N-1 loop
			if i=0 then
				C(0) <= G(0) or (Cin and P(0));
			else
				C(i) <= G(i) or (C(i-1) and P(i));
			end if;
		end loop;
	end process;
	
	S <= P xor C(N-2 downto 0) & Cin;
	Cout <= C(N-1);
end bhv;