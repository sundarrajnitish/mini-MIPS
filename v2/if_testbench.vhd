------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fetch_testbench is
	port(
		clk: in std_logic := '0';
        pc_out, instruction_out: out std_logic_vector(31 downto 0)
	);
end fetch_testbench;

architecture behavioral of fetch_testbench is
	signal instr_address: std_logic_vector(31 downto 0); -- Address of the instruction to run
	signal instruction: std_logic_vector(31 downto 0); -- The actual instruction to run

    signal pc_in, instruction_in: std_logic_vector(31 downto 0) := (others => '0');

    signal cc: std_logic:= '0'; -- The clock for the other components; starts when the state is ready

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
            clk: in STD_LOGIC;
			read_address: in STD_LOGIC_VECTOR (31 downto 0);
			instruction: out STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;

    component if_id_buffer
        port (
            clk, reset, enable : in std_logic;
            pc_in, instruction_in : in std_logic_vector(31 downto 0);
            pc_out, instruction_out : out std_logic_vector(31 downto 0)
          );
    end component;

	begin
	
	--en <= '1' when clk'event and clk = '1' else '0';

    en <= '1' when cc'event and cc = '1' else '0';

	PC: program_counter port map (en, instr_address); 

	IM: instruction_memory port map (en, instr_address, instruction);

    IF_ID: if_id_buffer port map (en, '0', '1', instr_address, instruction, pc_out, instruction_out);

    process
    begin
        for i in 1 to 5 loop
            cc <= '1';
            wait for 1 ns;
            cc <= '0';
            wait for 1 ns;
        end loop;
        wait;
    end process;

    end behavioral;