------------------------------------------------------------------------------
-- Instruction Memory: word-addressed ROM with asynchronous read.
--   * DEPTH words (default 256 words = 1 KiB); address bits [log2(DEPTH)+1:2]
--   * Contents are loaded at elaboration time from INIT_FILE: one 32-bit hex
--     word per line (anything after the first token is ignored, so the
--     assembler can append "// disassembly" comments).
--   * Unused locations read as 0x00000000 = SLL $0,$0,0 = NOP.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use work.mips_pkg.all;

entity instruction_memory is
  generic (
    DEPTH     : positive := 256;
    INIT_FILE : string   := "program.hex"
  );
  port (
    addr  : in  word_t;
    instr : out word_t
  );
end entity instruction_memory;

architecture rtl of instruction_memory is
  subtype rom_t is word_array_t(0 to DEPTH - 1);

  impure function load_rom(fname : string) return rom_t is
    file     f      : text;
    variable status : file_open_status;
    variable l      : line;
    variable w      : word_t;
    variable ok     : boolean;
    variable i      : natural := 0;
    variable rom    : rom_t := (others => ZERO_WORD);
  begin
    if fname'length = 0 then
      return rom;
    end if;
    file_open(status, f, fname, read_mode);
    if status /= open_ok then
      report "instruction_memory: cannot open " & fname & " (ROM left empty)"
        severity warning;
      return rom;
    end if;
    while not endfile(f) and i < DEPTH loop
      readline(f, l);
      if l'length >= 8 and l(l'low) /= '/' and l(l'low) /= '#' then
        hread(l, w, ok);
        if ok then
          rom(i) := w;
          i := i + 1;
        end if;
      end if;
    end loop;
    file_close(f);
    return rom;
  end function;

  constant ROM : rom_t := load_rom(INIT_FILE);
  constant AW  : natural := natural(ceil(log2(real(DEPTH))));
begin
  instr <= ROM(to_integer(unsigned(addr(AW + 1 downto 2))) mod DEPTH);
end architecture rtl;
