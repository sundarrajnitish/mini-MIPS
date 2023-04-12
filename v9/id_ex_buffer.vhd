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
        alu_op_in : in std_logic_vector(2 downto 0);

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
        alu_src_out : out std_logic;
        alu_op_out : out std_logic_vector(2 downto 0)
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

    signal opcode : std_logic_vector(5 downto 0) := (others => '0');
    signal funct : std_logic_vector(5 downto 0) := (others => '0');

    signal read_data1 : std_logic_vector(31 downto 0) := (others => '0');
    signal read_data2 : std_logic_vector(31 downto 0) := (others => '0');

    signal shamt : std_logic_vector(4 downto 0) := (others => '0');
    signal immediate_32 : std_logic_vector(31 downto 0) := (others => '0');

    signal rs : std_logic_vector(4 downto 0) := (others => '0');
    signal rt : std_logic_vector(4 downto 0) := (others => '0');
    signal rd : std_logic_vector(4 downto 0) := (others => '0');

begin
    
        process(clk, flush)
        begin
            if rising_edge(clk) then
            
                reg_write <= reg_write_in;
                mem_to_reg <= mem_to_reg_in;
                branch <= branch_in;
                mem_read <= mem_read_in;
                mem_write <= mem_write_in;
                reg_dst <= reg_dst_in;
                alu_src <= alu_src_in;
    
                opcode <= opcode_in;
                funct <= funct_in;
    
                read_data1 <= read_data1_in;
                read_data2 <= read_data2_in;
    
                shamt <= shamt_in;
                immediate_32 <= immediate_32_in;
    
                rs <= rs_in;
                rt <= rt_in;
                rd <= rd_in;
            end if;
        
        
        if falling_edge(clk) then
            if(flush = '1') then
                reg_write <= '0';
                mem_to_reg <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                reg_dst <= '0';
                alu_src <= '0';
    
                opcode <= (others => '0');
                funct <= (others => '0');
    
                read_data1 <= (others => '0');
                read_data2 <= (others => '0');
    
                shamt <= (others => '0');
                immediate_32 <= (others => '0');
    
                rs <= (others => '0');
                rt <= (others => '0');
                rd <= (others => '0');
            else
        reg_write_out <= reg_write;
        mem_to_reg_out <= mem_to_reg;
        branch_out <= branch;
        mem_read_out <= mem_read;
        mem_write_out <= mem_write;
        reg_dst_out <= reg_dst;
        alu_src_out <= alu_src;
        alu_op_out <= alu_op_in;
    
        opcode_out <= opcode;
        funct_out <= funct;
    
        read_data1_out <= read_data1;
        read_data2_out <= read_data2;
    
        shamt_out <= shamt;
        immediate_32_out <= immediate_32;
    
        rs_out <= rs;
        rt_out <= rt;
        rd_out <= rd;
        end if;
        end if;
        end process;
    
    end behavioral;



