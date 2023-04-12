------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity branch_and_gate is
    Port ( 
        branch : in std_logic;
        zero : in std_logic;
        gate_output : out std_logic
    );
end branch_and_gate;

architecture behavioral of branch_and_gate is
begin
    process (branch, zero)
    begin
        if (branch = '1' and zero = '1') then
            gate_output <= '1';
        else
        gate_output <= '0';
        end if;
    end process;
end behavioral;