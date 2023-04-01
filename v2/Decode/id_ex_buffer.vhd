------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity id_ex_buffer is
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
end id_ex_buffer;

architecture rtl of id_ex_buffer is
begin
    -- Outputs to EX stage
    ex_read_reg_1 <= std_logic_vector(resize(unsigned(read_reg_1), 32));
    ex_read_reg_2 <= std_logic_vector(resize(unsigned(read_reg_2), 32));
    ex_immediate <= std_logic_vector(resize(unsigned(immediate), 32));
    ex_pc <= std_logic_vector(resize(unsigned(pc), 32));
    ex_reg_write <= reg_write;
    ex_mem_write <= mem_write;
    ex_mem_read <= mem_read;
    ex_mem_to_reg <= mem_to_reg;
    ex_alu_op <= alu_op;
    ex_branch <= branch;
end rtl;
