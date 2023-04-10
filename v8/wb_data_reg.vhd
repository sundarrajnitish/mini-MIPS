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

entity wb_data_reg is
    port( clk : in std_logic;
           wb_data : in std_logic_vector(31 downto 0);
           wb_data_out : out std_logic_vector(31 downto 0));
end wb_data_reg;

architecture behavioral of wb_data_reg is
begin
    process(clk, wb_data)
    begin
        if rising_edge(clk) then
            wb_data_out <= wb_data;
        end if;
    end process;
end behavioral;