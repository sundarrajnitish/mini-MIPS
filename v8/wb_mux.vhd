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

entity wb_mux is
    port(
        read_data : in std_logic_vector(4 downto 0);
        alu_result : in std_logic_vector(4 downto 0);
        mem_to_reg : in std_logic;

        wb_mux_out : out std_logic_vector(4 downto 0)
    );
end wb_mux;

architecture behavioral of wb_mux is
begin
    process(read_data, alu_result, mem_to_reg)
    begin
        case mem_to_reg is
            when '0' => wb_mux_out <= alu_result;
            when '1' => wb_mux_out <= read_data;
            when others => wb_mux_out <= alu_result;
        end case;
    end process;
end behavioral;