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

entity wb_forward_control_unit is
    port(
        clk: in std_logic;
        reset: in std_logic;

        rs: in std_logic_vector(4 downto 0);
        rt: in std_logic_vector(4 downto 0);

        wb_rd: in std_logic_vector(4 downto 0);
        wb_data: in std_logic_vector(31 downto 0);

        wb_forward_rs: out std_logic;
        wb_forward_rt: out std_logic

        wb_forward_rs_data: out std_logic_vector(31 downto 0);
        
    );
end wb_forward_control_unit;

architecture behavioral of wb_forward_control_unit is

    begin
            process(clk, reset, wb_rd, rs, rt, wb_data)
            begin
                if rising_edge(clk) then
                if reset = '1' then
                    wb_forward_rs <= '0';
                    wb_forward_rt <= '0';
                    wb_forward_rs_data <= (others => '0');
                else
                    if wb_rd = rs then
                        wb_forward_rs <= '1';
                        wb_forward_rs_data <= wb_data;
                    else
                        wb_forward_rs <= '0';
                    end if;
    
                    if wb_rd = rt then
                        wb_forward_rt <= '1';
                    else
                        wb_forward_rt <= '0';
                    end if;
                end if;
            end if;
            end process;
        end behavioral;