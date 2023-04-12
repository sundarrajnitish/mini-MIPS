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

    --signals for instruction memory
    signal im_out : std_logic_vector(31 downto 0) := (others => '0');

    --signals for if_id_buffer
    signal if_id_flush : std_logic := '0';
    signal if_id_pc : std_logic_vector(31 downto 0) := (others => '0');
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

    --signals for register_file
    signal mem_wb_reg_write : std_logic := '0';
    signal mem_wb_rd : std_logic_vector(4 downto 0):= (others => '0');
    signal wb_data : std_logic_vector(31 downto 0):= (others => '0');
    signal register_data_1 : std_logic_vector(31 downto 0):= (others => '0');
    signal register_data_2 : std_logic_vector(31 downto 0):= (others => '0');

    --signals for hazard_control
    signal and_branch : std_logic := '0';
    signal id_ex_flush : std_logic := '0';
    signal ex_mem_rd : std_logic_vector(4 downto 0):= (others => '0');
    signal mem_ex_memread : std_logic := '0';

    signal hdu_load_address : std_logic_vector(31 downto 0):= (others => '0');


    --signals for control_unit
    signal cu_flush : std_logic := '0';
    signal cu_alu_src : std_logic := '0';
    signal cu_reg_dst : std_logic := '0';
    signal cu_branch : std_logic := '0';
    signal cu_mem_read : std_logic := '0';
    signal cu_mem_write : std_logic := '0';
    signal cu_mem_to_reg : std_logic := '0';
    signal cu_reg_write : std_logic := '0';
    signal cu_jump_jr : std_logic_vector (1 downto 0) := (others => '0');
    signal cu_alu_op : std_logic_vector (2 downto 0) := (others => '0');

    --signals for sign_extend
    signal sign_extend_output : std_logic_vector(31 downto 0):= (others => '0');

    --signals for jump_address_calculator
    signal jump_address_calculator_output : std_logic_vector(31 downto 0):= (others => '0');

    --signals for id_ex_buffer
    signal id_ex_opcode : std_logic_vector(5 downto 0):= (others => '0');
    signal id_ex_funct : std_logic_vector(5 downto 0):= (others => '0');
    signal id_ex_read_data1 : std_logic_vector(31 downto 0):= (others => '0');
    signal id_ex_read_data2 : std_logic_vector(31 downto 0):= (others => '0');
    signal id_ex_shamt : std_logic_vector(4 downto 0):= (others => '0');
    signal id_ex_immediate_32 : std_logic_vector(31 downto 0):= (others => '0');

    signal id_ex_rs : std_logic_vector(4 downto 0):= (others => '0');
    signal id_ex_rt : std_logic_vector(4 downto 0):= (others => '0');
    signal id_ex_rd : std_logic_vector(4 downto 0):= (others => '0');

    signal id_ex_reg_write : std_logic := '0';
    signal id_ex_mem_to_reg : std_logic := '0';
    signal id_ex_branch : std_logic := '0';
    signal id_ex_mem_read : std_logic := '0';
    signal id_ex_mem_write : std_logic := '0';
    signal id_ex_reg_dst : std_logic := '0';
    signal id_ex_alu_src : std_logic := '0';
    signal id_ex_alu_op : std_logic_vector (2 downto 0) := (others => '0');

begin 

    --Fetch Stage

    addr_buffer: entity work.address_buffer
        port map(clk => en, pc_4 => pc_address, branch_address => branch_address, load_address => load_address, jump_address => j_address, jump_reg_address => jr_address, pc_4_out => pc_address_out, branch_address_out => branch_address_out, load_address_out => load_address_out, jump_address_out => j_address_out, jump_reg_address_out => jr_address_out);

    branch_mux: entity work.branch_mux
        port map(pc_4 => pc_address_out, branch_address => branch_address_out, load_address => load_address_out, select_signal => b_mux_select, output_port => branch_mux_out);

    jump_mux: entity work.jump_mux
        port map(pc_4 => branch_mux_out, jump_address => j_address_out, jr_address => jr_address_out, select_signal => j_mux_select, output_port => jump_mux_out);

    pc: entity work.program_counter
        port map(clk => en, address_in => jump_mux_out, current_address => pc_out, next_address => pc_address);

    im: entity work.instruction_memory
        port map(clk => en, read_address => pc_out, instruction => im_out);

    if_id_buffer: entity work.if_id_buffer
        port map(clk => en, flush => if_id_flush, instruction => im_out, next_address => pc_address, pc => pc_out, pc_4 => if_id_pc_4, pc_concat => if_id_concat, opcode => if_id_opcode, funct => if_id_funct, rs => if_id_rs, rt => if_id_rt, rd => if_id_rd, shamt => if_id_shamt, immediate => if_id_immediate, jump_address => if_id_jump_address, pc_out => if_id_pc);

    --Decode Stage

    register_file: entity work.register_memory
        port map(clk => en, reg_write => mem_wb_reg_write, read_register_1 => if_id_rs, read_register_2 => if_id_rt, write_register => mem_wb_rd, write_data => wb_data, read_data_1 => register_data_1, read_data_2 => register_data_2);

    control_unit: entity work.control_unit
        port map(clk => en, flush => cu_flush ,opcode => if_id_opcode, funct => if_id_funct, alu_src => cu_alu_src, reg_dst => cu_reg_dst, branch => cu_branch, mem_read => cu_mem_read, mem_write => cu_mem_write, mem_to_reg => cu_mem_to_reg, reg_write => cu_reg_write, jump_jr => cu_jump_jr, alu_op => cu_alu_op);

    hdu: entity work.hazard_control_unit
        port map(clk => en, pc => if_id_pc, and_branch => and_branch, jump_jr => cu_jump_jr, if_id_rs => if_id_rs, if_id_rt => if_id_rt, id_ex_opcode => id_ex_opcode, id_ex_rt => id_ex_rt, control_flush => cu_flush, id_ex_flush => id_ex_flush, if_id_flush => if_id_flush, branch_mux_signal => b_mux_select, jump_mux_signal => j_mux_select, load_address => hdu_load_address);

    se: entity work.sign_extend
        port map(input_data => if_id_immediate, sign_extended_data => sign_extend_output);

    j_addr_calc: entity work.jump_address_calc
    port map(input_address => if_id_jump_address, pc_concat => if_id_concat, jump_address => jump_address_calculator_output);

    id_ex_buffer: entity work.id_ex_buffer
        port map(
        clk => en, 
        flush => id_ex_flush, 
        next_address => if_id_pc_4,

        reg_write_in => cu_reg_write,
        mem_to_reg_in => cu_mem_to_reg,
        branch_in => cu_branch,
        mem_read_in => cu_mem_read,
        mem_write_in => cu_mem_write,
        reg_dst_in => cu_reg_dst,
        alu_src_in => cu_alu_src,
        alu_op_in => cu_alu_op,

        opcode_in => if_id_opcode,
        funct_in => if_id_funct,

        read_data1_in => register_data_1,
        read_data2_in => register_data_2,

        shamt_in => if_id_shamt,
        immediate_32_in => sign_extend_output,

        rs_in => if_id_rs,
        rt_in => if_id_rt,
        rd_in => if_id_rd,

        opcode_out => id_ex_opcode,
        funct_out => id_ex_funct,

        read_data1_out => id_ex_read_data1,
        read_data2_out => id_ex_read_data2,

        shamt_out => id_ex_shamt,
        immediate_32_out => id_ex_immediate_32,

        rs_out => id_ex_rs,
        rt_out => id_ex_rt,
        rd_out => id_ex_rd,

        reg_write_out => id_ex_reg_write,
        mem_to_reg_out => id_ex_mem_to_reg,
        branch_out => id_ex_branch,
        mem_read_out => id_ex_mem_read,
        mem_write_out => id_ex_mem_write,
        reg_dst_out => id_ex_reg_dst,
        alu_src_out => id_ex_alu_src,
        alu_op_out => id_ex_alu_op
        );


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