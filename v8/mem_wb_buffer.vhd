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

entity mem_wb_buffer is
    port(
        clk : in std_logic;
        reset : in std_logic;

        reg_write : in std_logic;
        mem_to_reg : in std_logic;

        read_data_reg : in std_logic_vector(31 downto 0);

        alu_result : in std_logic_vector(31 downto 0);

        rd : in std_logic_vector(4 downto 0);

        reg_write_out : out std_logic;
        mem_to_reg_out : out std_logic;

        read_data_reg_out : out std_logic_vector(31 downto 0);

        alu_result_out : out std_logic_vector(31 downto 0);

        rd_out : out std_logic_vector(4 downto 0);

        rd_mem_wb : out std_logic_vector(4 downto 0);
        alu_result_mem_wb : out std_logic_vector(31 downto 0)

    );

end mem_wb_buffer;

architecture behavioral of mem_wb_buffer is

    begin 
    process (clk, reset, reg_write, mem_to_reg, read_data_reg, alu_result, rd)
    begin 
    if falling_edge(clk) then
        if reset = '1' then
            reg_write_out <= '0';
            mem_to_reg_out <= '0';
            read_data_reg_out <= (others => '0');
            alu_result_out <= (others => '0');
            rd_out <= (others => '0');
            rd_mem_wb <= (others => '0');
            alu_result_mem_wb <= (others => '0');
        else
            reg_write_out <= reg_write;
            mem_to_reg_out <= mem_to_reg;
            read_data_reg_out <= read_data_reg;
            alu_result_out <= alu_result;
            rd_out <= rd;
            rd_mem_wb <= rd;
            alu_result_mem_wb <= alu_result;
        end if;
    end if;
    end process;
