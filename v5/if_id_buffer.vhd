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

entity if_id_buffer is
    port ( 
        clk : in std_logic;
        flush : in std_logic;
        instruction : in std_logic_vector(31 downto 0);
        next_address : in std_logic_vector(31 downto 0);

        pc_4 : out std_logic_vector(31 downto 0);
        pc_concat : out std_logic_vector(3 downto 0);
        opcode : out std_logic_vector(5 downto 0);
        funct : out std_logic_vector(5 downto 0);
        rs : out std_logic_vector(4 downto 0);
        rt : out std_logic_vector(4 downto 0);
        rd : out std_logic_vector(4 downto 0);
        shamt : out std_logic_vector(4 downto 0);
        immediate : out std_logic_vector(15 downto 0);
        jump_address : out std_logic_vector(25 downto 0)
    );
end if_id_buffer;

architecture behavioral of if_id_buffer is
begin
    process(clk, flush, instruction, next_address)
    begin
        if flush = '1' and falling_edge(clk) then
            pc_4 <= (others => '0');
            pc_concat <= (others => '0');
            opcode <= (others => '0');
            funct <= (others => '0');
            rs <= (others => '0');
            rt <= (others => '0');
            rd <= (others => '0');
            shamt <= (others => '0');
            immediate <= (others => '0');
            jump_address <= (others => '0');
            report "IF/ID Buffer Flushed";
        elsif falling_edge(clk) and flush = '0' then
            pc_4 <= next_address;
            pc_concat <= next_address(31 downto 28);
            opcode <= instruction(31 downto 26);
            funct <= instruction(5 downto 0);
            rs <= instruction(25 downto 21);
            rt <= instruction(20 downto 16);
            rd <= instruction(15 downto 11);
            shamt <= instruction(10 downto 6);
            immediate <= instruction(15 downto 0);
            jump_address <= instruction(25 downto 0);
            report "IF/ID Buffer Updated";
        end if;
    end process;
end behavioral;

-- Standard implementation of the IF/ID buffer
