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

entity alu_control is
    port (
        instruction : in std_logic_vector(31 downto 0);
        control_output : out std_logic_vector(3 downto 0)
    );
end alu_control;

architecture behavioral of alu_control is
    signal opcode : std_logic_vector(5 downto 0) := instruction(31 downto 26);
    signal fucode : std_logic_vector(5 downto 0) := instruction(5 downto 0);
begin
    process (instruction)
    begin
        case opcode is
            when "000000" => -- R-type
                case fucode is
                    when "100111" => control_output <= "0000"; -- nor --0
                    when "000000" => control_output <= "0001"; -- sll --1
                    when "100110" => control_output <= "0010"; -- xor --2
                    when "100000" => control_output <= "0011"; -- add --3
                    when others => control_output <= "1110"; -- indicating invalid function code
                end case;
            when "001100" => control_output <= "0100"; -- andi -- 4
            when "011001" => control_output <= "0101"; -- subui -- 5
            when "000100" => control_output <= "0110"; -- beq -- 6
            when "100011" => control_output <= "0111"; -- lw --7
            when "101000" => control_output <= "1000";-- sb --8
            when "001000" => control_output <= "1001"; -- jr --9
            when "000010" => control_output <= "1010"; -- j --10
            when others => control_output <= "1111"; -- indicating invalid opcode
        end case;
    end process;
end behavioral;