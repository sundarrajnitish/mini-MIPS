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

entity id_ex_buffer is
    port ( 
        clk : in std_logic;
        flush : in std_logic;
        next_address : in std_logic_vector(31 downto 0);

        reg_write_in : in std_logic;
        mem_to_reg_in : in std_logic;
        branch_in : in std_logic;
        mem_read_in : in std_logic;
        mem_write_in : in std_logic;
        reg_dst_in : in std_logic;
        alu_src_in : in std_logic;

        opcode_in : in std_logic_vector(5 downto 0);
        funct_in : in std_logic_vector(5 downto 0);

        read_data1_in : in std_logic_vector(31 downto 0);
        read_data2_in : in std_logic_vector(31 downto 0);

        shamt_in : in std_logic_vector(4 downto 0);
        immediate_32_in : in std_logic_vector(31 downto 0);

        rs_in : in std_logic_vector(4 downto 0);
        rt_in : in std_logic_vector(4 downto 0);
        rd_in : in std_logic_vector(4 downto 0);

        opcode_out : out std_logic_vector(5 downto 0);
        funct_out : out std_logic_vector(5 downto 0);

        read_data1_out : out std_logic_vector(31 downto 0);
        read_data2_out : out std_logic_vector(31 downto 0);

        shamt_out : out std_logic_vector(4 downto 0);
        immediate_32_out : out std_logic_vector(31 downto 0);

        rs_out : out std_logic_vector(4 downto 0);
        rt_out : out std_logic_vector(4 downto 0);
        rd_out : out std_logic_vector(4 downto 0);

        reg_write_out : out std_logic;
        mem_to_reg_out : out std_logic;
        branch_out : out std_logic;
        mem_read_out : out std_logic;
        mem_write_out : out std_logic;
        reg_dst_out : out std_logic;
        alu_src_out : out std_logic
    );

end id_ex_buffer;

architecture behavioral of id_ex_buffer is

    signal reg_write : std_logic := '0';
    signal mem_to_reg : std_logic := '0';
    signal branch : std_logic := '0';
    signal mem_read : std_logic := '0';
    signal mem_write : std_logic := '0';
    signal reg_dst : std_logic := '0';
    signal alu_src : std_logic := '0';



