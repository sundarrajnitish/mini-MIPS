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

entity fd_mux_b is
    port(
        rd2 : in std_logic_vector(31 downto 0);
        fd2 : in std_logic_vector(31 downto 0);
        fd_mux_b_sel : in std_logic;

        fd_mux_b_out : out std_logic_vector(31 downto 0)
    );
end fd_mux_b;

architecture behavioral of fd_mux_b is
begin
    process(rd2, fd2, fd_mux_b_sel)
    begin
        case fd_mux_b_sel is
            when '0' => fd_mux_b_out <= rd2;
            when '1' => fd_mux_b_out <= fd2;
            when others => fd_mux_b_out <= rd2;
        end case;
    end process;
end behavioral;