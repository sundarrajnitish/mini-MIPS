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

entity alu_mux is
    port(
        input_1: in std_logic_vector(31 downto 0);
        input_2: in std_logic_vector(31 downto 0);
        select_signal: in std_logic;
        output_port: out std_logic_vector(31 downto 0)
    );
end entity alu_mux;

architecture behavioral of alu_mux is
    begin
        process (input_1, input_2, select_signal)
        begin
            if (select_signal = '0') then
                output_port <= input_1;
            elsif (select_signal = '1') then
                output_port <= input_2;
            end if;
        end process;
    end architecture behavioral;



