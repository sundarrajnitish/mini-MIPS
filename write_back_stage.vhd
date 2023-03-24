library IEEE;
use IEEE.std_logic_1164.all;

entity write_back_stage is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        mem_to_reg  : in  std_logic;
        reg_write   : in  std_logic;
        reg_dest    : in  std_logic_vector(4 downto 0);
        alu_result  : in  std_logic_vector(31 downto 0);
        mem_result  : in  std_logic_vector(31 downto 0);
        reg_out     : out std_logic_vector(31 downto 0)
    );
end write_back_stage;

architecture rtl of write_back_stage is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            reg_out <= (others => '0');
        elsif rising_edge(clk) then
            if reg_write = '1' then
                if mem_to_reg = '1' then
                    reg_out <= mem_result;
                else
                    reg_out <= alu_result;
                end if;
            end if;
        end if;
    end process;
end rtl;
