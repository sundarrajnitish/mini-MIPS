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

entity rdf1_mux_c is
    port(
        rd1 : in std_logic_vector(31 downto 0);
        fd1 : in std_logic_vector(31 downto 0);
        rdf1_mux_c_sel : in std_logic;

        rdf1_mux_c_out : out std_logic_vector(31 downto 0)
    );
end rdf1_mux_c;

architecture behavioral of rdf1_mux_c is
begin
    process(rd1, fd1, rdf1_mux_c_sel)
    begin
        case rdf1_mux_c_sel is
            when '0' => rdf1_mux_c_out <= rd1;
            when '1' => rdf1_mux_c_out <= fd1;
            when others => rdf1_mux_c_out <= rd1;
        end case;
    end process;
end behavioral;