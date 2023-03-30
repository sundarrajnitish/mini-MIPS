library IEEE;
use IEEE.std_logic_1164.all;

entity test_write_back_stage is
end test_write_back_stage;

architecture behavioral of test_write_back_stage is
    component write_back_stage
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            mem_to_reg  : in  std_logic;
            reg_write   : in  std_logic;
            reg_dest    : in  std_logic_vector(4 downto 0);
            alu_result  : in  std_logic_vector(31 downto 0);
            mem_result  : in  std_logic_vector(31 downto 0);
            reg_out     : out std_logic_vector(31 downto 0) := (others => '0')
        );
    end component;
    
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal mem_to_reg  : std_logic := '0';
    signal reg_write   : std_logic := '0';
    signal reg_dest    : std_logic_vector(4 downto 0) := (others => '0');
    signal alu_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_out     : std_logic_vector(31 downto 0) := (others => '0');
    
begin
    uut : write_back_stage
        port map (
            clk         => clk,
            rst         => rst,
            mem_to_reg  => mem_to_reg,
            reg_write   => reg_write,
            reg_dest    => reg_dest,
            alu_result  => alu_result,
            mem_result  => mem_result,
            reg_out     => reg_out
        );
        
    process
    begin
        
        rst <= '1';
        wait for 10 ns;
        assert reg_out = (31 downto 0 => '0') report "F1" severity error;
        
       
        rst <= '0';
        reg_write <= '0';
        wait for 10 ns;
        assert reg_out = (31 downto 0 => '0') report "F2" severity error;
        
       
        reg_write <= '1';
        mem_to_reg <= '0';
        alu_result <= x"00000001"; 
        wait for 10 ns;
        assert reg_out = x"00000001" report "F3" severity error;
        
       
        mem_to_reg <= '1';
        mem_result <= x"00000002"; 
        wait for 10 ns;
        assert reg_out = x"00000002" report "F4" severity error;
        
        wait;
    end process;
end behavioral;