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

entity fetch_incrementer is
    Port ( clk : in std_logic;
           address_out : in std_logic_vector(31 downto 0);
           output_address : out std_logic_vector(31 downto 0));
end fetch_incrementer;

architecture behavioral of fetch_incrementer is
begin
    process(clk)
    begin
        if clk'event and clk = '0' then
            output_address <= address_out + 4;
        end if;
    end process;
end behavioral;