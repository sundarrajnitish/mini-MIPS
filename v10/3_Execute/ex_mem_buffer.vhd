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

entity ex_mem_buffer is
    Port ( 
        clk : in std_logic;
        reset : in std_logic;

        reg_write : in std_logic;
        mem_to_reg : in std_logic;
        mem_read : in std_logic;
        mem_write : in std_logic;
        
        branch : in std_logic;

        opcode : in std_logic_vector(5 downto 0);
        read_data2 : in std_logic_vector(31 downto 0);

        zero_flag : in std_logic;
        alu_result : in std_logic_vector(31 downto 0);

        rd : in std_logic_vector(4 downto 0);

        reg_write_out : out std_logic;
        mem_to_reg_out : out std_logic;
        mem_read_out : out std_logic;
        mem_write_out : out std_logic;
        branch_out : out std_logic;
        opcode_out : out std_logic_vector(5 downto 0);
        read_data2_out : out std_logic_vector(31 downto 0);
        zero_flag_out : out std_logic;
        alu_result_out : out std_logic_vector(31 downto 0);
        rd_out : out std_logic_vector(4 downto 0)

        rd_ex_mem : out std_logic_vector(4 downto 0);
        alu_result_ex_mem : out std_logic_vector(31 downto 0);
    );
end ex_mem_buffer;

architecture behavioral of ex_mem_buffer is

    signal temp_reg_write : std_logic;
    signal temp_mem_to_reg : std_logic;
    signal temp_mem_read : std_logic;
    signal temp_mem_write : std_logic;
    signal temp_branch : std_logic;
    signal temp_opcode : std_logic_vector(5 downto 0);
    signal temp_read_data2 : std_logic_vector(31 downto 0);
    signal temp_zero_flag : std_logic;
    signal temp_alu_result : std_logic_vector(31 downto 0);
    signal temp_rd : std_logic_vector(4 downto 0);

    begin 
    process (clk, reset, reg_write, mem_to_reg, mem_read, mem_write, branch, opcode, read_data2, zero_flag, alu_result, rd)
    begin
        if rising_edge(clk) then
            temp_reg_write <= reg_write;
            temp_mem_to_reg <= mem_to_reg;
            temp_mem_read <= mem_read;
            temp_mem_write <= mem_write;
            temp_branch <= branch;
            temp_opcode <= opcode;
            temp_read_data2 <= read_data2;
            temp_zero_flag <= zero_flag;
            temp_alu_result <= alu_result;
            temp_rd <= rd;
        end if;
        if falling_edge(clk) then
            if reset = '1' then
                reg_write_out <= '0';
                mem_to_reg_out <= '0';
                mem_read_out <= '0';
                mem_write_out <= '0';
                branch_out <= '0';
                opcode_out <= "000000";
                read_data2_out <= (others => '0');
                zero_flag_out <= '0';
                alu_result_out <= (others => '0');
                rd_out <= (others => '0');
                rd_ex_mem <= (others => '0');
                alu_result_ex_mem <= (others => '0');
            else
                reg_write_out <= temp_reg_write;
                mem_to_reg_out <= temp_mem_to_reg;
                mem_read_out <= temp_mem_read;
                mem_write_out <= temp_mem_write;
                branch_out <= temp_branch;
                opcode_out <= temp_opcode;
                read_data2_out <= temp_read_data2;
                zero_flag_out <= temp_zero_flag;
                alu_result_out <= temp_alu_result;
                rd_out <= temp_rd;
                rd_ex_mem <= temp_rd;
                alu_result_ex_mem <= temp_alu_result;
            end if;
            end if;
