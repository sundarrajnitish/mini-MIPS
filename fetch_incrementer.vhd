------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity incrementer is
    Port ( clk : in std_logic;
           input_address : in std_logic_vector(31 downto 0);
           output_address : out std_logic_vector(31 downto 0));
end incrementer;

architecture behavioral of incrementer is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            output_address <= input_address + 4;
        end if;
    end process;
end behavioral;