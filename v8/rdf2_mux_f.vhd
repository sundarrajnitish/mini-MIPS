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

entity rdf2_mux_f is
    port(
        rd2 : in std_logic_vector(31 downto 0);
        fd2 : in std_logic_vector(31 downto 0);
        rdf2_mux_f_sel : in std_logic;

        rdf2_mux_f_out : out std_logic_vector(31 downto 0)
    );
end rdf2_mux_f;

architecture behavioral of rdf1_mux_e is
begin
    process(rd1, fd1, rdf2_mux_e_sel)
    begin
        case rdf2_mux_f_sel is
            when '0' => rdf2_mux_f_out <= rd2;
            when '1' => rdf2_mux_f_out <= fd2;
            when others => rdf2_mux_f_out <= rd2;
        end case;
    end process;
end behavioral;