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

entity register_memory is
	port (
        clk: in STD_LOGIC;
        reg_write: in STD_LOGIC;

        --instruction: in STD_LOGIC_VECTOR (31 downto 0);
		read_register_1: in STD_LOGIC_VECTOR (4 downto 0);
        read_register_2: in STD_LOGIC_VECTOR (4 downto 0);
        write_register: in STD_LOGIC_VECTOR (4 downto 0);
        write_data: in STD_LOGIC_VECTOR (31 downto 0);

		read_data_1: out STD_LOGIC_VECTOR (31 downto 0);
        read_data_2: out STD_LOGIC_VECTOR (31 downto 0)
	);
end register_memory;

architecture behavioral of register_memory is
    signal r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31: std_logic_vector(31 downto 0) := (others => '0');
    begin

        process (read_register_1, read_register_2, write_register, write_data)
        begin
            if rising_edge(clk) then
            case read_register_1 is
                when "00000" => --0 -- each address represents a 5-bit value for 32 registers
                    read_data_1 <= r0;
                when "00001" => --1
                    read_data_1 <= r1;
                when "00010" => --2
                    read_data_1 <= r2;
                when "00011" => --3
                     read_data_1 <= r3;
                when "00100" => --4
                    read_data_1 <= r4;
                when "00101" => --5
                    read_data_1 <= r5;
                when "00110" => --6
                    read_data_1 <= r6;
                when "00111" => --7
                    read_data_1 <= r7;
                when "01000" => --8
                    read_data_1 <= r8;
                when "01001" => --9
                    read_data_1 <= r9;
                when "01010" => --10
                    read_data_1 <= r10;
                when "01011" => --11
                    read_data_1 <= r11;
                when "01100" => --12
                    read_data_1 <= r12;
                when "01101" => --13
                    read_data_1 <= r13;
                when "01110" => --14
                    read_data_1 <= r14;
                when "01111" => --15
                    read_data_1 <= r15;
                when "10000" => --16
                    read_data_1 <= r16;
                when "10001" => --17
                    read_data_1 <= r17;
                when "10010" => --18
                    read_data_1 <= r18;
                when "10011" => --19
                    read_data_1 <= r19;
                when "10100" => --20
                    read_data_1 <= r20;
                when "10101" => --21
                    read_data_1 <= r21;
                when "10110" => --22
                    read_data_1 <= r22;
                when "10111" => --23
                    read_data_1 <= r23;
                when "11000" => --24
                    read_data_1 <= r24;
                when "11001" => --25
                    read_data_1 <= r25;
                when "11010" => --26
                    read_data_1 <= r26;
                when "11011" => --27
                    read_data_1 <= r27;
                when "11100" => --28
                    read_data_1 <= r28;
                when "11101" => --29
                    read_data_1 <= r29;
                when "11110" => --30
                    read_data_1 <= r30;
                when "11111" => --31
                    read_data_1 <= r31;
                when others =>
                    read_data_1 <= (others => '0');
            end case;
                case read_register_2 is
                    when "00000" => --0
                        read_data_2 <= r0;
                    when "00001" => --1
                        read_data_2 <= r1;
                    when "00010" => --2
                        read_data_2 <= r2;
                    when "00011" => --3
                        read_data_2 <= r3;
                    when "00100" => --4
                        read_data_2 <= r4;
                    when "00101" => --5
                        read_data_2 <= r5;
                    when "00110" => --6
                        read_data_2 <= r6;
                    when "00111" => --7
                        read_data_2 <= r7;
                    when "01000" => --8
                        read_data_2 <= r8;
                    when "01001" => --9
                        read_data_2 <= r9;
                    when "01010" => --10
                        read_data_2 <= r10;
                    when "01011" => --11
                        read_data_2 <= r11;
                    when "01100" => --12
                        read_data_2 <= r12;
                    when "01101" => --13
                        read_data_2 <= r13;
                    when "01110" => --14
                        read_data_2 <= r14;
                    when "01111" => --15
                        read_data_2 <= r15;
                    when "10000" => --16
                        read_data_2 <= r16;
                    when "10001" => --17
                        read_data_2 <= r17;
                    when "10010" => --18
                        read_data_2 <= r18;
                    when "10011" => --19
                        read_data_2 <= r19;
                    when "10100" => --20
                        read_data_2 <= r20;
                    when "10101" => --21
                        read_data_2 <= r21;
                    when "10110" => --22
                        read_data_2 <= r22;
                    when "10111" => --23
                        read_data_2 <= r23;
                    when "11000" => --24
                        read_data_2 <= r24;
                    when "11001" => --25
                        read_data_2 <= r25;
                    when "11010" => --26
                        read_data_2 <= r26;
                    when "11011" => --27
                        read_data_2 <= r27;
                    when "11100" => --28
                        read_data_2 <= r28;
                    when "11101" => --29
                        read_data_2 <= r29;
                    when "11110" => --30
                        read_data_2 <= r30;
                    when "11111" => --31
                        read_data_2 <= r31;
                    when others =>
                        read_data_2 <= (others => '0');
                end case;
                end if;
                    if rising_edge(clk) and reg_write = '1' then
                        --wait until rising_edge(clk);
                        case write_register is
                            when "00000" => --0
                                r0 <= write_data;
                            when "00001" => --1
                                r1 <= write_data;
                            when "00010" => --2
                                r2 <= write_data;
                            when "00011" => --3
                                r3 <= write_data;
                            when "00100" => --4
                                r4 <= write_data;
                            when "00101" => --5
                                r5 <= write_data;
                            when "00110" => --6
                                r6 <= write_data;
                            when "00111" => --7
                                r7 <= write_data;
                            when "01000" => --8
                                r8 <= write_data;
                            when "01001" => --9
                                r9 <= write_data;
                            when "01010" => --10
                                r10 <= write_data;
                            when "01011" => --11
                                r11 <= write_data;
                            when "01100" => --12
                                r12 <= write_data;
                            when "01101" => --13
                                r13 <= write_data;
                            when "01110" => --14
                                r14 <= write_data;
                            when "01111" => --15
                                r15 <= write_data;
                            when "10000" => --16
                                r16 <= write_data;
                            when "10001" => --17
                                r17 <= write_data;
                            when "10010" => --18
                                r18 <= write_data;
                            when "10011" => --19
                                r19 <= write_data;
                            when "10100" => --20
                                r20 <= write_data;
                            when "10101" => --21
                                r21 <= write_data;
                            when "10110" => --22
                                r22 <= write_data;
                            when "10111" => --23
                                r23 <= write_data;
                            when "11000" => --24
                                r24 <= write_data;
                            when "11001" => --25
                                r25 <= write_data;
                            when "11010" => --26
                                r26 <= write_data;
                            when "11011" => --27
                                r27 <= write_data;
                            when "11100" => --28
                                r28 <= write_data;
                            when "11101" => --29
                                r29 <= write_data;
                            when "11110" => --30
                                r30 <= write_data;
                            when "11111" => --31
                                r31 <= write_data;
                            when others =>
                                null;
                        end case;
                        end if;
    
        end process;
        end behavioral;