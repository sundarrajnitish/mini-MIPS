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

entity control_unit is
    port(
        clk: in std_logic;
        flush: in std_logic;
        opcode: in std_logic_vector(5 downto 0);
        funct: in std_logic_vector(5 downto 0);

        alu_src: out std_logic := '0';
        reg_dst: out std_logic := '0';
        branch: out std_logic := '0';
        mem_read: out std_logic := '0';
        mem_write: out std_logic := '0';
        mem_to_reg: out std_logic := '0';
        reg_write: out std_logic := '0';
        jump_jr: out std_logic_vector(1 downto 0) := (others => '0');
        alu_op: out std_logic_vector(2 downto 0) := (others => '0')
    );
end control_unit;

architecture behavioral of control_unit is
begin
    process(clk, flush, opcode, funct)
    begin
        if rising_edge(clk) then
        if flush = '1' then
            alu_src <= '0';
            reg_dst <= '0';
            branch <= '0';
            mem_read <= '0';
            mem_write <= '0';
            mem_to_reg <= '0';
            reg_write <= '0';
            jump_jr <= "00";
            alu_op <= "000";
        elsif flush = '0' then
        case opcode is
            when "000000" => -- R-type General
                alu_src <= '0';
                reg_dst <= '1';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                jump_jr <= "00";
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
                alu_src <= '0';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '0';
                jump_jr <= "10";
            when others =>
                alu_src <= '0';
                reg_dst <= '1';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                jump_jr <= "00";
            end case;
            when "001100" => -- ANDI
                alu_src <= '1';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                jump_jr <= "00";
            when "011001" => -- SUBUI
                alu_src <= '1';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                jump_jr <= "00";
            when "000100" => -- BEQ
                alu_src <= '1';
                reg_dst <= '0';
                branch <= '1';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                jump_jr <= "00";
            when "100011" => -- LW
                alu_src <= '1';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '1';
                mem_write <= '0';
                mem_to_reg <= '1';
                reg_write <= '1';
                jump_jr <= "00";
            when "101000" => -- SB
                alu_src <= '1';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '1';
                mem_to_reg <= '0';
                reg_write <= '0';
                jump_jr <= "00";
            when "000010" => -- J-type
                alu_src <= '0';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '0';
                jump_jr <= "01";
            when others =>
                alu_src <= '0';
                reg_dst <= '0';
                branch <= '0';
                mem_read <= '0';
                mem_write <= '0';
                mem_to_reg <= '0';
                reg_write <= '0';
                jump_jr <= "00";
        end case;
        end if;
        end if;
    end process;
end behavioral;