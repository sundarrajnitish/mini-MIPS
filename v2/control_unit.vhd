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
        opcode: in std_logic_vector(5 downto 0);
        funct: in std_logic_vector(5 downto 0);

        reg_dst: out std_logic;
        reg_write: out std_logic;
        alu_src: out std_logic;
        mem_read: out std_logic;
        mem_write: out std_logic;
        branch: out std_logic := '0';
        jump: out std_logic;
        pc_src: out std_logic;
        mem_to_reg: out std_logic;

        alu_op: out std_logic_vector(2 downto 0)
        
    );
end control_unit;   

architecture control of control_unit is
begin
    process(opcode, funct)
    begin
        if clk = '1' then
        case opcode is
            when "000000" => -- R-type
                reg_dst <= '1';
                alu_src <= '0';
                mem_to_reg <= '0';
                reg_write <= '1';
                mem_read <= '0';
                mem_write <= '0';
                jump <= '0';
                pc_src <= '0';
                case funct is
                    when "100111" => -- nor
                        alu_op <= "100";
                    when "000000" => -- sll
                        alu_op <= "101";
                    when "100110" => -- xor
                        alu_op <= "011";
                    when "100000" => -- add
                        alu_op <= "001";
                    when "001000" => -- jr
                        alu_op <= "111";
                        reg_dst <= '0';
                        alu_src <= '0';
                        mem_to_reg <= '0';
                        reg_write <= '0';
                        mem_read <= '0';
                        mem_write <= '0';
                        jump <= '1';
                        pc_src <= '1';
                    when others => -- invalid
                        alu_op <= "111";
                end case;
            when "001100" => -- andi
                reg_dst <= '0';
                alu_src <= '1';
                mem_to_reg <= '0';
                reg_write <= '1';
                mem_read <= '0';
                mem_write <= '0';
                alu_op <= "000";
                jump <= '0';
                pc_src <= '0';
            when "001011" => --subui
                reg_dst <= '1';
                alu_src <= '1';
                mem_to_reg <= '0';
                reg_write <= '1';
                mem_read <= '0';
                mem_write <= '0';
                alu_op <= "010";
                jump <= '0';
                pc_src <= '0';
            when "000100" => -- beq
                reg_dst <= '0';
                alu_src <= '1';
                mem_to_reg <= '0';
                reg_write <= '0';
                mem_read <= '0';
                mem_write <= '0';
                alu_op <= "010";
                jump <= '0';
                branch <= '1';
                pc_src <= '1';
            when "100011" => -- lw
                reg_dst <= '0';
                alu_src <= '1';
                mem_to_reg <= '1';
                reg_write <= '1';
                mem_read <= '1';
                mem_write <= '0';
                alu_op <= "001";
                jump <= '0';
                pc_src <= '0';
            when "101000" => -- sb
                reg_dst <= '0';
                alu_src <= '1';
                mem_to_reg <= '0';
                reg_write <= '0';
                mem_read <= '0';
                mem_write <= '1';
                alu_op <= "001";
                jump <= '0';
                pc_src <= '0';
            when "000010" => -- j
                reg_dst <= '0';
                alu_src <= '0';
                mem_to_reg <= '0';
                reg_write <= '0';
                mem_read <= '0';
                mem_write <= '0';
                alu_op <= "111";
                jump <= '1';
                pc_src <= '1';
            when others => -- invalid
                reg_dst <= '0';
                alu_src <= '0';
                mem_to_reg <= '0';
                reg_write <= '0';
                mem_read <= '0';
                mem_write <= '0';
                alu_op <= "111";
                jump <= '0';
                pc_src <= '0';
        end case;
        end if;
    end process;
end control;
