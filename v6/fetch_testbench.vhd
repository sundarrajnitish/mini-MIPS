library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test_bench is
end test_bench;

architecture test of test_bench is

    -- Clock Singal
    signal en : std_logic;

    --Branch MUX Signals
    signal pc_4 : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_mux_signal : std_logic_vector(1 downto 0) := (others => '0');
    signal branch_mux_out : std_logic_vector(31 downto 0) := (others => '0');

    --Jump MUX Signals
    signal jump_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal jump_reg_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal jump_mux_signal : std_logic_vector(1 downto 0) := (others => '0');
    signal jump_mux_out : std_logic_vector(31 downto 0) := (others => '0');

    --Program Counter Signals
    signal pc_address_in : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_address_out : std_logic_vector(31 downto 0) := (others => '0');

    begin
        b_mux: entity work.branch_mux
            port map(
                pc_plus_four => pc_4,
                branch_address => branch_addr,
                select_signal => branch_mux_signal,
                output_port => branch_mux_out
            );

        j_mux: entity work.jump_mux
            port map(
                branch_address => branch_mux_out,
                j => jump_addr,
                jr => jump_reg_addr,
                select_signal => jump_mux_signal,
                output_port => jump_mux_out
            );
        pc: entity work.program_counter
            port map(
                clk => en,
                input_address => jump_mux_out,
                next_address => pc_4,
                output_address => pc_address_out
            );

    process
        begin   
        for i in 0 to 20 loop
            en <= '1';
            wait for 100 ns;
            en <= '0';
            wait for 100 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end test;


