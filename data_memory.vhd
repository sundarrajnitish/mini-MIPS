------------------------------------------------------
------------------------------------------------------
-- Programmed by Nitish Sundarraj Balaji (40241817)
-- Concordia University, Montreal, Canada
-- COEN 6741 - Computer Architecture and Design - Winter 2023
------------------------------------------------------
------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity data_memory is
    port(
        mem_address: in std_logic_vector(31 downto 0);
        write_data: in std_logic_vector(31 downto 0);

        clk: in std_logic;
        mem_write: in std_logic;
        mem_read: in std_logic;
       -- mem_reg_write: in std_logic; -- has to be in the write back stage

        read_data: out std_logic_vector(31 downto 0)
    );
end data_memory;

architecture behavioral of data_memory is
    signal m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18, m19, m20, m21, m22, m23, m24, m25, m26, m27, m28, m29, m30, m31: std_logic_vector(31 downto 0) := (others => '0');
    begin
    process (mem_address, write_data, clk)
	begin
        if mem_write = '1' and mem_read = '0' then
        case mem_address is
            when "00000000000000000000000000000000" => m0 <= write_data;
            when "00000000000000000000000000000100" => m1 <= write_data;
            when "00000000000000000000000000001000" => m2 <= write_data;
            when "00000000000000000000000000001100" => m3 <= write_data;
            when "00000000000000000000000000010000" => m4 <= write_data;
            when "00000000000000000000000000010100" => m5 <= write_data;
            when "00000000000000000000000000011000" => m6 <= write_data;
            when "00000000000000000000000000011100" => m7 <= write_data;
            when "00000000000000000000000000100000" => m8 <= write_data;
            when "00000000000000000000000000100100" => m9 <= write_data;
            when "00000000000000000000000000101000" => m10 <= write_data;
            when "00000000000000000000000000101100" => m11 <= write_data;
            when "00000000000000000000000000110000" => m12 <= write_data;
            when "00000000000000000000000000110100" => m13 <= write_data;
            when "00000000000000000000000000111000" => m14 <= write_data;
            when "00000000000000000000000000111100" => m15 <= write_data;
            when "00000000000000000000000001000000" => m16 <= write_data;
            when "00000000000000000000000001000100" => m17 <= write_data;
            when "00000000000000000000000001001000" => m18 <= write_data;
            when "00000000000000000000000001001100" => m19 <= write_data;
            when "00000000000000000000000001010000" => m20 <= write_data;
            when "00000000000000000000000001010100" => m21 <= write_data;
            when "00000000000000000000000001011000" => m22 <= write_data;
            when "00000000000000000000000001011100" => m23 <= write_data;
            when "00000000000000000000000001100000" => m24 <= write_data;
            when "00000000000000000000000001100100" => m25 <= write_data;
            when "00000000000000000000000001101000" => m26 <= write_data;
            when "00000000000000000000000001101100" => m27 <= write_data;
            when "00000000000000000000000001110000" => m28 <= write_data;
            when "00000000000000000000000001110100" => m29 <= write_data;
            when "00000000000000000000000001111000" => m30 <= write_data;
            when "00000000000000000000000001111100" => m31 <= write_data;
            when others => null;
        end case;
        elsif mem_read = '1' and mem_write = '0' then
        case mem_address is
            when "00000000000000000000000000000000" => read_data <= m0;
            when "00000000000000000000000000000100" => read_data <= m1;
            when "00000000000000000000000000001000" => read_data <= m2;
            when "00000000000000000000000000001100" => read_data <= m3;
            when "00000000000000000000000000010000" => read_data <= m4;
            when "00000000000000000000000000010100" => read_data <= m5;
            when "00000000000000000000000000011000" => read_data <= m6;
            when "00000000000000000000000000011100" => read_data <= m7;
            when "00000000000000000000000000100000" => read_data <= m8;
            when "00000000000000000000000000100100" => read_data <= m9;
            when "00000000000000000000000000101000" => read_data <= m10;
            when "00000000000000000000000000101100" => read_data <= m11;
            when "00000000000000000000000000110000" => read_data <= m12;
            when "00000000000000000000000000110100" => read_data <= m13;
            when "00000000000000000000000000111000" => read_data <= m14;
            when "00000000000000000000000000111100" => read_data <= m15;
            when "00000000000000000000000001000000" => read_data <= m16;
            when "00000000000000000000000001000100" => read_data <= m17;
            when "00000000000000000000000001001000" => read_data <= m18;
            when "00000000000000000000000001001100" => read_data <= m19;
            when "00000000000000000000000001010000" => read_data <= m20;
            when "00000000000000000000000001010100" => read_data <= m21;
            when "00000000000000000000000001011000" => read_data <= m22;
            when "00000000000000000000000001011100" => read_data <= m23;
            when "00000000000000000000000001100000" => read_data <= m24;
            when "00000000000000000000000001100100" => read_data <= m25;
            when "00000000000000000000000001101000" => read_data <= m26;
            when "00000000000000000000000001101100" => read_data <= m27;
            when "00000000000000000000000001110000" => read_data <= m28;
            when "00000000000000000000000001110100" => read_data <= m29;
            when "00000000000000000000000001111000" => read_data <= m30;
            when "00000000000000000000000001111100" => read_data <= m31;
            when others => null;
            end case;
        end if;
    end process;

    end behavioral;

            
		