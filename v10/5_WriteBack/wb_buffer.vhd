------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_buffer is
    port(
        clk: in std_logic;

        mem_wb_rd: in std_logic_vector(4 downto 0);
        wb_data: in std_logic_vector(31 downto 0);

        mem_wb_reg_rd: out std_logic_vector(4 downto 0);
        mem_wb_reg_data: out std_logic_vector(31 downto 0)
    );

end entity wb_buffer;

architecture behavioral of wb_buffer is 
begin 
process(clk, mem_wb_rd, wb_data)
begin
    if rising_edge(clk) then
        mem_wb_reg_rd <= mem_wb_rd;
        mem_wb_reg_data <= wb_data;
    end if;
end process;
end architecture behavioral;