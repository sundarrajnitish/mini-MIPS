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

entity rdf3_mux_e is
    port(
        rd1 : in std_logic_vector(31 downto 0);
        fd3 : in std_logic_vector(31 downto 0);
        rdf3_mux_e_sel : in std_logic;

        rdf3_mux_e_out : out std_logic_vector(31 downto 0)
    );
end rdf3_mux_e;

architecture behavioral of rdf3_mux_e is
begin
    process(rd1, fd3, rdf3_mux_e_sel)
    begin
        case rdf3_mux_e_sel is
            when '0' => rdf3_mux_e_out <= rd1;
            when '1' => rdf3_mux_e_out <= fd3;
            when others => rdf3_mux_e_out <= rd1;
        end case;
    end process;
end behavioral;