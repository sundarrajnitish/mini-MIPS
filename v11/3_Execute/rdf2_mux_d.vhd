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

entity rdf2_mux_d is
    port(
        rd2 : in std_logic_vector(31 downto 0);
        fd2 : in std_logic_vector(31 downto 0);
        rdf2_mux_d_sel : in std_logic;

        rdf2_mux_d_out : out std_logic_vector(31 downto 0)
    );
end rdf2_mux_d;

architecture behavioral of rdf2_mux_d is
begin
    process(rd2, fd2, rdf2_mux_d_sel)
    begin
        case rdf2_mux_d_sel is
            when '0' => rdf2_mux_d_out <= rd2;
            when '1' => rdf2_mux_d_out <= fd2;
            when others => rdf2_mux_d_out <= rd2;
        end case;
    end process;
end behavioral;