
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main is
	port(
		clk: in std_logic
	);
end main;

architecture beh of main is
	signal instr_address: std_logic_vector(31 downto 0); -- Address of the instruction to run
	--signal next_address: std_logic_vector(31 downto 0); -- Next address to be loaded into PC
	signal instruction: std_logic_vector(31 downto 0); -- The actual instruction to run
	--signal last_instr_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000"; -- vhdl does not allow me to port map " y => incremented_address(31 downto 28) & shifted_jump_address "

	 -- Enum for checking if the instructions have loaded
     --type state is (loading, running, done);
     --signal s: state:= loading;

     	-- The clock for the other components; starts when the state is ready
	signal en: std_logic:= '0';

	-- Load the other components
	component program_counter
		port (
			clk: in std_logic;
			current_address: out std_logic_vector(31 downto 0)
		);
	end component;

	component instruction_memory
		port (
			read_address: in STD_LOGIC_VECTOR (31 downto 0);
			instruction: out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;

	begin
	
	en <= '1' when clk'event and clk = '1' else '0';

	PC: program_counter port map (en, instr_address); 

	IM: instruction_memory port map (instr_address, instruction);


    end beh;