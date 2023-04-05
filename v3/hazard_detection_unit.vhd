------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hazard_detection_unit is
    port(
        clk : in std_logic;
        jump : in std_logic;
        jump_reg : in std_logic;
        branch : in std_logic;
        mem_read : in std_logic;

        pc_flush : out std_logic;
        if_id_flush : out std_logic;
        id_ex_flush : out std_logic;
        jump_jr : out std_logic_vector(1 downto 0);
    );

end hazard_detection_unit;

architecture behavioral of hazard_detection_unit is
    begin
        process(clk)
        begin
            if rising_edge(clk) then
                if jump = '1' then
                    pc_flush <= '1';
                    if_id_flush <= '1';
                    id_ex_flush <= '0';
                    jump_jr <= '01';
                elsif jump_reg = '1' then
                    pc_flush <= '1';
                    if_id_flush <= '1';
                    id_ex_flush <= '1';
                    jump_jr <= '10';
                elsif branch = '1' or mem_read = '1' then
                    pc_flush <= '1';
                    if_id_flush <= '1';
                    id_ex_flush <= '0';
                    jump_jr <= '0';
                else
                    pc_flush <= '0';
                    if_id_flush <= '0';
                    id_ex_flush <= '0';
                    jump_jr <= '0';
                end if;
            end if;
        end process;
    end behavioral;