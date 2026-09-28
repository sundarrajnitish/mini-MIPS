------------------------------------------------------------------------------
-- Data Memory: DEPTH x 32-bit words (default 1024 words = 4 KiB), byte
-- addressed, little-endian.
--   LW : read_data = word at addr[AW+1:2] (asynchronous read, low 2 address
--        bits ignored -> word-aligned access)
--   SB : on the rising edge, byte lane addr[1:0] of that word <= wdata[7:0]
-- Optional INIT_FILE: one 32-bit hex word per line, starting at address 0.
-- Addresses wrap modulo the memory size.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use work.mips_pkg.all;

entity data_memory is
  generic (
    DEPTH     : positive := 1024;
    INIT_FILE : string   := ""
  );
  port (
    clk        : in  std_logic;
    mem_write  : in  std_logic;   -- SB
    addr       : in  word_t;
    wdata      : in  word_t;
    read_data  : out word_t
  );
end entity data_memory;

architecture rtl of data_memory is
  subtype ram_t is word_array_t(0 to DEPTH - 1);
  constant AW : natural := natural(ceil(log2(real(DEPTH))));

  impure function load_ram(fname : string) return ram_t is
    file     f      : text;
    variable status : file_open_status;
    variable l      : line;
    variable w      : word_t;
    variable ok     : boolean;
    variable i      : natural := 0;
    variable ram    : ram_t := (others => ZERO_WORD);
  begin
    if fname'length = 0 then
      return ram;
    end if;
    file_open(status, f, fname, read_mode);
    if status /= open_ok then
      report "data_memory: cannot open " & fname & " (RAM left zeroed)"
        severity warning;
      return ram;
    end if;
    while not endfile(f) and i < DEPTH loop
      readline(f, l);
      if l'length >= 8 and l(l'low) /= '/' and l(l'low) /= '#' then
        hread(l, w, ok);
        if ok then
          ram(i) := w;
          i := i + 1;
        end if;
      end if;
    end loop;
    file_close(f);
    return ram;
  end function;

  signal ram  : ram_t := load_ram(INIT_FILE);
  signal widx : natural range 0 to DEPTH - 1;
begin
  widx <= to_integer(unsigned(addr(AW + 1 downto 2))) mod DEPTH;

  process (clk)
    variable lane : natural range 0 to 3;
  begin
    if rising_edge(clk) then
      if mem_write = '1' then
        lane := to_integer(unsigned(addr(1 downto 0)));
        ram(widx)(8 * lane + 7 downto 8 * lane) <= wdata(7 downto 0);
      end if;
    end if;
  end process;

  read_data <= ram(widx);
end architecture rtl;
