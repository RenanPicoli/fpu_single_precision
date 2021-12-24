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

signal CLK: std_logic;
signal expected_output: std_logic_vector(31 downto 0);
signal error_flag: std_logic;
	
file 		file_vectors_input: text;-- open read_mode is "input_vectors.txt";--estrutura representando arquivo de entrada de dados
file		file_vectors_octave: text;--represents octave results

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
	
--	op <= "00";--add numbers
--	op <= "01";--subtract numbers
	op <= "10";--multiply numbers
--	op <= "11";--divide numbers
	
	-----------------------------------------------------------
	--	this process reads a file vector, loads its vectors,
	--	passes them to the DUT and checks the result.
	-----------------------------------------------------------
	process--parses input text file
		variable v_iline: line;
		variable v_space: character;--stores the white space used to separate 2 arguments
		variable v_A: std_logic_vector(31 downto 0);--first argument
		variable v_B: std_logic_vector(31 downto 0);--second argument
	begin
		file_open(file_vectors_input,"input_vectors.txt",read_mode);--PRECISA FICAR NA PASTA simulation/modelsim
		
		while not endfile(file_vectors_input) loop
			readline(file_vectors_input,v_iline);--lê uma linha
			hread(v_iline,v_A);
			readline(file_vectors_input,v_iline);--lê a linha seguinte
			hread(v_iline,v_B);
			
			A <= v_A;
			B <= v_B;
			
			wait until rising_edge(CLK);--rising_edge(CLK)
		end loop;
		
		file_close(file_vectors_input);
		wait; --?
	end process;
	
	-----------------------------------------------------------
	--	this process reads a file vector, loads expected results calculated by octave,
	--	and compare the results.
	-----------------------------------------------------------
	process--parses input text file
		variable v_iline: line;
		variable v_space: character;--stores the white space used to separate 2 arguments
		variable v_A: std_logic_vector(31 downto 0);--expected result
	begin
		file_open(file_vectors_octave,"octave_results.txt",read_mode);--PRECISA FICAR NA PASTA simulation/modelsim
		
		while not endfile(file_vectors_octave) loop
			readline(file_vectors_octave,v_iline);--lê uma linha
			hread(v_iline,v_A);
			read(v_iline,v_space);
			
			expected_output <= v_A;
			
			wait until rising_edge(CLK);--rising_edge(CLK)
		end loop;
		
		file_close(file_vectors_octave);
		wait; --?
	end process;
	
	
	test: process(expected_output,result,CLK)
	begin
		if(falling_edge(CLK)) then
			if (expected_output /= result) then
				error_flag <= '1';
			else
				error_flag <= '0';
			end if;
		end if;
	end process;
	
	clock: process--100MHz input clock
	begin
		CLK <= '1';
		wait for 5 ns;
		CLK <= '0';
		wait for 5 ns;
	end process clock;
end architecture test;