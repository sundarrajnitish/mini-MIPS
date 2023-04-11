------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity main_test_bench is
end main_test_bench;

architecture behavioral of main_test_bench is

    --common clock for all components
    signal en : std_logic := '0';

    --Fetch Stage

    --Signals for the address buffer
    signal pc_address : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_address: std_logic_vector(31 downto 0) := (others => '0');
    signal load_address: std_logic_vector(31 downto 0) := (others => '0');
    signal j_address: std_logic_vector(31 downto 0) := (others => '0');
    signal jr_address: std_logic_vector(31 downto 0) := (others => '0');

    signal pc_address_out : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_address_out: std_logic_vector(31 downto 0) := (others => '0');
    signal load_address_out: std_logic_vector(31 downto 0) := (others => '0');
    signal j_address_out: std_logic_vector(31 downto 0) := (others => '0');
    signal jr_address_out: std_logic_vector(31 downto 0) := (others => '0');

    --signals for the branch mux
    signal b_mux_select : std_logic_vector(1 downto 0) := (others => '0');
    signal branch_mux_out : std_logic_vector(31 downto 0) := (others => '0');

    --signals for the jump mux
    signal j_mux_select : std_logic_vector(1 downto 0) := (others => '0');
    signal jump_mux_out : std_logic_vector(31 downto 0) := (others => '0');

    --signals for the pc
    signal pc_out : std_logic_vector(31 downto 0) := (others => '0');




begin 
    addr_buffer: entity work.address_buffer
        port map(clk => en, pc_4 => pc_address, branch_address => branch_address, load_address => load_address, jump_address => j_address, jump_reg_address => jr_address, pc_4_out => pc_address_out, branch_address_out => branch_address_out, load_address_out => load_address_out, jump_address_out => j_address_out, jump_reg_address_out => jr_address_out);

    branch_mux: entity work.branch_mux
        port map(pc_4 => pc_address_out, branch_address => branch_address_out, load_address => load_address_out, select_signal => b_mux_select, output_port => branch_mux_out);

    jump_mux: entity work.jump_mux
        port map(pc_4 => branch_mux_out, jump_address => j_address_out, jr_address => jr_address_out, select_signal => j_mux_select, output_port => jump_mux_out);

    pc: entity work.program_counter
        port map(clk => en, address_in => jump_mux_out, current_address => pc_out, next_address => pc_address);


    process
        begin   
        for i in 0 to 20 loop
            en <= '0';
            wait for 10 ns;
            en <= '1';
            wait for 10 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end behavioral;