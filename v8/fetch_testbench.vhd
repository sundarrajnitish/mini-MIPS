------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fetch_test_bench is
end fetch_test_bench;

architecture behavioral of fetch_test_bench is
    --common clock for all components
    signal en : std_logic := '0';

    --signals for branch_mux
    signal branch_load_address : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_address : std_logic_vector(31 downto 0) := (others => '0');
    signal jump : std_logic_vector(31 downto 0) := (others => '0');
    signal jump_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_mux_select : std_logic_vector(1 downto 0) := (others => '0');
    signal branch_mux_output : std_logic_vector(31 downto 0) := (others => '0');

    --signals for program_counter
    signal pc_write : std_logic := '0';
    signal pc_output : std_logic_vector(31 downto 0);

    --signals for instruction_memory
    signal im_output : std_logic_vector(31 downto 0);

    --signals for if_id_buffer
    signal if_id_flush : std_logic := '0';
    signal if_id_pc_4 : std_logic_vector(31 downto 0):= (others => '0');
    signal if_id_concat : std_logic_vector(3 downto 0):= (others => '0');
    signal if_id_opcode : std_logic_vector(5 downto 0):= (others => '0');
    signal if_id_funct : std_logic_vector(5 downto 0):= (others => '0');
    signal if_id_rs : std_logic_vector(4 downto 0):= (others => '0');
    signal if_id_rt : std_logic_vector(4 downto 0):= (others => '0');
    signal if_id_rd : std_logic_vector(4 downto 0):= (others => '0');
    signal if_id_shamt : std_logic_vector(4 downto 0):= (others => '0');
    signal if_id_immediate : std_logic_vector(15 downto 0):= (others => '0');
    signal if_id_jump_address : std_logic_vector(25 downto 0):= (others => '0');

begin 
    branch_mux: entity work.branch_mux
        port map(branch_address => branch_address, j => jump, jr => jump_reg, load_address => branch_load_address, select_signal => branch_mux_select, output_port => branch_mux_output);
    p_count: entity work.program_counter
        port map(clk => en, pc_write => pc_write, branch_address => branch_mux_output, output_address => pc_output);
    im: entity work.instruction_memory
        port map(clk => en, read_address => pc_output, instruction => im_output);
    if_id_buffer: entity work.if_id_buffer
        port map(clk => en, flush => if_id_flush, instruction => im_output, next_address => pc_output, pc_4 => if_id_pc_4, pc_concat => if_id_concat, opcode => if_id_opcode, funct => if_id_funct, rs => if_id_rs, rt => if_id_rt, rd => if_id_rd, shamt => if_id_shamt, immediate => if_id_immediate, jump_address => if_id_jump_address);

        process
        begin   
        for i in 0 to 20 loop
            en <= '1';
            wait for 10 ns;
            en <= '0';
            wait for 10 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end behavioral;
