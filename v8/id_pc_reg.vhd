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

entity id_pc_reg is
    port( clk : in std_logic;
           pc : in std_logic_vector(31 downto 0);
           pc_reg : out std_logic_vector(31 downto 0));
end id_pc_reg;

architecture behavioral of id_pc_reg is
begin
    process(clk, pc)
    begin
        if rising_edge(clk) then
            pc_reg <= pc;
        end if;
    end process;
end behavioral;