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

entity alu_control_unit is 
    port(
        clk : in std_logic;
        opcode: in std_logic_vector(5 downto 0);
        funct: in std_logic_vector(5 downto 0);

        alu_op: out std_logic_vector(2 downto 0)
    );
end alu_control_unit;

architecture behavioral of alu_control_unit is
    begin
        process(clk, opcode, funct)
        begin
            if rising_edge(clk) then
            case opcode is
                when "000000" => --R-type
                    case funct is
                        when "100111" => --nor
                            alu_op <= "011";
                        when "000000" => --sll
                            alu_op <= "100";
                        when "100110" => --xor
                            alu_op <= "010";
                        when "100000" => --add
                            alu_op <= "000";
                        when "001000" => --jr
                            null;
                        when others =>
                            null;
                    end case;
                when "001100" => --andi
                    alu_op <= "001";
                when "011001" => --subui
                    alu_op <= "110";
                when "000100" => --beq
                    alu_op <= "000";
                when "100011" => --lw
                    alu_op <= "000";
                when "101000" => --sb
                    alu_op <= "000";
                when "000010" => --j
                    null;
                when others =>
                    null;
            end case;
            end if;
        end process;
    end behavioral;

