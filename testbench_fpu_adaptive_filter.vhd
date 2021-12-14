library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;--for floor(), ceil()
use work.all;
use std.textio.all;--for file reading
use ieee.std_logic_textio.all;--for reading of std_logic_vectors

use work.my_types.all;


entity testbench is
end testbench;

architecture test of testbench is

component fpu is
port (
	A: in std_logic_vector(31 downto 0);--supposed to be normalized
	B: in std_logic_vector(31 downto 0);--supposed to be normalized
	op:in std_logic_vector(1  downto 0);--4 operations: add,subtract, multiply,divide
	divideByZero:	out std_logic;
	overflow:		out std_logic;
	underflow:		out std_logic;
	result:out std_logic_vector(31 downto 0)
);
end component;

component generic_coeffs_mem
	-- 0..P: índices dos coeficientes de x (b)
	-- 1..Q: índices dos coeficientes de y (a)
	generic	(N: natural; P: natural; Q: natural);--N address width in bits
	port(	D:	in std_logic_vector(31 downto 0);-- um coeficiente é atualizado por vez
			ADDR: in std_logic_vector(N-1 downto 0);--se ALTERAR P, Q PRECISA ALTERAR AQUI
			RST:	in std_logic;--asynchronous reset
			RDEN:	in std_logic;--read enable
			WREN:	in std_logic;--write enable
			CLK:	in std_logic;
			filter_CLK:	in std_logic;--to synchronize read with filter (coeffs are updated at rising_edge)
			filter_WREN: in std_logic;--filter write enable, used to check if all_coeffs must be used
			parallel_write_data: in array32 (0 to 2**N-1);
			parallel_wren: in std_logic;
			parallel_rden: in std_logic;
			parallel_read_data: out array32 (0 to 2**N-1);--used when peripherals other than filter
			Q_coeffs: out std_logic_vector(31 downto 0);--single coefficient reading
			all_coeffs:	out array32((P+Q) downto 0)-- all VALID coefficients are read at once by filter through this port
	);
end component;

---------------------------------------------------

component filter
	-- 0..P: índices dos coeficientes de x (b)
	-- 1..Q: índices dos coeficientes de y (a)
	generic	(P: natural; Q: natural);
	port(	input:in std_logic_vector(31 downto 0);-- input
			RST:	in std_logic;--synchronous reset
			WREN:	in std_logic;--enables writing on coefficients
			CLK:	in std_logic;--sampling clock
			coeffs:	in array32((P+Q) downto 0);-- todos os coeficientes são lidos de uma vez
			IACK: in std_logic;--iack
			IRQ:	out std_logic;--interrupt request: new sample arrived
			output: out std_logic_vector(31 downto 0)-- output
	);

end component;

---------------------------------------------------

component d_flip_flop
		port (D:	in std_logic_vector(31 downto 0);
				RST: in std_logic;
				ENA:	in std_logic:='1';--enables writes
				CLK:in std_logic;
				Q:	out std_logic_vector(31 downto 0)  
				);
	end component;

---------------------------------------------------

component pll_dbg_uproc
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1 	: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component;

---------------------------------------------------

--produces 12MHz from 50MHz
component pll_12MHz
	port
	(
		areset		: in std_logic  := '0';
		inclk0		: in std_logic  := '0';
		c0				: out std_logic 
	);
end component;
---------------------------------------------------
--produces fs and 256fs from 12MHz
component pll_audio
	port
	(
		areset		: in std_logic  := '0';
		inclk0		: in std_logic  := '0';
		c0				: out std_logic;
		c1				: out std_logic;
		c2				: out std_logic;
		locked		: out std_logic
	);
end component;

---------------------------------------------------

component inner_product_calculation_unit
generic	(N: natural);--N: address width in bits
port(	D: in std_logic_vector(31 downto 0);
		ADDR: in std_logic_vector(N-1 downto 0);
		CLK: in std_logic;
		RST: in std_logic;
		WREN: in std_logic;
		RDEN: in std_logic;
		parallel_write_data: in array32 (0 to 2**(N-2)-1);
		parallel_wren_A: in std_logic;
		parallel_wren_B: in std_logic;
		parallel_rden_A: in std_logic;--enables parallel read (to shared data bus)
		parallel_rden_B: in std_logic;--enables parallel read (to shared data bus)
		parallel_read_data: out array32 (0 to 2**(N-2)-1);
		output: out std_logic_vector(31 downto 0)-- output
);
end component;

---------------------------------------------------

component vectorial_multiply_accumulator_unit
generic	(N: natural);--N: address width in bits
port(	D: in std_logic_vector(31 downto 0);-- input
		ADDR: in std_logic_vector(N-1 downto 0);-- input
		CLK: in std_logic;-- input
		RST: in std_logic;-- input
		WREN: in std_logic;-- input
		RDEN: in std_logic;-- input
		VMAC_EN: in std_logic;-- input: enables accumulation
		parallel_write_data: in array32 (0 to 2**(N-2)-1);
		parallel_wren_A: in std_logic;
		parallel_wren_B: in std_logic;
		parallel_rden_A: in std_logic;--enables parallel read (to shared data bus)
		parallel_rden_B: in std_logic;--enables parallel read (to shared data bus)
		parallel_read_data: out array32 (0 to 2**(N-2)-1);
		output: out std_logic_vector(31 downto 0)-- output
);

end component;

---------------------------------------------------

component filter_xN
-- 0..P: índices dos x
-- P+1..P+Q: índices dos y
generic	(N: natural; P: natural; Q: natural);--N: address width in bits (must be >= log2(P+1+Q))
port(	D: in std_logic_vector(31 downto 0);-- not used (peripheral is read-only)
		DX: in std_logic_vector(31 downto 0);--current filter input
		DY: in std_logic_vector(31 downto 0);--current filter output
		ADDR: in std_logic_vector(N-1 downto 0);-- input
		CLK_x: in std_logic;-- must be filter clock (input sampling)
		CLK_y: in std_logic;-- must be not filter clock (output storing)
		RST: in std_logic;-- input
		WREN: in std_logic;--not used (peripheral supports only read)
		RDEN: in std_logic;-- input
		parallel_write_data: in array32 (0 to 2**N-1);--not used
		parallel_wren: in std_logic;--not used
		parallel_rden: in std_logic;--enables parallel read (to shared data bus)
		parallel_read_data: out array32 (0 to 2**N-1);
		output: out std_logic_vector(31 downto 0)-- output
);
end component;


--reset duration must be long enough to be perceived by the slowest clock (filter clock, both polarities)
constant TIME_RST : time := 50 us;
-- internal clock period.
constant TIME_DELTA : time := 20 ns;

--simulates software writing '1' to bit 0 of filter_ctrl_status register
constant TIME_SW_FILTER_ENABLE : time := 160135 ns;

--simulates software writing '1' to bit 0 of proc_filter_wren register
constant TIME_SW_FILTER_WREN : time := 200 us;

--simulates time for a instuction to complete (@4MHz)
constant TIME_INSTRUCTION : time := 250 ns;

signal  	CLK_IN:std_logic;--50MHz
signal	rst: std_logic;

----------standalone fpu signals----------------
signal fpu_A: std_logic_vector (31 downto 0);
signal fpu_B: std_logic_vector (31 downto 0);
signal fpuControl: std_logic_vector (1 downto 0);--FPU operation selector
signal fpu_result: std_logic_vector (31 downto 0);
signal fpu_flags: std_logic_vector(31 downto 0);--flags da FPU

-------------------clocks---------------------------------
--signal rising_CLK_occur: std_logic;--rising edge of CLK occurred after filter_CLK falling edge
signal CLK: std_logic;--clock for processor and cache (50MHz)
signal CLK_dbg: std_logic;--clock for debug, check timing analyzer or the pll_dbg wizard
signal CLK_fs: std_logic;-- 11.029kHz clock
signal CLK_fs_dbg: std_logic;-- 110.29kHz clock
signal CLK16_928571MHz: std_logic;-- 16.928571MHz clock (1536fs, for I2S peripheral)
signal CLK12MHz: std_logic;-- 12MHz clock (MCLK for audio codec)

signal i2s_SCK_IN_PLL_LOCKED: std_logic;--'1' if PLL that provides SCK_IN is locked

signal sample_number: std_logic_vector(7 downto 0);--used to generate address for data_in_rom_ip and desired_rom_ip

----------adaptive filter algorithm inputs----------------
signal data_in: std_logic_vector(31 downto 0);--data to be filtered (encoded in IEEE 754 single precision)
signal desired: std_logic_vector(31 downto 0);--desired response (encoded in IEEE 754 single precision)
signal expected_output: std_logic_vector(31 downto 0);--expected filter output (encoded in IEEE 754 single precision, generated at modelsim)
signal data_in_array: array_of_std_logic_vector (0 to 255);--data to be filtered (encoded in IEEE 754 single precision)
signal desired_array: array_of_std_logic_vector (0 to 255);--desired response (encoded in IEEE 754 single precision)
signal expected_output_array: array_of_std_logic_vector (0 to 255);--expected filter output (encoded in IEEE 754 single precision, generated at modelsim)
signal expected_output_delayed: std_logic_vector(31 downto 0);--expected filter output delayed one filter_CLK clock cycle
signal error_flag: std_logic;-- '1' if expected_output is different from actual filter output

signal filter_CLK: std_logic;
signal filter_CLK_n: std_logic;--filter_CLK inverted
signal filter_parallel_wren: std_logic;
signal filter_rst: std_logic := '1';
signal filter_input: std_logic_vector(31 downto 0);
signal filter_output: std_logic_vector(31 downto 0);
signal filter_irq: std_logic;
signal filter_iack: std_logic;
signal proc_filter_parallel_wren: std_logic;

signal filter_enable: std_logic;--bit 0, enables filter_CLK
signal filter_CLK_state: std_logic := '0';--starts in zero, changes to 1 when first rising edge of filter_CLK occurs

--signals for coefficients memory----------------------------
--constant P: natural := 2;
constant P: natural := 3;
--constant Q: natural := 2;
--constant Q: natural := 0;--forces  FIR filter
constant Q: natural := 4;
signal coeffs_mem_Q: std_logic_vector(31 downto 0);--signal for single coefficient reading
signal coefficients: array32 (P+Q downto 0);
signal coeffs_mem_wren: std_logic;
signal coeffs_mem_rden: std_logic;
signal coeffs_mem_parallel_rden: std_logic;
signal coeffs_mem_parallel_wren: std_logic;

-----------signals for RAM interfacing---------------------
---processor sees all memory-mapped I/O as part of RAM-----
constant N: integer := 7;-- size in bits of data addresses (each address refers to a 32 bit word)
signal ram_clk: std_logic;--data memory clock signal
signal ram_addr: std_logic_vector(N-1 downto 0);
signal ram_rden: std_logic;
signal ram_wren: std_logic;
signal ram_write_data: std_logic_vector(31 downto 0);
--signal ram_Q: std_logic_vector(31 downto 0);
signal ram_Q_buffer_in: std_logic_vector(31 downto 0);
signal ram_Q_buffer_out: std_logic_vector(31 downto 0);

--signals for inner_product----------------------------------
signal inner_product_result: std_logic_vector(31 downto 0);
signal inner_product_rden: std_logic;
signal inner_product_wren: std_logic;
signal inner_product_parallel_rden_A: std_logic;
signal inner_product_parallel_wren_A: std_logic;
signal inner_product_parallel_rden_B: std_logic;
signal inner_product_parallel_wren_B: std_logic;

--signals for vmac-------------------------------------------
signal vmac_Q: std_logic_vector(31 downto 0);
signal vmac_rden: std_logic;
signal vmac_wren: std_logic;--enables write on individual registers
signal vmac_en:	std_logic;--enables accumulation
signal vmac_parallel_rden_A: std_logic;
signal vmac_parallel_rden_B: std_logic;
signal vmac_parallel_wren_A: std_logic;
signal vmac_parallel_wren_B: std_logic;

--signals for filter_xN--------------------------------------
signal filter_xN_CLK: std_logic;-- must be the same frequency as filter clock, but can't be the same polarity
signal filter_xN_Q: std_logic_vector(31 downto 0) := (others=>'0');
signal filter_xN_rden: std_logic;
signal filter_xN_wren: std_logic;
signal filter_xN_parallel_rden: std_logic;
signal filter_xN_parallel_wren: std_logic;

--signals for vector transfers
signal lvec: std_logic;
signal lvec_src: std_logic_vector(2 downto 0);
signal lvec_dst_mask: std_logic_vector(6 downto 0);
signal vector_bus: array32 (0 to 7);--shared data bus for parallel write of 8 fp32

constant fs : integer := 22050;--frequência de amostragem do filtro

signal	data_out:std_logic_vector(31 downto 0);
signal	instruction_addr:std_logic_vector(31 downto 0);
signal	instruction_number: natural := 0;-- number of the instruction being executed

constant c_WIDTH : natural := 4;
file 		input_file: text;-- open read_mode;--estrutura representando arquivo de entrada de dados
file 		desired_file: text;-- open read_mode;--estrutura representando arquivo de entrada de dados
file 		output_file: text;-- open write_mode;--estrutura representando arquivo de saída de dados

constant COUNT_MAX: integer := 
integer(floor(real(real(fs)*real(TIME_DELTA/1 us)/1000000.0)/real(2.0*(1.0-real(fs)*real(TIME_DELTA/1 us)/1000000.0))));

constant FILTER_CLK_SEMIPERIOD: time := 22_675_736.961 ps;--maximum precision allowed by vhdl would be fs, but constant wouldnt fit an integer

begin	
	-----------------------------------------------------------
	--	this process reads a file vector, loads its vectors,
	--	passes them to the DUT and checks the result.
	-----------------------------------------------------------
	reading_process: process--parses input text file
		variable v_space: character;--stores the white space used to separate 2 arguments
		variable v_A: std_logic_vector(31 downto 0);--input of filter
		variable v_B: std_logic_vector(31 downto 0);--desired response
		variable v_iline_A: line;
		variable v_iline_B: line;
		
		variable count: integer := 0;-- para sincronização da apresentação de amostras
		
	begin
		file_open(input_file,"input_vectors.txt",read_mode);--PRECISA FICAR NA PASTA simulation/modelsim
		file_open(desired_file,"desired_vectors.txt",read_mode);--PRECISA FICAR NA PASTA simulation/modelsim
		
		wait for TIME_RST+2*FILTER_CLK_SEMIPERIOD;--wait until reset finishes
--		wait until filter_CLK ='1';-- waits until the first rising edge after reset
--		wait for (TIME_DELTA/2);-- additional delay (rising edge of sampling will be in the middle of sample)
		wait until filter_CLK ='0';-- waits for first falling EDGE after reset
		
		while not endfile(input_file) loop
			readline(input_file,v_iline_A);--lê uma linha do arquivo de entradas
			hread(v_iline_A,v_A);
--			read(v_iline,v_space);
--			hread(v_iline,v_B);
			
			data_in <= v_A;-- assigns input to filter
			
			readline(desired_file,v_iline_B);--lê uma linha do arquivo de resposta desejada
			hread(v_iline_B,v_B);
			desired <= v_B;-- assigns desired response to the algorithm
			
			-- IMPORTANTE: CONVERSÃO DE TEMPO PARA REAL
			-- se FILTER_CLK_SEMIPERIOD em ms, use 1000 e 1 ms
			-- se FILTER_CLK_SEMIPERIOD em us, use 1000000 e 1 us
			-- se FILTER_CLK_SEMIPERIOD em ns, use 1000000000 e 1 ns
			-- se FILTER_CLK_SEMIPERIOD em ps, use 1000000000000 e 1 ps
			if (count = COUNT_MAX) then
				wait until filter_CLK ='1';-- waits until the first rising edge occurs
				wait for (FILTER_CLK_SEMIPERIOD);-- reestabelece o devido delay entre amostras e clock de amostragem
			else
				if (count = COUNT_MAX + 1) then
					count := 0;--variable assignment takes place immediately
				end if;
				wait for 2*FILTER_CLK_SEMIPERIOD;-- usual delay between 2 samples
			end if;
			count := count + 1;--variable assignment takes place immediately
		end loop;
		
		file_close(input_file);

		wait; --?
	end process;
	
	--reads adaptive filter response
	write_proc: process(data_out, filter_CLK)--writing output file every time data_out changes introduces spurious pulses
		variable v_oline: line;
		variable v_C: std_logic_vector(31 downto 0);--data to be written
	begin
		if (filter_CLK'event and filter_CLK='0') then-- falling_edge(filter_CLK): when outputs are sampled in filter and xN
			file_open(output_file,"output_vectors.txt",append_mode);--PRECISA FICAR NA PASTA simulation/modelsim
			
			v_C := data_out;
			hwrite(v_oline, v_C);--write values in hex notation
--			write(v_oline,string'(" "));
--			write(v_oline,time'image(now));
			writeline(output_file, v_oline);
				
			file_close(output_file);
		end if;
	end process;
												
	floating_point_unity: fpu port map (A => fpu_A,
													B => fpu_B,
													op=> fpuControl,
													divideByZero => fpu_flags(0),
													overflow	=> fpu_flags(1),
													underflow=> fpu_flags(2),
													result	=> fpu_result
												);
	fpu_flags(31 downto 3) <= (others=>'0');
	
----------------------------------------------------------
	filter_CLK_n <= not filter_CLK;
	--index of sample being fetched
	--generates address for reading ROM IP's
	--counts from 0 to 255 and then restarts
	counter: process(rst,filter_rst,filter_CLK)
	begin
		if(rst='1' or filter_rst='1')then
			sample_number <= (others=>'0');
		elsif(rising_edge(filter_CLK) and filter_rst='0')then--this ensures, count is updated after used for sram_ADDR
			sample_number <= sample_number + 1;
		end if;
	end process;
		
		process(rst,filter_CLK_n,expected_output)
		begin
			if(rst='1')then
				expected_output_delayed <= (others=>'0');
			elsif(rising_edge(filter_CLK_n))then
				expected_output_delayed <= expected_output;
			end if;
		end process; 
		
		test: process(expected_output_delayed,filter_output,filter_rst,filter_CLK)
		begin
			if(filter_rst='1')then
				error_flag <= '0';
			elsif(rising_edge(filter_CLK)) then
				if (expected_output_delayed /= filter_output) then
					error_flag <= '1';
				else
					error_flag <= '0';
				end if;
			end if;
		end process;
		
		--simulates software writing '1' to bit 0 of filter_ctrl_status register
		filter_enable <= '1';
						
		filter_reset_process: process (filter_CLK,RST,filter_CLK_state,filter_enable,i2s_SCK_IN_PLL_LOCKED)
		begin
			if(RST='1')then
				filter_rst <='1';
				filter_CLK_state <= '0';
			else
				if (rising_edge(filter_CLK) and i2s_SCK_IN_PLL_LOCKED='1') then--pll_audio must be locked
					filter_CLK_state <= '1';
				end if;
				if (falling_edge(filter_CLK) and filter_CLK_state = '1' and filter_enable='1' and i2s_SCK_IN_PLL_LOCKED='1') then
						filter_rst <= '0';
				end if;
			end if;
		end process filter_reset_process;

	process(RST,proc_filter_parallel_wren,filter_CLK)
	begin
		if(RST='1')then
			filter_parallel_wren <= '0';
		elsif(proc_filter_parallel_wren=	'1')then
			filter_parallel_wren <= '1';
		elsif(rising_edge(filter_CLK))then--next rising_edge of filter means next sample, so filter_parallel_wren must be reset
			filter_parallel_wren <= '0';
		end if;
	end process;
		
	
	coeffs_mem_parallel_rden <= '1' when (lvec='1' and lvec_src="000") else '0';
	coeffs_mem_parallel_wren <= lvec_dst_mask(0);
	coeffs_mem: generic_coeffs_mem generic map (N=> 3, P => P,Q => Q)
									port map(D => ram_write_data,
												ADDR	=> ram_addr(2 downto 0),
												RST => rst,
												RDEN	=> coeffs_mem_rden,
												WREN	=> coeffs_mem_wren,
												CLK	=> ram_clk,
												filter_CLK => filter_CLK,
												filter_WREN => filter_parallel_wren,
												parallel_write_data => vector_bus,
												parallel_rden => coeffs_mem_parallel_rden,
												parallel_wren => coeffs_mem_parallel_wren,
												parallel_read_data => vector_bus,
												Q_coeffs => coeffs_mem_Q,
												all_coeffs => coefficients
												);

	filter_CLK <= CLK_fs;
	proc_filter_parallel_wren <= lvec_dst_mask(1);
	IIR_filter: filter 	generic map (P => P, Q => Q)
								port map(input => filter_input,-- input
											RST => filter_rst,--synchronous reset
											WREN => filter_parallel_wren,--enables updating all coefficients at once
											CLK => filter_CLK,--sampling clock
											coeffs => coefficients,-- todos os coeficientes são lidos de uma vez
											iack => filter_iack,
											irq => filter_irq,
											output => filter_output											
											);
	filter_input <= data_in;
	
	ram_clk <= not CLK;
	
	inner_product_parallel_rden_A <= '1' when (lvec='1' and lvec_src="011") else '0';
	inner_product_parallel_rden_B <= '1' when (lvec='1' and lvec_src="100") else '0';
	inner_product_parallel_wren_A <= lvec_dst_mask(3);
	inner_product_parallel_wren_B <= lvec_dst_mask(4);
	inner_product: inner_product_calculation_unit
	generic map (N => 5)
	port map(D => ram_write_data,--supposed to be normalized
				ADDR => ram_addr(4 downto 0),
				CLK => ram_clk,
				RST => rst,
				WREN => inner_product_wren,
				RDEN => inner_product_rden,
				parallel_write_data => vector_bus,
				parallel_rden_A => inner_product_parallel_rden_A,
				parallel_wren_A => inner_product_parallel_wren_A,
				parallel_rden_B => inner_product_parallel_rden_B,
				parallel_wren_B => inner_product_parallel_wren_B,
				parallel_read_data => vector_bus,
				-------NEED ADD FLAGS (overflow, underflow, etc)
				--overflow:		out std_logic,
				--underflow:		out std_logic,
				output => inner_product_result
				);
	
	vmac_parallel_rden_A <= '1' when (lvec='1' and lvec_src="101") else '0';
	vmac_parallel_rden_B <= '1' when (lvec='1' and lvec_src="110") else '0';
	vmac_parallel_wren_A <= lvec_dst_mask(5);
	vmac_parallel_wren_B <= lvec_dst_mask(6);
	vmac: vectorial_multiply_accumulator_unit
	generic map (N => 5)
	port map(D => ram_write_data,
				ADDR => ram_addr(4 downto 0),
				CLK => ram_clk,
				RST => rst,
				WREN => vmac_wren,
				RDEN => vmac_rden,
				VMAC_EN => vmac_en,
				parallel_write_data => vector_bus,
				parallel_rden_A => vmac_parallel_rden_A,
				parallel_wren_A => vmac_parallel_wren_A,
				parallel_rden_B => vmac_parallel_rden_B,
				parallel_wren_B => vmac_parallel_wren_B,
				parallel_read_data => vector_bus,
				-------NEED ADD FLAGS (overflow, underflow, etc)
				--overflow:		out std_logic,
				--underflow:		out std_logic,
				output => vmac_Q
	);
	
	-- must be the clock of filter output updating
	filter_xN_CLK <= not filter_CLK;
	filter_xN_parallel_rden <= '1' when (lvec='1' and lvec_src="010") else '0';
	filter_xN_parallel_wren <= lvec_dst_mask(2);
	xN: filter_xN
	-- 0..P: índices dos x
	-- P+1..P+Q: índices dos y
	generic map (N => 3, P => P, Q => Q)--N: address width in bits (must be >= log2(P+1+Q))
	port map (	D => ram_write_data,-- not used (peripheral supports only read)
			DX => filter_input,--current filter input
			DY => filter_output,--current filter output
			ADDR => ram_addr(2 downto 0),-- input
			CLK_x => filter_CLK,
			CLK_y => filter_xN_CLK,-- must be the same frequency as filter clock, but can't be the same polarity
			RST => filter_rst,
			WREN => filter_xN_wren,--not used (peripheral supports only read)
			RDEN => filter_xN_rden,-- input
			parallel_write_data => vector_bus,
			parallel_rden => filter_xN_parallel_rden,
			parallel_wren => filter_xN_parallel_wren,
			parallel_read_data => vector_bus,
			output => filter_xN_Q-- output
			);
			
	--emulates processor instructions being executed
	uproc: process
		variable r1: std_logic_vector(31 downto 0) := (others => '0');
		constant r2: std_logic_vector(31 downto 0) := x"3851B717";-- 5E-5
		variable r5: std_logic_vector(31 downto 0) := (others => '0');
		variable r6: std_logic_vector(31 downto 0) := x"7FFFFFFF";
		variable r8: std_logic_vector(31 downto 0) := (others => '0');
		variable r9: std_logic_vector(31 downto 0) := (others => '0');
		variable r10: std_logic_vector(31 downto 0) := (others => '0');
	begin
		if (rst='1')then
			lvec  <= '0';
			lvec_src <= (others=>'0');
			lvec_dst_mask <= (others=>'0');
			fpu_A <= (others=>'0');
			fpu_B <= (others=>'0');
			fpuControl <= "00";
			vmac_en <= '0';
		else
			--new sample arrived (filter IRQ ='1')
			wait until rising_edge(filter_CLK) and filter_rst='0';
			lvec  <= '1';
			lvec_src <= "010";--filter_xN is source
			lvec_dst_mask <= "1011000";--destinations are inner_product (A, B) and vmac:B
			wait for TIME_INSTRUCTION;
			--VHDL 2008 specific feature: inspecting internal values
			r1 := <<signal inner_product.result : std_logic_vector(31 downto 0) >>;--squared norm
			lvec  <= '0';
			lvec_src <= (others=>'0');
			lvec_dst_mask <= (others=>'0');
			wait for TIME_INSTRUCTION;
			fpu_A <= r1;
			fpu_B <= r2;
			fpuControl <= "01";-- subtraction
			wait for TIME_INSTRUCTION/2;
			r5 := fpu_result; -- r5 := r1-r2
			r6 := x"3F800000";-- 1.0
			wait for TIME_INSTRUCTION/2;
			if r5(31) = '1' then -- testa quem é maior: cte ou squared norm, pega a MAIOR
				-- fdiv r6 r2 r1; r1 <- 1/(5E-5), r1*erro será o escalar na atualização do filtro
				fpu_A <= r6;
				fpu_B <= r2;
				fpuControl <= "11";--division
			else
				-- fdiv r6 r1 r1; r1 <- 1/(sq norm), r1*erro será o escalar na atualização do filtro
				fpu_A <= r6;
				fpu_B <= r1;
				fpuControl <= "11";--division
			end if;
			wait for TIME_INSTRUCTION/2;
			r1 := fpu_result;
			wait for TIME_INSTRUCTION/2;
			--new instruction
			r8 := <<signal IIR_filter.output : std_logic_vector(31 downto 0) >>;--resposta do filtro
			r9 := desired;
			wait for TIME_INSTRUCTION;
			-- fsub r9 r8 r10; Calcula e armazena o erro (d-y) em r10
			fpu_A <= r9;
			fpu_B <= r8;
			fpuControl <= "01";-- subtraction
			wait for TIME_INSTRUCTION/2;
			r10 := fpu_result;
			wait for TIME_INSTRUCTION/2;
			-- fmul r1 r10 r1 ; r1 <- (2*step)*erro		
			fpu_A <= r1;
			fpu_B <= r10;
			fpuControl <= "10";--multiplication
			wait for TIME_INSTRUCTION/2;
			r1 := fpu_result;
			wait for TIME_INSTRUCTION/2;
			-- sw [r4 + 64] r1; armazena 2*step*erro no lambda
			-- VHDL 2008 allows injection
			<<signal vmac.lambda_out : std_logic_vector(31 downto 0) >> <= force r1;
			wait for TIME_INSTRUCTION;
			--	Carrega VMAC:A(5) com as componentes do filtro atual(0)
			-- lvec x"00" x"20";
			lvec  <= '1';
			lvec_src <= "000";--coeffs_mem is the source
			lvec_dst_mask <= "0100000";--destination is vmac:A
			wait for TIME_INSTRUCTION;
			--vmac; enables accumulation
			lvec  <= '0';
			vmac_en <= '1';
			wait for TIME_INSTRUCTION;		
			vmac_en <= '0';
			--	Lê o acumulador do VMAC(5) e atualiza os coeficientes do filtro(0)
			-- lvec x"05" x"01";
			lvec  <= '1';
			lvec_src <= "101";--vmac:A is the source
			lvec_dst_mask <= "0000001";--destination is coeffs_mem
			wait for TIME_INSTRUCTION;
			--	Lê memória de coeficientes do filtro(0) para o filtro(1)
			-- enables filter to update its components (when filter_CLK rises)
			-- lvec x"00" x"02";		
			lvec  <= '1';
			lvec_src <= "000";--coeffs_mem is the source
			lvec_dst_mask <= "0000010";--destination is IIR_filter
			wait for TIME_INSTRUCTION;
			lvec <= '0';
	--		wait;
	end if;
	end process;
	
	clock: process--50MHz input clock
	begin
		CLK_IN <= '0';
		wait for 10 ns;
		CLK_IN <= '1';
		wait for 10 ns;
	end process clock;
	
	rst <= '1', '0' after TIME_RST;--reset must be long enough to be perceived by the slowest clock (fifo)
	
	clk_dbg_uproc:	pll_dbg_uproc
	port map
	(
		areset=> '0',
		inclk0=> CLK_IN,
		c0		=> CLK_dbg,
		c1		=> CLK,--produces CLK=4MHz for processor
		locked=> open
	);

	--produces 12MHz (MCLK) from 50MHz input
	clk_12MHz: pll_12MHz
	port map (
	inclk0 => CLK_IN,
	areset => rst,
	c0 => CLK12MHz
	);

	--produces 11025Hz (fs) and 16.928571 MHz (1536fs for BCLK_IN) from 12MHz input
	clk_fs_1536fs: pll_audio
	port map (
	inclk0 => CLK12MHz,
	areset => rst,
	c0 => CLK_fs,
	c1 => CLK16_928571MHz,
	c2 => CLK_fs_dbg,--10x fs
	locked => i2s_SCK_IN_PLL_LOCKED
	);
	
end architecture test;