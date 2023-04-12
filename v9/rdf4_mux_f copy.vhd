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
        rd1 : in std_logic_vector(31 downto 0);
        fd1 : in std_logic_vector(31 downto 0);
        rdf1_mux_e_sel : in std_logic;

        rdf1_mux_e_out : out std_logic_vector(31 downto 0)
    );
end rdf4_mux_f;

architecture behavioral of rdf4_mux_f is
begin
    process(rd1, fd1, rdf1_mux_e_sel)
    begin
        case rdf1_mux_e_sel is
            when '0' => rdf1_mux_e_out <= rd1;
            when '1' => rdf1_mux_e_out <= fd1;
            when others => rdf1_mux_e_out <= rd1;
        end case;
    end process;
end behavioral;