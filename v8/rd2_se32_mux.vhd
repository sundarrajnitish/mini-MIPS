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

entity rd2_se32_mux is
    port(
        rd2 : in std_logic_vector(31 downto 0);
        se32 : in std_logic_vector(31 downto 0);
        rd2_se32_mux_sel : in std_logic;

        rd2_se32_mux_out : out std_logic_vector(31 downto 0)
    );
end rd2_se32_mux;

architecture behavioral of rd2_se32_mux is
begin
    process(rd2, se32, rd2_se32_mux_sel)
    begin
        case rd2_se32_mux_sel is
            when '0' => rd2_se32_mux_out <= rd2;
            when '1' => rd2_se32_mux_out <= se32;
            when others => rd2_se32_mux_out <= rd2;
        end case;
    end process;
end behavioral;