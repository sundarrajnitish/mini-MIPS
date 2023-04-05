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

entity if_mux_2 is
    port(
        jr: in std_logic_vector(31 downto 0);
        j: in std_logic_vector(31 downto 0);
        address: in std_logic_vector(31 downto 0);
        select_signal: in std_logic_vector(1 downto 0);
        output_port: out std_logic_vector(31 downto 0)
    );
end entity if_mux_2;

architecture behavioral of if_mux_2 is
    begin
        process (jr, j, address, select_signal)
        begin
            if (select_signal = "00") then
                output_port <= jr;
            elsif (select_signal = "01") then
                output_port <= j;
            elsif (select_signal = "10") then
                output_port <= address;
            end if;
        end process;
    end architecture behavioral;



