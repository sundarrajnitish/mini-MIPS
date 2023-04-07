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

    --MUX 1 Component
    component if_mux_1
        port(
            pc_4 : in std_logic_vector(31 downto 0);
            branch_address : in std_logic_vector(31 downto 0);
            select_signal : in std_logic;
            output_port : out std_logic_vector(31 downto 0)
        );
    end component;

    --signals for if_mux_1
    signal pc_4 : std_logic_vector(31 downto 0) := (others => '0');
    signal branch_address : std_logic_vector(31 downto 0) := (others => '0');
    signal mux_1_select : std_logic := '0';
    signal mux_1_output : std_logic_vector(31 downto 0) := (others => '0');

    --MUX 2 Component
    component if_mux_2
        port(
            address : in std_logic_vector(31 downto 0);
            j : in std_logic_vector(31 downto 0);
            jr : in std_logic_vector(31 downto 0);
            select_signal : in std_logic_vector(1 downto 0);
            output_port : out std_logic_vector(31 downto 0)
        );
    end component;

    --signals for if_mux_2
    signal j : std_logic_vector(31 downto 0) := (others => '0');
    signal jr : std_logic_vector(31 downto 0) := (others => '0');
    signal mux_2_select : std_logic_vector(1 downto 0) := (others => '0');
    signal mux_2_output : std_logic_vector(31 downto 0) := (others => '0');

    --Program Counter Component
    component program_counter
        port(
            clk : in std_logic;
            input_address : in std_logic_vector(31 downto 0);
            next_address : in std_logic_vector(31 downto 0);
            output_address : out std_logic_vector(31 downto 0)
        );
    end component;

    --signals for program_counter
    signal pc_output : std_logic_vector(31 downto 0) := (others => '0');
    --signal pc_pc_4 : std_logic_vector(31 downto 0) := (others => '0');

    --Instruction Memory Component
    component instruction_memory
        port(
            clk : in std_logic;
            read_address : in std_logic_vector(31 downto 0);
            instruction : out std_logic_vector(31 downto 0)
        );
    end component;

    --signals for instruction_memory
    signal im_output : std_logic_vector(31 downto 0) := (others => '0');

    --IF_ID Buffer Component
    component if_id_buffer
        port(
            clk : in std_logic;
            flush : in std_logic;
            instruction : in std_logic_vector(31 downto 0);
            next_address : in std_logic_vector(31 downto 0);
            pc_4 : out std_logic_vector(31 downto 0);
            pc_concat : out std_logic_vector(3 downto 0);
            opcode : out std_logic_vector(5 downto 0);
            funct : out std_logic_vector(5 downto 0);
            rs : out std_logic_vector(4 downto 0);
            rt : out std_logic_vector(4 downto 0);
            rd : out std_logic_vector(4 downto 0);
            shamt : out std_logic_vector(4 downto 0);
            immediate : out std_logic_vector(15 downto 0);
            jump_address : out std_logic_vector(25 downto 0)
        );
    end component;

    --signals for if_id_buffer
    signal if_id_buffer_output : std_logic_vector(63 downto 0) := (others => '0');
    signal if_id_flush : std_logic := '0';
    signal if_id_pc_4 : std_logic_vector(31 downto 0) := (others => '0');
    signal if_id_concat : std_logic_vector(3 downto 0) := (others => '0');
    signal if_id_opcode : std_logic_vector(5 downto 0) := (others => '0');
    signal if_id_funct : std_logic_vector(5 downto 0) := (others => '0');
    signal if_id_rs : std_logic_vector(4 downto 0) := (others => '0');
    signal if_id_rt : std_logic_vector(4 downto 0) := (others => '0');
    signal if_id_rd : std_logic_vector(4 downto 0) := (others => '0');
    signal if_id_shamt : std_logic_vector(4 downto 0) := (others => '0');
    signal if_id_immediate : std_logic_vector(15 downto 0) := (others => '0');
    signal if_id_jump_address : std_logic_vector(25 downto 0) := (others => '0');

begin 
    mux_1: if_mux_1
        port map(pc_4 => pc_4, branch_address => branch_address, select_signal => mux_1_select, output_port => mux_1_output);
    mux_2: if_mux_2
        port map(address => pc_4, j => j, jr => jr, select_signal => mux_2_select, output_port => mux_2_output);
    pc: program_counter
        port map(clk => clk, input_address => mux_2_output, next_address => pc_4, output_address => pc_output);
    im: instruction_memory
        port map(clk => clk, read_address => pc_output, instruction => im_output);
    ifid_buffer: if_id_buffer
        port map(clk => clk, flush => if_id_flush, instruction => im_output, next_address => pc_4, pc_4 => if_id_pc_4, pc_concat => if_id_concat, opcode => if_id_opcode, funct => if_id_funct, rs => if_id_rs, rt => if_id_rt, rd => if_id_rd, shamt => if_id_shamt, immediate => if_id_immediate, jump_address => if_id_jump_address);

        process
        begin   
        for i in 0 to 20 loop
            clk <= '0';
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end behavioral;