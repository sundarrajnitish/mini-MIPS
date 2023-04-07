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

entity test_bench is
end test_bench;

architecture behavioral of test_bench is
    --common clock for all components
    signal clk : std_logic := '0';

    --signals for if_mux_1
    signal pc : std_logic_vector(31 downto 0) := (others => '0');
    signal branch : std_logic_vector(31 downto 0) := (others => '0');
    signal mux_1_select : std_logic := '0';
    signal mux_1_output : std_logic_vector(31 downto 0);

    --signals for if_mux_2
    signal jump : std_logic_vector(31 downto 0) := (others => '0');
    signal jump_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal mux_2_select : std_logic_vector(1 downto 0) := (others => '0');
    signal mux_2_output : std_logic_vector(31 downto 0);

    --signals for program_counter
    signal pc_output : std_logic_vector(31 downto 0);
    signal pc_4_2 : std_logic_vector(31 downto 0);

    --signals for instruction_memory
    signal im_output : std_logic_vector(31 downto 0);

    --signals for if_id_buffer
    signal if_id_buffer_output : std_logic_vector(63 downto 0);
    signal if_id_flush : std_logic := '0';
    signal if_id_pc_4 : std_logic_vector(31 downto 0);
    signal if_id_concat : std_logic_vector(3 downto 0);
    signal if_id_opcode : std_logic_vector(5 downto 0);
    signal if_id_funct : std_logic_vector(5 downto 0);
    signal if_id_rs : std_logic_vector(4 downto 0);
    signal if_id_rt : std_logic_vector(4 downto 0);
    signal if_id_rd : std_logic_vector(4 downto 0);
    signal if_id_shamt : std_logic_vector(4 downto 0);
    signal if_id_immediate : std_logic_vector(15 downto 0);
    signal if_id_jump_address : std_logic_vector(25 downto 0);

begin 
    mux_1: entity work.if_mux_1
        port map(pc_4 => pc, branch_address => branch, select_signal => mux_1_select, output_port => mux_1_output);
    mux_2: entity work.if_mux_2
        port map(address => pc, j => jump, jr => jump_reg, select_signal => mux_2_select, output_port => mux_2_output);
    p_count: entity work.program_counter
        port map(clk => clk, input_address => mux_2_output, next_address => pc, output_address => pc_output);
    --im: entity work.instruction_memory
        --port map(clk => clk, read_address => pc_output, instruction => im_output);
    --if_id_buffer: entity work.if_id_buffer
        --port map(clk => clk, flush => if_id_flush, instruction => im_output, next_address => pc_4, pc_4 => if_id_pc_4, pc_concat => if_id_concat, opcode => if_id_opcode, funct => if_id_funct, rs => if_id_rs, rt => if_id_rt, rd => if_id_rd, shamt => if_id_shamt, immediate => if_id_immediate, jump_address => if_id_jump_address);

        process
        begin   
        for i in 0 to 20 loop
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end behavioral;