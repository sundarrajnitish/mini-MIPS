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

entity hazard_control_unit is
    port(
        clk : in std_logic;
        pc : in std_logic_vector(31 downto 0);
        and_branch : in std_logic;
        jump_jr : in std_logic_vector(1 downto 0);
        mem_wb_mem_to_reg : in std_logic;
        rs : in std_logic_vector(4 downto 0);
        rt : in std_logic_vector(4 downto 0);
        ex_mem_rd : in std_logic_vector(4 downto 0);

        jump_mux_signal : out std_logic_vector(1 downto 0);
        if_id_flush : out std_logic;
        control_flush : out std_logic; 
        id_ex_flush : out std_logic;
        branch_address : out std_logic_vector(31 downto 0)
    );

end hazard_control_unit;

architecture behavioral of hazard_control_unit is

    signal temp_rs : std_logic_vector(4 downto 0) := (others => '0');
    signal temp_rt : std_logic_vector(4 downto 0) := (others => '0');

    begin
        process(pc, and_branch, jump_jr, mem_wb_mem_to_reg)
        begin
        if rising_edge(clk) then
        case and_branch is
            when '1' =>
                jump_mux_signal <= "11";
                if_id_flush <= '1';
                control_flush <= '1';
                id_ex_flush <= '1';
                branch_address <= (others => '0');
            when others =>
                jump_mux_signal <= "00";
                if_id_flush <= '0';
                control_flush <= '0';
                id_ex_flush <= '0';
                branch_address <= (others => '0');
        end case;
        
        case jump_jr is
            when "01" =>
                jump_mux_signal <= "01"; --jump
                if_id_flush <= '1';
                control_flush <= '1';
                id_ex_flush <= '1';
                branch_address <= (others => '0');
            when "10" =>
                jump_mux_signal <= "10"; --jr
                if_id_flush <= '1';
                control_flush <= '1';
                id_ex_flush <= '1';
                branch_address <= (others => '0');
            when others =>
                jump_mux_signal <= "00";
                if_id_flush <= '0';
                control_flush <= '0';
                id_ex_flush <= '0';
                branch_address <= (others => '0');
        end case;

        case mem_wb_mem_to_reg is
            when '1' =>
                jump_mux_signal <= "00";
                if_id_flush <= '0';
                control_flush <= '0';
                id_ex_flush <= '0';
                branch_address <= (others => '0');
            when others =>
            if (ex_mem_rd = rs) then
                    if_id_flush <= '1';
                    control_flush <= '1';
                    id_ex_flush <= '1';
                    branch_address <= pc;
            elsif (ex_mem_rd = rt) then
                    if_id_flush <= '1';
                    control_flush <= '1';
                    id_ex_flush <= '1';
                    branch_address <= pc;
            else
                    if_id_flush <= '0';
                    control_flush <= '0';
                    id_ex_flush <= '0';
                    branch_address <= (others => '0');
            end if;
        end case;
        end if;
    end process;
end behavioral;



