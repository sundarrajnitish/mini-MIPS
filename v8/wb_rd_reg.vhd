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

entity wb_rd_reg is
    port( clk : in std_logic;
           wb_rd : in std_logic_vector(4 downto 0);
           wb_rd_out : out std_logic_vector(4 downto 0));
end wb_rd_reg;

architecture behavioral of wb_rd_reg is
begin
    process(clk, wb_rd)
    begin
        if rising_edge(clk) then
            wb_rd_out <= wb_rd;
        end if;
    end process;
end behavioral;