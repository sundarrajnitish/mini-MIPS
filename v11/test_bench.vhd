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

    --signals for rdf3_mux_e
    signal rdf3_mux_select : std_logic := '0';
    signal rdf3_mux_e_out : std_logic_vector(31 downto 0):= (others => '0');

    --signals for rdf4_mux_f
    signal rdf4_mux_select : std_logic := '0';
    signal rdf4_mux_f_out : std_logic_vector(31 downto 0):= (others => '0');

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
    signal id_ex_immediate : std_logic_vector(31 downto 0):= (others => '0');

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

    --signals for rd2_se32_mux
    signal rd2_se32_mux_select : std_logic := '0';
    signal rd2_se32_mux_out : std_logic_vector(31 downto 0):= (others => '0');

    --signals for rt_rd_mux
    signal rt_rd_mux_select : std_logic := '0';
    signal rt_rd_mux_out : std_logic_vector(4 downto 0):= (others => '0');

    --signals for alu
    signal alu_result : std_logic_vector(31 downto 0):= (others => '0');
    signal alu_zero : std_logic := '0';

    --signals for forwarding unit
    signal forward_data_1 : std_logic_vector(31 downto 0):= (others => '0');
    signal forward_data_2 : std_logic_vector(31 downto 0):= (others => '0');
    signal forward_data_3 : std_logic_vector(31 downto 0):= (others => '0');
    signal forward_data_4 : std_logic_vector(31 downto 0):= (others => '0');

    signal forward_signal_1 : std_logic := '0';
    signal forward_signal_2 : std_logic := '0';
    signal forward_signal_3 : std_logic := '0';
    signal forward_signal_4 : std_logic := '0';

    --signals for ex_mem_buffer
    signal ex_mem_flush : std_logic := '0';
    signal ex_mem_alu_result : std_logic_vector(31 downto 0):= (others => '0');
    --signal ex_mem_rd : std_logic_vector(4 downto 0):= (others => '0');

    signal ex_mem_read_data2 : std_logic_vector(31 downto 0):= (others => '0');

    --signal ex_mem_mem_to_reg : std_logic := '0';
    --signal ex_mem_reg_write : std_logic := '0';
    --signal ex_mem_mem_read : std_logic := '0';
    --signal ex_mem_mem_write : std_logic := '0';
    --signal ex_mem_alu_zero : std_logic := '0';
    --signal ex_mem_branch : std_logic := '0';

    --signal ex_mem_rd : std_logic_vector(4 downto 0):= (others => '0');

    signal ex_mem_mem_to_reg : std_logic := '0';
    signal ex_mem_reg_write : std_logic := '0';
    signal ex_mem_mem_read : std_logic := '0';
    signal ex_mem_mem_write : std_logic := '0';
    signal ex_mem_alu_zero : std_logic := '0';
    signal ex_mem_branch : std_logic := '0';
    
    signal fwd_alu_result_ex_mem : std_logic_vector(31 downto 0):= (others => '0');
    signal fwd_rd_ex_mem : std_logic_vector(4 downto 0):= (others => '0');

    --signals for branch_and_gate
    signal branch_and_gate_out : std_logic := '0';

    --signals for rd_f1_mux_c
    signal rdf1_mux_c_out : std_logic_vector(31 downto 0):= (others => '0');

    --signals for rd_f2_mux_d
    signal rdf2_mux_d_out : std_logic_vector(31 downto 0):= (others => '0');

    --signals for forward_control_unit
    signal mem_wb_alu_result : std_logic_vector(31 downto 0):= (others => '0');
    signal mem_wb_read_data : std_logic_vector(31 downto 0):= (others => '0');

    --signals for data memory
    signal data_memory_read_data : std_logic_vector(31 downto 0):= (others => '0');

    --signals for mem_wb_buffer
    signal mem_wb_flush : std_logic := '0';
    signal mem_wb_mem_to_reg : std_logic := '0';
    signal fwd_rd_mem_wb : std_logic_vector(4 downto 0):= (others => '0');
    signal fwd_alu_result_mem_wb : std_logic_vector(31 downto 0):= (others => '0');

    --signal mem_wb_read_data : std_logic_vector(31 downto 0):= (others => '0');

    --signals for wb_mux
    signal wb_mux_out : std_logic_vector(31 downto 0):= (others => '0');

    --signals for wb buffer
    signal wb_rd : std_logic_vector(4 downto 0):= (others => '0');
    --signal wb_data : std_logic_vector(31 downto 0):= (others => '0');

    --signals for branch_address_calculator
    signal branch_address_calculator_output : std_logic_vector(31 downto 0):= (others => '0');

    signal id_ex_pc : std_logic_vector(31 downto 0):= (others => '0');

    signal next_address_out : std_logic_vector(31 downto 0):= (others => '0');


begin 

    --Fetch Stage

    addr_buffer: entity work.address_buffer
        port map(clk => en, pc_4 => pc_address, branch_address => branch_address_calculator_output, load_address => hdu_load_address, jump_address => jump_address_calculator_output, jump_reg_address => jr_address, pc_4_out => pc_address_out, branch_address_out => branch_address_out, load_address_out => load_address_out, jump_address_out => j_address_out, jump_reg_address_out => jr_address_out);

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
        port map(clk => en, reg_write => mem_wb_reg_write, read_register_1 => if_id_rs, read_register_2 => if_id_rt, write_register => wb_rd, write_data => wb_data, read_data_1 => register_data_1, read_data_2 => register_data_2);

    rdf3_mux_e: entity work.rdf3_mux_e
        port map(rd1 =>register_data_1, fd3 => forward_data_3, rdf3_mux_e_sel => forward_signal_3, rdf3_mux_e_out => rdf3_mux_e_out);
    
    rdf4_mux_f: entity work.rdf4_mux_f
        port map(rd2 =>register_data_2, fd4 => forward_data_4, rdf4_mux_f_sel => forward_signal_4, rdf4_mux_f_out => rdf4_mux_f_out);

    control_unit: entity work.control_unit
        port map(clk => en, flush => cu_flush ,opcode => if_id_opcode, funct => if_id_funct, alu_src => cu_alu_src, reg_dst => cu_reg_dst, branch => cu_branch, mem_read => cu_mem_read, mem_write => cu_mem_write, mem_to_reg => cu_mem_to_reg, reg_write => cu_reg_write, jump_jr => cu_jump_jr, alu_op => cu_alu_op);

    hdu: entity work.hazard_control_unit
        port map(clk => en, pc => if_id_pc, and_branch => branch_and_gate_out, jump_jr => cu_jump_jr, if_id_rs => if_id_rs, if_id_rt => if_id_rt, id_ex_opcode => id_ex_opcode, id_ex_rt => id_ex_rt, control_flush => cu_flush, id_ex_flush => id_ex_flush, if_id_flush => if_id_flush, branch_mux_signal => b_mux_select, jump_mux_signal => j_mux_select, load_address => hdu_load_address);

    se: entity work.sign_extend
        port map(input_data => if_id_immediate, sign_extended_data => sign_extend_output);

    j_addr_calc: entity work.jump_address_calc
        port map(input_address => if_id_jump_address, pc_concat => if_id_concat, jump_address => jump_address_calculator_output);

    id_ex_buffer: entity work.id_ex_buffer
        port map(clk => en, flush => id_ex_flush, next_address => if_id_pc_4, opcode_in => if_id_opcode, rs_in => if_id_rs, rt_in => if_id_rt, rd_in => if_id_rd, immediate_32_in => sign_extend_output, shamt_in => if_id_shamt, read_data1_in => rdf3_mux_e_out, read_data2_in => rdf4_mux_f_out, alu_src_in => cu_alu_src, reg_dst_in => cu_reg_dst, branch_in => cu_branch, mem_read_in => cu_mem_read, mem_write_in => cu_mem_write, mem_to_reg_in => cu_mem_to_reg, reg_write_in => cu_reg_write, alu_op_in => cu_alu_op, opcode_out => id_ex_opcode, rs_out => id_ex_rs, rt_out => id_ex_rt, rd_out => id_ex_rd, shamt_out => id_ex_shamt, read_data1_out => id_ex_read_data1, read_data2_out => id_ex_read_data2, immediate_32_out => id_ex_immediate, alu_src_out => id_ex_alu_src, reg_dst_out => id_ex_reg_dst, branch_out => id_ex_branch, mem_read_out => id_ex_mem_read, mem_write_out => id_ex_mem_write, mem_to_reg_out => id_ex_mem_to_reg, reg_write_out => id_ex_reg_write, alu_op_out => id_ex_alu_op, next_address_out => id_ex_pc);
    
    

    --Execute Stage
    branch_address_calc: entity work.branch_address_calc
        port map(immediate_32 => id_ex_immediate, pc_4 => id_ex_pc, branch_address => branch_address_calculator_output);
    rd2_se32_mux: entity work.rd2_se32_mux
        port map(rd2 => id_ex_read_data2, se32 => id_ex_immediate, rd2_se32_mux_sel => id_ex_alu_src, rd2_se32_mux_out => rd2_se32_mux_out);

    rt_rd_mux: entity work.rt_rd_mux
        port map(rt => id_ex_rt, rd => id_ex_rd, rt_rd_mux_sel => id_ex_reg_dst, rt_rd_mux_out => rt_rd_mux_out);

    rdf1_mux_c: entity work.rdf1_mux_c
        port map(rd1 => id_ex_read_data1, fd1 => forward_data_1, rdf1_mux_c_sel => forward_signal_1, rdf1_mux_c_out => rdf1_mux_c_out);

    rdf2_mux_d: entity work.rdf2_mux_d
        port map(rd2 => rd2_se32_mux_out, fd2 => forward_data_2, rdf2_mux_d_sel => forward_signal_2, rdf2_mux_d_out => rdf2_mux_d_out);

    alu: entity work.alu
        port map(clk => en, aluop => id_ex_alu_op, shamt => id_ex_shamt, input_a => rdf1_mux_c_out, input_b => rdf2_mux_d_out, alu_result => alu_result, zero => alu_zero);
    
    ex_mem_buffer: entity work.ex_mem_buffer
        port map(clk => en, reset => ex_mem_flush, zero_flag => alu_zero, read_data2 => id_ex_read_data2, reg_write => id_ex_reg_write, mem_to_reg => id_ex_mem_to_reg, branch => id_ex_branch, mem_read => id_ex_mem_read, mem_write => id_ex_mem_write, alu_result => alu_result, rd => id_ex_rd, reg_write_out => ex_mem_reg_write, mem_to_reg_out => ex_mem_mem_to_reg, branch_out => ex_mem_branch, mem_read_out => ex_mem_mem_read, mem_write_out => ex_mem_mem_write, alu_result_out => ex_mem_alu_result, rd_out => ex_mem_rd, rd_ex_mem => fwd_rd_ex_mem, alu_result_ex_mem => fwd_alu_result_ex_mem);
    
    forward_control_unit: entity work.forward_control_unit
        port map(clk => en, rd_ex_mem => ex_mem_rd, rd_mem_wb => mem_wb_rd, alu_result_ex_mem => ex_mem_alu_result, alu_result_mem_wb => mem_wb_alu_result, read_data_mem_wb => mem_wb_read_data, mem_to_reg_mem_wb => ex_mem_mem_to_reg, rs_if_id => if_id_rs, rt_if_id => if_id_rt, rs_id_ex => id_ex_rs, rt_id_ex => id_ex_rt, forward_signal_rs_if_id => forward_signal_1, forward_signal_rt_if_id => forward_signal_2, forward_signal_rs_id_ex => forward_signal_3, forward_signal_rt_id_ex => forward_signal_4, forward_data_rs_if_id => forward_data_1, forward_data_rt_if_id => forward_data_2, forward_data_rs_id_ex => forward_data_3, forward_data_rt_id_ex => forward_data_4);
    
    -- Memory Stage
    branch_and_gate: entity work.branch_and_gate
        port map(branch => ex_mem_branch, zero => alu_zero, gate_output => branch_and_gate_out);

    data_memory: entity work.data_memory
        port map(clk => en, mem_address => ex_mem_alu_result, write_data => ex_mem_read_data2, mem_read => ex_mem_mem_read, mem_write => ex_mem_mem_write, read_data => data_memory_read_data);
    
    mem_wb_buffer: entity work.mem_wb_buffer
        port map(clk => en, reset => mem_wb_flush, reg_write => ex_mem_reg_write, mem_to_reg => ex_mem_mem_to_reg, alu_result => ex_mem_alu_result, rd => ex_mem_rd, reg_write_out => mem_wb_reg_write, mem_to_reg_out => mem_wb_mem_to_reg, alu_result_out => mem_wb_alu_result, rd_out => mem_wb_rd, rd_mem_wb => fwd_rd_mem_wb, alu_result_mem_wb => fwd_alu_result_mem_wb, read_data_reg => ex_mem_read_data2, read_data_reg_out => mem_wb_read_data);

    --Write Back Stage
    wb_mux: entity work.wb_mux
        port map(read_data => mem_wb_read_data, alu_result => mem_wb_alu_result, wb_mux_sel => mem_wb_mem_to_reg, wb_mux_out => wb_mux_out);

    wb_buffer: entity work.wb_buffer
        port map(clk => en, mem_wb_rd => mem_wb_rd, wb_data => wb_mux_out, mem_wb_reg_rd => wb_rd, mem_wb_reg_data => wb_data);
        
        
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