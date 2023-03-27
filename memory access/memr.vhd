library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_access_stage is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        mem_en  : in  std_logic;
        mem_rw  : in  std_logic;
        mem_addr: in  std_logic_vector(31 downto 0);
        mem_data_in : in  std_logic_vector(31 downto 0);
        mem_data_out: out std_logic_vector(31 downto 0)
    );
end entity;

architecture Behavioral of mem_access_stage is
    type mem_array is array (0 to 4095) of std_logic_vector(31 downto 0);
    signal memory: mem_array := (others => (others => '0'));
begin
    process (clk, rst)
    begin
        if rst = '1' then
            mem_data_out <= (others => '0');
        elsif rising_edge(clk) then
            if mem_en = '1' then
                if mem_rw = '1' then
                    -- Load Word (LW)
                    mem_data_out <= memory(to_integer(unsigned(mem_addr(31 downto 2))))(31 downto 0);
                else
                    -- Store Byte (SB)
                    memory(to_integer(unsigned(mem_addr(31 downto 2))))(7 downto 0) <= mem_data_in(7 downto 0);
                end if;
            end if;
        end if;
    end process;
end architecture;

