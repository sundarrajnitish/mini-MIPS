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

entity alu is
    port (
        clk : in std_logic;
        aluop : in std_logic_vector(2 downto 0);
        shamt : in std_logic_vector(4 downto 0);
        input_a : in std_logic_vector(31 downto 0);
        input_b : in std_logic_vector(31 downto 0);

        alu_result : out std_logic_vector(31 downto 0);
        zero : out std_logic
    );
end alu;

architecture behavioral of alu is

    signal temp_alu_result : std_logic_vector(31 downto 0);

    begin 
    process (clk, aluop, input_a, input_b, shamt)
    begin
        if rising_edge(clk) then
        case aluop is
            when "011" => temp_alu_result <= input_a nor input_b;
            when "100" => temp_alu_result <= std_logic_vector(shift_left(unsigned(input_b), to_integer(unsigned(shamt))));
            when "010" => temp_alu_result <= input_a xor input_b;
            when "000" => temp_alu_result <= std_logic_vector(unsigned(input_a) + unsigned(input_b));

            when "001" => temp_alu_result <= input_a and input_b;
            when "110" => temp_alu_result <= std_logic_vector(unsigned(input_a) - to_integer(unsigned(input_b)));
            when others =>
                temp_alu_result <= (others => '0');
        end case;
        case temp_alu_result is
            when "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" | "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" =>
                alu_result <= "00000000000000000000000000000000";
            when others =>
                null;
        end case;
        alu_result <= temp_alu_result;
        case temp_alu_result is
            when "00000000000000000000000000000000" => zero <= '1';
            when others => zero <= '0';
        end case;
        end if;
    end process;
end behavioral;

