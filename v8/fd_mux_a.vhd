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

entity fd_mux_a is
    port(
        rd1 : in std_logic_vector(31 downto 0);
        fd1 : in std_logic_vector(31 downto 0);
        fd_mux_a_sel : in std_logic;

        fd_mux_a_out : out std_logic_vector(31 downto 0)
    );
end fd_mux_a;

architecture behavioral of fd_mux_a is
begin
    process(rd1, fd1, fd_mux_a_sel)
    begin
        case fd_mux_a_sel is
            when '0' => fd_mux_a_out <= rd1;
            when '1' => fd_mux_a_out <= fd1;
            when others => fd_mux_a_out <= rd1;
        end case;
    end process;
end behavioral;