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

entity decode_testbench is
	port(
		clk: in std_logic := '0';
        read_data_1, read_data_2: out std_logic_vector(31 downto 0)
	);
end decode_testbench;

architecture testbench of decode_testbench is

    type InstructionArray is array (1 to 5) of std_logic_vector(31 downto 0);
    constant INSTRUCTIONS : InstructionArray := (
        "00000010001010000100000000100000",  -- add $t0, $s0, $s1
        "10001110000010000000000000000000",  -- lw $t0, 0($s0)
        "00000010001010000100000000100011",  -- subu $t0, $s0, $s1
        "00000010001010000100000000100110",  -- xor $t0, $s0, $s1
        "00010010000010000000000000000100"   -- beq $s0, $s1, label
    );

    signal instruction_address: std_logic_vector(31 downto 0) := (others => '0');

    signal test_instruction: std_logic_vector(31 downto 0) := (others => '0');
    signal instruction: std_logic_vector(31 downto 0) := (others => '0');
    signal opcode: std_logic_vector(5 downto 0) := (others => '0');
    signal rs: std_logic_vector(4 downto 0) := (others => '0');
    signal rt: std_logic_vector(4 downto 0) := (others => '0');
    signal rd: std_logic_vector(4 downto 0) := (others => '0');
    signal shamt: std_logic_vector(4 downto 0) := (others => '0');
    signal funct: std_logic_vector(5 downto 0) := (others => '0');
    signal immediate: std_logic_vector(15 downto 0) := (others => '0');
    signal address: std_logic_vector(25 downto 0) := (others => '0');

    signal reg_dst: std_logic := '0';
    signal reg_write: std_logic := '0';
    signal alu_src: std_logic := '0';
    signal mem_read: std_logic := '0';
    signal mem_write: std_logic := '0';
    signal branch: std_logic := '0';
    signal jump: std_logic := '0';
    signal pc_src: std_logic := '0';
    signal mem_to_reg: std_logic := '0';
    signal alu_op: std_logic_vector(2 downto 0):= (others => '0');

    signal read_register_1: STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
    signal read_register_2: STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
    signal write_register: STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
    signal write_data: STD_LOGIC_VECTOR (31 downto 0) := (others => '0');

    signal d_write_register: STD_LOGIC_VECTOR (4 downto 0) := (others => '0');

    signal input_data : std_logic_vector(15 downto 0) := (others => '0');
    signal output_data : std_logic_vector(31 downto 0) := (others => '0');

    signal ex_read_reg_1 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_read_reg_2 : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_immediate  : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_pc         : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_reg_write  : std_logic := '0';
    signal ex_mem_write  : std_logic := '0';
    signal ex_mem_read   : std_logic := '0';
    signal ex_mem_to_reg : std_logic := '0';
    signal ex_alu_op     : std_logic_vector(2 downto 0) := (others => '0');
    signal ex_branch     : std_logic := '0';

    signal cc: std_logic:= '0'; -- The clock for the other components; starts when the state is ready

	signal en: std_logic:= '0';  -- The clock for the other components; starts when the state is ready

    component instruction_decoder
    port(
        clk : in std_logic;
        reset : in std_logic;
        instruction : in std_logic_vector(31 downto 0);
        opcode : out std_logic_vector(5 downto 0);
        funct : out std_logic_vector(5 downto 0);
        rs : out std_logic_vector(4 downto 0);
        rt : out std_logic_vector(4 downto 0);
        rd : out std_logic_vector(4 downto 0);
        shamt : out std_logic_vector(4 downto 0);
        immediate : out std_logic_vector(15 downto 0);
        address : out std_logic_vector(25 downto 0)
    );
    end component;

    component sign_extend
    port(
        input_data : in std_logic_vector(15 downto 0);
        output_data : out std_logic_vector(31 downto 0)
    );
    end component;

    component control_unit
    port(
        clk: in std_logic;
        opcode: in std_logic_vector(5 downto 0);
        funct: in std_logic_vector(5 downto 0);

        reg_dst: out std_logic;
        reg_write: out std_logic;
        alu_src: out std_logic;
        mem_read: out std_logic;
        mem_write: out std_logic;
        branch: out std_logic;
        jump: out std_logic;
        pc_src: out std_logic;
        mem_to_reg: out std_logic;

        alu_op: out std_logic_vector(2 downto 0)
    );
    end component;

    component decode_mux
    port(
        rt: in std_logic_vector(4 downto 0);
        rd: in std_logic_vector(4 downto 0);
        reg_dst: in std_logic;
        d_write_register: out std_logic_vector(4 downto 0)
    );
    end component;

    component register_memory
    port(
        clk: in STD_LOGIC;
        reg_write: in STD_LOGIC;

		read_register_1: in STD_LOGIC_VECTOR (4 downto 0);
        read_register_2: in STD_LOGIC_VECTOR (4 downto 0);
        write_register: in STD_LOGIC_VECTOR (4 downto 0);
        write_data: in STD_LOGIC_VECTOR (31 downto 0);

		read_data_1: out STD_LOGIC_VECTOR (31 downto 0);
        read_data_2: out STD_LOGIC_VECTOR (31 downto 0)
    );
    end component;

    component id_ex_buffer is
        port (
            -- Inputs from ID stage
            instruction   : in std_logic_vector(31 downto 0);
            read_reg_1    : in std_logic_vector(4 downto 0);
            read_reg_2    : in std_logic_vector(4 downto 0);
            immediate     : in std_logic_vector(15 downto 0);
            pc            : in std_logic_vector(31 downto 0);
            -- Control signals from ID stage
            reg_write     : in std_logic;
            mem_write     : in std_logic;
            mem_read      : in std_logic;
            mem_to_reg    : in std_logic;
            alu_op        : in std_logic_vector(2 downto 0);
            branch        : in std_logic;
            -- Outputs to EX stage
            ex_read_reg_1 : out std_logic_vector(31 downto 0);
            ex_read_reg_2 : out std_logic_vector(31 downto 0);
            ex_immediate  : out std_logic_vector(31 downto 0);
            ex_pc         : out std_logic_vector(31 downto 0);
            ex_reg_write  : out std_logic;
            ex_mem_write  : out std_logic;
            ex_mem_read   : out std_logic;
            ex_mem_to_reg : out std_logic;
            ex_alu_op     : out std_logic_vector(2 downto 0);
            ex_branch     : out std_logic
        );
    end component id_ex_buffer;

    begin
	
        --en <= '1' when clk'event and clk = '1' else '0';
    
        en <= '1' when cc'event and cc = '1' else '0';
    
        ID: instruction_decoder port map (en, '0', test_instruction, opcode, funct, rs, rt, rd, shamt, immediate, address); 

        CU: control_unit port map (en, opcode, funct, reg_dst, reg_write, alu_src, mem_read, mem_write, branch, jump, pc_src, mem_to_reg, alu_op);

        DM: decode_mux port map (rt, rd, reg_dst, d_write_register);

        RM: register_memory port map (en, reg_write, rs, rt, d_write_register, write_data, read_data_1, read_data_2);

        SE: sign_extend port map (immediate, output_data);

        ID_EX: id_ex_buffer port map (test_instruction, rs, rt, immediate, instruction_address, reg_write, mem_write, mem_read, mem_to_reg, alu_op, branch, ex_read_reg_1, ex_read_reg_2, ex_immediate, ex_pc, ex_reg_write, ex_mem_write, ex_mem_read, ex_mem_to_reg, ex_alu_op, ex_branch);

        process
        begin
            for i in 1 to 5 loop
                test_instruction <= INSTRUCTIONS(i);
                cc <= '1';
                wait for 1 ns;
                cc <= '0';
                wait for 1 ns;
            end loop;
            wait;
        end process;

        end testbench;