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

entity mem_read_data_reg is
    port( clk : in std_logic;
           mem_read_data : in std_logic_vector(31 downto 0);
           mem_read_data_reg : out std_logic_vector(31 downto 0));
end mem_read_data_reg;

architecture behavioral of mem_read_data_reg is
begin
    process(clk, reset)
    begin
        if rising_edge(clk) then
            mem_read_data_reg <= mem_read_data;
        end if;
    end process;
end behavioral;