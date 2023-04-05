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

    --Signal for the Instruction Fetch Unit

    signal clk : std_logic := '0';
    signal pc_flush : std_logic := '0';

    signal jump: std_logic_vector(1 downto 0) := (others => '0');
    signal branch: std_logic := '0';

    signal branch_address: std_logic_vector(31 downto 0) := (others => '0');
    signal jump_address: std_logic_vector(31 downto 0) := (others => '0');
    signal jump_register_address: std_logic_vector(31 downto 0) := (others => '0');

    signal mux_1_output: std_logic_vector(31 downto 0) := (others => '0');
    signal mux_2_output: std_logic_vector(31 downto 0) := (others => '0');
    signal pc_in: std_logic_vector(31 downto 0) := (others => '0');
    signal pc_out: std_logic_vector(31 downto 0) := (others => '0');

    signal next_address: std_logic_vector(31 downto 0) := (others => '0');

    signal current_address : std_logic_vector(31 downto 0) := (others => '0');

    signal current_instruction : std_logic_vector(31 downto 0) := (others => '0');

    --IF/ID Buffer Signals

    signal buffer_flush : std_logic := '0';

    signal pc_concat : std_logic_vector(3 downto 0):= (others => '0');
    signal opcode : std_logic_vector(5 downto 0):= (others => '0');
    signal funct : std_logic_vector(5 downto 0):= (others => '0');
    signal rs : std_logic_vector(4 downto 0):= (others => '0');
    signal rt : std_logic_vector(4 downto 0):= (others => '0');
    signal rd : std_logic_vector(4 downto 0):= (others => '0');
    signal shamt : std_logic_vector(4 downto 0):= (others => '0');
    signal immediate : std_logic_vector(15 downto 0):= (others => '0');
    signal address : std_logic_vector(25 downto 0):= (others => '0');

    --signal pc_out: std_logic_vector(31 downto 0) := (others => '0');

    --signal i : integer := 0;

    signal en: std_logic:= '0';

    --Initiating components for the MUXs

    component if_mux_1 is
        port(
            pc_in: in std_logic_vector(31 downto 0);
            branch_address: in std_logic_vector(31 downto 0);
            select_signal: in std_logic;

            output_port: out std_logic_vector(31 downto 0)
        );
    end component;

    component if_mux_2 is
        port(
            jr: in std_logic_vector(31 downto 0);
            j: in std_logic_vector(31 downto 0);
            address: in std_logic_vector(31 downto 0);
            select_signal: in std_logic_vector(1 downto 0);

            output_port: out std_logic_vector(31 downto 0)
        );
    end component;

    component program_counter is
        port(
            clk: in std_logic;
            pc_flush: in std_logic;

            input_address: in std_logic_vector(31 downto 0);
		    output_address: out std_logic_vector(31 downto 0);
            next_address: out std_logic_vector(31 downto 0)
        );
    end component;

    component instruction_memory is
        port (
            clk: in STD_LOGIC;
            read_address: in STD_LOGIC_VECTOR (31 downto 0);
            instruction: out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;

    component if_id_buffer is
        port ( 
            clk : in std_logic;
            flush : in std_logic;
            instruction : in std_logic_vector(31 downto 0);
            next_address : in std_logic_vector(31 downto 0);
    
            pc_concat : out std_logic_vector(3 downto 0):= (others => '0');
            opcode : out std_logic_vector(5 downto 0):= (others => '0');
            funct : out std_logic_vector(5 downto 0):= (others => '0');
            rs : out std_logic_vector(4 downto 0):= (others => '0');
            rt : out std_logic_vector(4 downto 0):= (others => '0');
            rd : out std_logic_vector(4 downto 0):= (others => '0');
            shamt : out std_logic_vector(4 downto 0):= (others => '0');
            immediate : out std_logic_vector(15 downto 0):= (others => '0');
            address : out std_logic_vector(25 downto 0):= (others => '0')
        );
    end component;

    
    begin
        MUX_1: if_mux_1 port map(
            pc_in => current_address,
            branch_address => branch_address,
            select_signal => branch,

            output_port => mux_1_output
        );
        MUX_2: if_mux_2 port map(
            jr => jump_register_address,
            j => jump_address,
            address => mux_1_output,
            select_signal => jump,

            output_port => mux_2_output
        );
        PC: program_counter port map(
            clk => en,
            pc_flush => pc_flush,

            input_address => mux_2_output,
            output_address => pc_out,
            next_address => current_address
        );
        IM: instruction_memory port map(
            clk => en,
            read_address => pc_out,
            instruction => current_instruction
        );
        IF_ID: if_id_buffer port map(
            clk => en,
            flush => buffer_flush,
            instruction => current_instruction,
            next_address => current_address,

            pc_concat => pc_concat,
            opcode => opcode,
            funct => funct,
            rs => rs,
            rt => rt,
            rd => rd,
            shamt => shamt,
            immediate => immediate,
            address => address
        );

        en <= '1' when clk'event and clk = '1' else '0';

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
            

    