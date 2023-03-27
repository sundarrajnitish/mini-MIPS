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
    port(
        data_1: in std_logic_vector(31 downto 0);
        data_2: in std_logic_vector(31 downto 0);
        alu_control: in std_logic_vector(3 downto 0);

        zero_flag: out std_logic;
        alu_output: out std_logic_vector(31 downto 0)
    );
end alu;

architecture behavioral of alu is
    signal c_nor: std_logic_vector(3 downto 0) := "0000";
    signal c_sll: std_logic_vector(3 downto 0) := "0001";
    signal c_xor: std_logic_vector(3 downto 0) := "0010";
    signal c_andi: std_logic_vector(3 downto 0) := "0100";
    signal c_subui: std_logic_vector(3 downto 0) := "0101";
    signal c_add: std_logic_vector(3 downto 0) := "0011";
    signal c_lw: std_logic_vector(3 downto 0) := "0111";
    signal c_sb: std_logic_vector(3 downto 0) := "1000";

    signal temp_output: std_logic_vector(31 downto 0);


    begin
        temp_output <= data_1 nor data_2 when alu_control = c_nor else
                        std_logic_vector(unsigned(data_1) sll to_integer(unsigned(data_2))) when alu_control = c_sll else
                        data_1 xor data_2 when alu_control = c_xor else
                        data_1 and data_2 when alu_control = c_andi else
                        std_logic_vector(unsigned(data_1) - unsigned(data_2)) when alu_control = c_subui else
                        std_logic_vector(unsigned(data_1) + unsigned(data_2)) when alu_control = c_add else
                        data_1 when alu_control = c_lw else
                        data_1 when alu_control = c_sb;

        alu_output <= temp_output;

        case temp_output is
            when "00000000000000000000000000000000" => zero_flag <= '1';
            when others => zero_flag <= '0';
       end case;


end behavioral;