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
        if_id_rs : in std_logic_vector(4 downto 0);
        if_id_rt : in std_logic_vector(4 downto 0);
        id_ex_opcode : in std_logic_vector(5 downto 0);
        id_ex_rt : in std_logic_vector(4 downto 0);

        control_flush : out std_logic; 
        id_ex_flush : out std_logic;
        ex_mem_flush : out std_logic;
        load_address : out std_logic_vector(31 downto 0);
        branch_mux_signal : out std_logic_vector(1 downto 0);
        jump_mux_signal : out std_logic_vector(1 downto 0);
        if_id_flush : out std_logic
        
    );

end hazard_control_unit;

architecture behavioral of hazard_control_unit is


    begin
        process(clk, pc, and_branch, jump_jr, if_id_rs, if_id_rt, id_ex_opcode, id_ex_rt)
        begin
        if rising_edge(clk) then
            -- Load Hazard
            if (id_ex_opcode = "100011" and id_ex_rt = if_id_rs) then
                control_flush <= '1';
                id_ex_flush <= '1';
                ex_mem_flush <= '0';
                load_address <= pc;
                branch_mux_signal <= "10";
                jump_mux_signal <= "00";
                if_id_flush <= '1';
                report "Load Hazard pipeline flushed";

            elsif (id_ex_opcode = "100011" and id_ex_rt = if_id_rt) then
                control_flush <= '1';
                id_ex_flush <= '1';
                load_address <= pc;
                ex_mem_flush <= '0';
                branch_mux_signal <= "10";
                jump_mux_signal <= "00";
                if_id_flush <= '1';
                report "Load Hazard pipeline flushed";
            -- Branch Hazard
            elsif (and_branch = '1') then
                control_flush <= '1';
                id_ex_flush <= '1';
                ex_mem_flush <= '1';
                load_address <= (others => '0');
                branch_mux_signal <= "10";
                jump_mux_signal <= "00";
                if_id_flush <= '1';
                report "Branch Detected pipeline flushed";
            -- Jump Hazard
            elsif (jump_jr = "01") then
                control_flush <= '1';
                id_ex_flush <= '1';
                ex_mem_flush <= '0';
                load_address <= (others => '0');
                branch_mux_signal <= "00";
                jump_mux_signal <= "01";
                if_id_flush <= '1';
                report "Jump Detected pipeline flushed";
            elsif (jump_jr = "10") then
                control_flush <= '1';
                id_ex_flush <= '1';
                ex_mem_flush <= '0';
                load_address <= (others => '0');
                branch_mux_signal <= "00";
                jump_mux_signal <= "10";
                if_id_flush <= '1';
                report "Jump Detected pipeline flushed";
            -- No Hazard
            else
                control_flush <= '0';
                id_ex_flush <= '0';
                ex_mem_flush <= '0';
                load_address <= (others => '0');
                branch_mux_signal <= "00";
                jump_mux_signal <= "00";
                if_id_flush <= '0';
        
        end if;
        end if;
    end process;
end behavioral;



