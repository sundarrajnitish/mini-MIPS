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

entity jump_mux is
    port(
        pc_4: in std_logic_vector(31 downto 0);
        jump_address: in std_logic_vector(31 downto 0);
        jr_address: in std_logic_vector(31 downto 0);

        select_signal: in std_logic_vector(1 downto 0);

        output_port: out std_logic_vector(31 downto 0)
    );
end entity jump_mux;

architecture behavioral of jump_mux is
    begin
        process (pc_4, jump_address, jr_address, select_signal)
        begin
                case select_signal is
                    when "00" => output_port <= pc_4;
                    when "01" => output_port <= jump_address;
                    when "10" => output_port <= jr_address;
                    when others => output_port <= pc_4;
                end case;
        end process;
    end architecture behavioral;

-- Standard 3 into 1 MUX where we select either the branch address, the load address or the incremented pc address
