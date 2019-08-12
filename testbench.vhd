library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;
use std.textio.all;--for file reading
use ieee.std_logic_textio.all;--for reading of std_logic_vectors


entity testbench is
end testbench;

architecture test of testbench is
-- "Time" that will elapse between test vectors we submit to the component.
constant TIME_DELTA : time := 10 ns;

signal  	A: std_logic_vector(31 downto 0);
signal	B: std_logic_vector(31 downto 0);
signal	op:std_logic_vector( 1 downto 0);
signal	result: std_logic_vector(31 downto 0);
--FLAGS (div by zero, overflow, underflow, etc)
signal divideByZero:	std_logic;
signal overflow: std_logic;
signal underflow: std_logic;
	
file 		file_vectors: text;-- open read_mode is "input_vectors.txt";--estrutura representando arquivo de entrada de dados

begin

	DUT: entity work.fpu
	port map(A 				=> A,
				B	 			=> B,
				op 			=> op,
				divideByZero=> divideByZero,
				overflow		=> overflow,
				underflow	=> underflow,
				result		=> result		
	);
	
	op <= "11";--always divide numbers
	
	-----------------------------------------------------------
	--	this process reads a file vector, loads its vectors,
	--	passes them to the DUT and checks the result.
	-----------------------------------------------------------
	process--parses text file
		variable v_iline: line;
		variable v_space: character;--stores the white space used to separate 2 arguments
		variable v_A: std_logic_vector(31 downto 0);--first argument
		variable v_B: std_logic_vector(31 downto 0);--second argument
	begin
		file_open(file_vectors,"input_vectors.txt",read_mode);--PRECISA FICAR NA PASTA simulation/modelsim
		
		while not endfile(file_vectors) loop
			readline(file_vectors,v_iline);--lê uma linha
			hread(v_iline,v_A);
			read(v_iline,v_space);
			hread(v_iline,v_B);
			
			A <= v_A;
			B <= v_B;
			
			wait for 10 ns;
		end loop;
		
		file_close(file_vectors);
		wait; --?
	end process;
end architecture test;