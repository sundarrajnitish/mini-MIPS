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

entity execute_test_bench is
end execute_test_bench;

architecture behavioral of execute_test_bench is
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

    --signals for register_file
    signal mem_wb_reg_write : std_logic := '0';
    signal mem_wb_rd : std_logic_vector(4 downto 0):= (others => '0');
    signal wb_data : std_logic_vector(31 downto 0):= (others => '0');
    signal register_data_1 : std_logic_vector(31 downto 0):= (others => '0');
    signal register_data_2 : std_logic_vector(31 downto 0):= (others => '0');

    --signals for hazard_control
    signal id_ex_flush : std_logic := '0';
    signal pc : std_logic_vector(31 downto 0) := (others => '0');
    signal ex_mem_branch : std_logic := '0';
    signal ex_mem_rd : std_logic_vector(4 downto 0):= (others => '0');
    signal mem_ex_memread : std_logic := '0';
    signal jump_mux_signal : std_logic_vector(1 downto 0) := (others => '0');
    signal control_flush : std_logic := '0';
    

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

    --signals for rd2_se32_mux
    signal rd2_se32_mux_output : std_logic_vector(31 downto 0):= (others => '0');

    --signals for rt_rd_mux
    signal rt_rd_mux_output : std_logic_vector(4 downto 0):= (others => '0');

    --signals for fd_mux_a
    signal fd_mux_a_output : std_logic_vector(31 downto 0):= (others => '0');
    signal fd_select_1 : std_logic := '0';
    signal fd_1 : std_logic_vector(31 downto 0):= (others => '0');

    --signals for fd_mux_b
    signal fd_mux_b_output : std_logic_vector(31 downto 0):= (others => '0');
    signal fd_select_2 : std_logic := '0';
    signal fd_2 : std_logic_vector(31 downto 0):= (others => '0');

    --signals for alu_control
    signal alu_op : std_logic_vector(2 downto 0):= (others => '0');

    --signals for alu
    signal alu_output : std_logic_vector(31 downto 0):= (others => '0');
    signal alu_zero : std_logic := '0';

    --signals for forwarding unit
    signal fd1 : std_logic_vector(31 downto 0):= (others => '0');
    signal fd2 : std_logic_vector(31 downto 0):= (others => '0');


    
begin 
    pc <= std_logic_vector(unsigned(pc_output) - 4);
    --Fetch Stage
    branch_mux: entity work.branch_mux
        port map(branch_address => branch_address, j => jump, jr => jump_reg, load_address => branch_load_address, select_signal => branch_mux_select, output_port => branch_mux_output);
    p_count: entity work.program_counter
        port map(clk => en, pc_write => pc_write, branch_address => branch_mux_output, output_address => pc_output);
    im: entity work.instruction_memory
        port map(clk => en, read_address => pc_output, instruction => im_output);
    if_id_buffer: entity work.if_id_buffer
        port map(clk => en, flush => if_id_flush, instruction => im_output, next_address => pc_output, pc_4 => if_id_pc_4, pc_concat => if_id_concat, opcode => if_id_opcode, funct => if_id_funct, rs => if_id_rs, rt => if_id_rt, rd => if_id_rd, shamt => if_id_shamt, immediate => if_id_immediate, jump_address => if_id_jump_address);

    --Decode Stage

    register_file: entity work.register_memory
        port map(clk => en, reg_write => mem_wb_reg_write, read_register_1 => if_id_rs, read_register_2 => if_id_rt, write_register => mem_wb_rd, write_data => wb_data, read_data_1 => register_data_1, read_data_2 => register_data_2);

    hazard_control: entity work.hazard_control_unit
        port map(clk => en, pc => pc, and_branch => ex_mem_branch, jump_jr => cu_jump_jr, mem_ex_memread => mem_ex_memread, rs => if_id_rs, rt => if_id_rt, ex_mem_rd => ex_mem_rd, jump_mux_signal => jump_mux_signal, if_id_flush => if_id_flush, control_flush => control_flush, id_ex_flush => id_ex_flush, branch_address => branch_load_address);
    
    control_unit: entity work.control_unit
        port map(clk => en, flush => cu_flush ,opcode => if_id_opcode, funct => if_id_funct, alu_src => cu_alu_src, reg_dst => cu_reg_dst, branch => cu_branch, mem_read => cu_mem_read, mem_write => cu_mem_write, mem_to_reg => cu_mem_to_reg, reg_write => cu_reg_write, jump_jr => cu_jump_jr);
    
    sign_extender: entity work.sign_extend
        port map(input_data => if_id_immediate, sign_extended_data => sign_extend_output);

    jump_address_calculator: entity work.jump_address_calc
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
        alu_src_out => id_ex_alu_src
        );
    
    --Execute Stage

    rd2_se32_mux: entity work.rd2_se32_mux
        port map(rd2 => id_ex_read_data2, se32 => id_ex_immediate_32, rd2_se32_mux_sel => id_ex_alu_src, rd2_se32_mux_out => rd2_se32_mux_output);

    rt_rd_mux: entity work.rt_rd_mux
        port map(rt => id_ex_rt, rd => id_ex_rd, rt_rd_mux_sel => id_ex_reg_dst, rt_rd_mux_out => rt_rd_mux_output);

    fd_mux_a: entity work.fd_mux_a
        port map(rd1 => id_ex_read_data1, fd1 => fd1, fd_mux_a_sel => fd_select_1, fd_mux_a_out => fd_mux_a_output);
    
    fd_mux_b: entity work.fd_mux_b
        port map(rd2 => rd2_se32_mux_output, fd2 => fd2, fd_mux_b_sel => fd_select_2, fd_mux_b_out => fd_mux_b_output);
    
    alu_control: entity work.alu_control_unit
        port map(clk => en, opcode => id_ex_opcode, funct => id_ex_funct, alu_op => alu_op);

    alu: entity work.alu
        port map(clk => en, aluop => alu_op, shamt => id_ex_shamt ,input_a => fd_mux_a_output, input_b => fd_mux_b_output, alu_result => alu_output, zero => alu_zero);

    
    
        
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
