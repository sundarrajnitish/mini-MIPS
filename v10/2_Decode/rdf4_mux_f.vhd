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

entity rdf4_mux_f is
    port(
        rd2 : in std_logic_vector(31 downto 0);
        fd4 : in std_logic_vector(31 downto 0);
        rdf4_mux_f_sel : in std_logic;

        rdf4_mux_f_out : out std_logic_vector(31 downto 0)
    );
end rdf4_mux_f;

architecture behavioral of rdf4_mux_f is
begin
    process(rd2, fd4, rdf4_mux_f_sel)
    begin
        case rdf4_mux_f_sel is
            when '0' => rdf4_mux_f_out <= rd2;
            when '1' => rdf4_mux_f_out <= fd4;
            when others => rdf4_mux_f_out <= rd2;
        end case;
    end process;
end behavioral;