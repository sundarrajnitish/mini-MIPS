------------------------------------------------------------------------------
-- tb_alu : unit test for the ALU. 20 000 random vectors per operation plus
-- corner cases, checked against an independent reference written with
-- numeric_std arithmetic in the testbench.
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.mips_pkg.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is
  signal op     : alu_op_t := ALU_ADD;
  signal a, b   : word_t := ZERO_WORD;
  signal shamt  : std_logic_vector(4 downto 0) := (others => '0');
  signal result : word_t;
  signal zero   : std_logic;

  function ref(xop : alu_op_t; xa, xb : word_t; sh : std_logic_vector) return word_t is
    variable ua : unsigned(31 downto 0) := unsigned(xa);
    variable ub : unsigned(31 downto 0) := unsigned(xb);
  begin
    case xop is
      when ALU_ADD => return std_logic_vector(ua + ub);
      when ALU_SUB => return std_logic_vector(ua + (not ub) + 1);   -- two's complement form
      when ALU_AND => return xa and xb;
      when ALU_XOR => return xa xor xb;
      when ALU_NOR => return not (xa or xb);
      when ALU_SLL => return std_logic_vector(ub sll to_integer(unsigned(sh)));
      when others  => return ZERO_WORD;
    end case;
  end function;
begin
  dut : entity work.alu port map (op => op, a => a, b => b, shamt => shamt, result => result, zero => zero);

  process
    type ops_t is array (natural range <>) of alu_op_t;
    constant OPS : ops_t := (ALU_ADD, ALU_AND, ALU_XOR, ALU_NOR, ALU_SLL, ALU_SUB);
    type corner_t is array (natural range <>) of word_t;
    constant CORNERS : corner_t := (x"00000000", x"00000001", x"7FFFFFFF", x"80000000", x"FFFFFFFF", x"AAAAAAAA");
    variable s1, s2 : positive := 42;
    variable r      : real;
    variable errors, checks : natural := 0;
    impure function rnd32 return word_t is
      variable v : word_t;
    begin
      for i in 0 to 3 loop
        uniform(s1, s2, r);
        v(8 * i + 7 downto 8 * i) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
      end loop;
      return v;
    end function;
    procedure check is
      variable e : word_t;
    begin
      wait for 1 ns;
      e := ref(op, a, b, shamt);
      checks := checks + 1;
      if result /= e or (zero = '1') /= (e = ZERO_WORD) then
        errors := errors + 1;
        report "ALU mismatch op=" & to_string(op) & " a=" & to_hstring(a) & " b=" & to_hstring(b)
          & " got=" & to_hstring(result) & " exp=" & to_hstring(e) severity error;
      end if;
    end procedure;
  begin
    for k in OPS'range loop
      op <= OPS(k);
      for i in CORNERS'range loop
        for j in CORNERS'range loop
          a <= CORNERS(i); b <= CORNERS(j); shamt <= std_logic_vector(to_unsigned((i * 7 + j) mod 32, 5));
          check;
        end loop;
      end loop;
      for n in 1 to 20000 loop
        a <= rnd32; b <= rnd32;
        uniform(s1, s2, r); shamt <= std_logic_vector(to_unsigned(integer(floor(r * 32.0)), 5));
        check;
      end loop;
    end loop;
    if errors = 0 then
      report "TB_RESULT PASS alu checks=" & integer'image(checks);
    else
      report "TB_RESULT FAIL alu errors=" & integer'image(errors) severity error;
    end if;
    wait;
  end process;
end architecture sim;
