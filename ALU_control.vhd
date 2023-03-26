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
                    when "000000" => control_output <= "0100"; -- sll
                    when "100000" => control_output <= "0010"; -- add
                    when "100110" => control_output <= "0011"; -- xor
                    when "100111" => control_output <= "0000"; -- nor
                    when others => control_output <= "1111"; -- indicating invalid function code
                end case;
            when "001100" => control_output <= "1000"; -- andi
            when "011001" => control_output <= "0010"; -- subui
            when "000010" => control_output <= "1100"; -- j
            when "001000" => control_output <= "1111"; -- jr
            when "000100" => control_output <= "0011"; -- beq
            when "100011" => control_output <= "1111"; -- lw
            when "101000" => control_output <= "0010";-- sb
            when others => control_output <= "1111"; -- indicating invalid opcode
        end case;
    end process;
end behavioral;