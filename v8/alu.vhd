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

    begin 
    process (clk, aluop, input_a, input_b)
    begin
        case alu_op is
            when "011" => alu_result <= input_a nor input_b;
