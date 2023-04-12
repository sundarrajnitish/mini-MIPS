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

entity rt_rd_mux is
    port(
        rt : in std_logic_vector(4 downto 0);
        rd : in std_logic_vector(4 downto 0);
        rt_rd_mux_sel : in std_logic;

        rt_rd_mux_out : out std_logic_vector(4 downto 0)
    );
end rt_rd_mux;

architecture behavioral of rt_rd_mux is
begin
    process(rt, rd, rt_rd_mux_sel)
    begin
        case rt_rd_mux_sel is
            when '0' => rt_rd_mux_out <= rt;
            when '1' => rt_rd_mux_out <= rd;
            when others => rt_rd_mux_out <= rd;
        end case;
    end process;
end behavioral;