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

entity decode_mux is
    port(
        rt: in std_logic_vector(4 downto 0);
        rd: in std_logic_vector(4 downto 0);
        reg_dst: in std_logic;
        d_write_register: out std_logic_vector(4 downto 0)
    );
end entity decode_mux;

architecture behavioral of decode_mux is
    begin
        process (rt, rd, reg_dst)
        begin
            if (reg_dst = '0') then
                d_write_register <= rt;
            elsif (reg_dst = '1') then
                d_write_register <= rd;
            end if;
        end process;
    end architecture behavioral;



