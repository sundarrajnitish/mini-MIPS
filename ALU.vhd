------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity alu is
    port(
        data_1: in std_logic_vector(31 downto 0);
        data_2: in std_logic_vector(31 downto 0);

        zero_flag: out std_logic;
        alu_output: out std_logic_vector(31 downto 0);
    )