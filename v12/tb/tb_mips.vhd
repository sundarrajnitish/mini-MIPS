------------------------------------------------------------------------------
-- tb_mips : self-checking system testbench for mini-MIPS
--
--  1. loads IMEM_FILE / DMEM_FILE into the CPU, releases reset
--  2. writes one CSV line per clock cycle to TRACE_FILE (pipeline occupancy,
--     hazard/forwarding decisions, write-back and store events)
--  3. stops 3 cycles after a "halt" (j .) reaches ID -- enough for every
--     older instruction to complete write-back
--  4. compares all 32 registers and the whole data memory against
--     EXPECT_FILE (produced by the golden ISS, sw/mips_iss.py) and reports
--     "TB_RESULT PASS" or "TB_RESULT FAIL"
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.mips_pkg.all;

entity tb_mips is
  generic (
    IMEM_FILE   : string  := "";
    DMEM_FILE   : string  := "";
    EXPECT_FILE : string  := "";
    TRACE_FILE  : string  := "trace.csv";
    MAX_CYCLES  : natural := 5000
  );
end entity tb_mips;

architecture sim of tb_mips is
  constant T_CLK : time := 10 ns;
  signal clk  : std_logic := '0';
  signal rst  : std_logic := '1';
  signal dbg  : debug_t;
  signal done : boolean := false;

  function hex(v : std_logic_vector) return string is
  begin
    return to_hstring(v);
  end function;
  function b(s : std_logic) return string is
  begin
    if s = '1' then return "1"; else return "0"; end if;
  end function;
begin

  dut : entity work.mips_cpu
    generic map (IMEM_FILE => IMEM_FILE, DMEM_FILE => DMEM_FILE)
    port map (clk => clk, rst => rst, dbg => dbg);

  clk <= not clk after T_CLK / 2 when not done;

  stimulus : process
    alias regs is << signal .tb_mips.dut.u_rf.regs : reg_array_t >>;
    alias ram  is << signal .tb_mips.dut.u_dmem.ram : word_array_t(0 to 1023) >>;

    file     tf     : text;
    file     ef     : text;
    variable l      : line;
    variable cycle  : natural := 0;
    variable drain  : integer := -1;
    variable halt_c : integer := -1;
    variable status : file_open_status;
    variable kind   : character;
    variable idx    : integer;
    variable w      : word_t;
    variable errors : natural := 0;
    variable exp_m  : word_array_t(0 to 1023) := (others => ZERO_WORD);
    variable n_instr: integer := -1;
  begin
    file_open(tf, TRACE_FILE, write_mode);
    write(l, string'("cycle,pc,ifid_v,ifid_pc,ifid_instr,idex_v,idex_pc,exmem_v,exmem_pc,memwb_v,memwb_pc," &
                     "stall,flush,pc_sel,next_pc,fwd_a,fwd_b,fwd_e,fwd_f,alu,wb_en,wb_rd,wb_data,mem_we,mem_addr,mem_wdata"));
    writeline(tf, l);

    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';

    loop
      wait until falling_edge(clk);          -- all combinational values settled
      cycle := cycle + 1;
      write(l, integer'image(cycle) & "," & hex(dbg.pc_if) & "," &
               b(dbg.if_id.valid) & "," & hex(dbg.if_id.pc) & "," & hex(dbg.if_id.instr) & "," &
               b(dbg.id_ex_v) & "," & hex(dbg.id_ex_pc) & "," &
               b(dbg.ex_mem_v) & "," & hex(dbg.ex_mem_pc) & "," &
               b(dbg.mem_wb_v) & "," & hex(dbg.mem_wb_pc) & "," &
               b(dbg.stall) & "," & b(dbg.if_flush) & "," & hex(dbg.pc_sel) & "," & hex(dbg.next_pc) & "," &
               hex(dbg.fwd_a) & "," & hex(dbg.fwd_b) & "," & b(dbg.fwd_e) & "," & b(dbg.fwd_f) & "," &
               hex(dbg.alu_result) & "," &
               b(dbg.wb_en) & "," & integer'image(to_integer(unsigned(dbg.wb_rd))) & "," & hex(dbg.wb_data) & "," &
               b(dbg.mem_we) & "," & hex(dbg.mem_addr) & "," & hex(dbg.mem_wdata));
      writeline(tf, l);

      if dbg.halted = '1' and drain < 0 then
        halt_c := cycle;
        drain  := 3;
      end if;
      if drain = 0 or cycle >= MAX_CYCLES then
        exit;
      end if;
      if drain > 0 then
        drain := drain - 1;
      end if;
    end loop;
    wait until rising_edge(clk);            -- let the final write-back land
    wait for 1 ns;
    file_close(tf);

    if halt_c < 0 then
      report "TB_RESULT FAIL : no halt within " & integer'image(MAX_CYCLES) & " cycles" severity error;
      errors := errors + 1;
    end if;

    -- compare against the golden model
    if EXPECT_FILE'length > 0 then
      file_open(status, ef, EXPECT_FILE, read_mode);
      assert status = open_ok report "cannot open " & EXPECT_FILE severity failure;
      while not endfile(ef) loop
        readline(ef, l);
        next when l'length = 0;
        read(l, kind);
        read(l, idx);
        if kind = 'R' then
          hread(l, w);
          if regs(idx) /= w then
            report "MISMATCH $" & integer'image(idx) & " rtl=" & hex(regs(idx)) & " expected=" & hex(w)
              severity error;
            errors := errors + 1;
          end if;
        elsif kind = 'M' then
          hread(l, w);
          exp_m(idx) := w;
        elsif kind = 'I' then
          n_instr := idx;
        end if;
      end loop;
      file_close(ef);
      for i in 0 to 1023 loop
        if ram(i) /= exp_m(i) then
          report "MISMATCH mem[" & integer'image(4 * i) & "] rtl=" & hex(ram(i)) & " expected=" & hex(exp_m(i))
            severity error;
          errors := errors + 1;
        end if;
      end loop;
    end if;

    if errors = 0 then
      report "TB_RESULT PASS cycles=" & integer'image(halt_c + 3) & " instructions=" & integer'image(n_instr);
    else
      report "TB_RESULT FAIL errors=" & integer'image(errors) severity error;
    end if;
    done <= true;
    wait;
  end process;

end architecture sim;
