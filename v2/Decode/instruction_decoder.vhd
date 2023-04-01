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

entity instruction_decoder is
    port ( 
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
end instruction_decoder;

architecture behavioral of instruction_decoder is
begin
    process(clk, reset)
    begin
        if reset = '1' and clk = '0' then
            opcode <= (others => '0');
            funct <= (others => '0');
            rs <= (others => '0');
            rt <= (others => '0');
            rd <= (others => '0');
            shamt <= (others => '0');
            immediate <= (others => '0');
            address <= (others => '0');
        elsif clk = '1' and reset = '0' then
            opcode <= instruction(31 downto 26);
            funct <= instruction(5 downto 0);
            rs <= instruction(25 downto 21);
            rt <= instruction(20 downto 16);
            rd <= instruction(15 downto 11);
            shamt <= instruction(10 downto 6);
            immediate <= instruction(15 downto 0);
            address <= instruction(25 downto 0);
        end if;
    end process;
end behavioral;