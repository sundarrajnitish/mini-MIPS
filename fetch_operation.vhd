
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main is
	port(
		ck: in std_logic
	);
end main;

architecture beh of main is
	signal instr_address: std_logic_vector(31 downto 0); -- Address of the instruction to run
	signal next_address: std_logic_vector(31 downto 0); -- Next address to be loaded into PC
	signal instruction: std_logic_vector(31 downto 0); -- The actual instruction to run
	signal last_instr_address: std_logic_vector(31 downto 0):= "00000000000000000000000000000000"; -- vhdl does not allow me to port map " y => incremented_address(31 downto 28) & shifted_jump_address "

	 -- Enum for checking if the instructions have loaded
     type state is (loading, running, done);
     signal s: state:= loading;

     	-- The clock for the other components; starts when the state is ready
	signal en: std_logic:= '0';

	-- Load the other components
	component pc
		port (
			ck: in std_logic;
			address_to_load: in std_logic_vector(31 downto 0);
			current_address: out std_logic_vector(31 downto 0)
		);
	end component;
	component instruction_memory
		port (
			read_address: in STD_LOGIC_VECTOR (31 downto 0);
			instruction, last_instr_address: out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;

    begin

        process(ck)
		begin
		case s is
			when running =>
				en <= ck;
			when others =>
				en <= '0';
		end case;

		if ck='1' and ck'event then
			case s is
				when loading =>
					s <= running; -- give 1 cycle to load the instructions into memory
				when running =>
					if instr_address > last_instr_address then
						s <= done; -- stop moving the pc after it has passed the last instruction
						en <= '0';
					end if;
				when others =>
					null;
			end case;
		end if;
		next_address <= instr_address + 1; -- increment the pc by 4
	end process;

	Prog_Count: pc port map (en, next_address, instr_address); 

	IM: instruction_memory port map (instr_address, instruction, last_instr_address);

    end beh;