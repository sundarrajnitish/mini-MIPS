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

entity if_mux_1 is
    port(
        pc_in: in std_logic_vector(31 downto 0);
        branch_address: in std_logic_vector(31 downto 0);
        select_signal: in std_logic;
        output_port: out std_logic_vector(31 downto 0)
    );
end entity if_mux_1;

architecture behavioral of if_mux_1 is
    begin
        process (pc_in, branch_address, select_signal)
        begin
            if (select_signal = '0') then
                output_port <= pc_in;
            elsif (select_signal = '1') then
                output_port <= branch_address;
            end if;
        end process;
    end architecture behavioral;



