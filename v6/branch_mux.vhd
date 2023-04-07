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

entity branch_mux is
    port(
        pc_plus_four: in std_logic_vector(31 downto 0);
        branch_address: in std_logic_vector(31 downto 0);
        select_signal: in std_logic_vector(1 downto 0);

        output_port: out std_logic_vector(31 downto 0)
    );
end entity branch_mux;

architecture behavioral of branch_mux is
    begin
        process (pc_plus_four, branch_address, select_signal)
        begin
                case select_signal is
                    when "00" => output_port <= pc_plus_four;
                    report "Branch Mux: Select signal is 00";
                    when "01" => output_port <= branch_address;
                    report "Branch Mux: Select signal is 01";
                    when others => output_port <= pc_plus_four;
                end case;
        end process;
    end architecture behavioral;

-- Standard 3 into 1 MUX where we select either the branch address, the jump address or the jump register address
