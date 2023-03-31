------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity if_id_buffer is
    Port (clk, reset, enable : in std_logic;
          pc_in, instruction_in : in std_logic_vector(31 downto 0);
          pc_out, instruction_out : out std_logic_vector(31 downto 0):= (others => '0'));
end if_id_buffer;

architecture behavioral of if_id_buffer is
begin
    process(clk, reset)
    begin
        if (reset = '1') then
            pc_out <= (others => '0');
            instruction_out <= (others => '0');
        elsif (clk'event and clk = '0') then
            if (enable = '1') then
                pc_out <= pc_in;
                instruction_out <= instruction_in;
            end if;
        end if;
    end process;
end behavioral;