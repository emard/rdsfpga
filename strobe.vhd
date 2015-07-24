-- Strobe generator of arbitrary frequency
-- (c) Davor Jadrijevic
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.rds_pack.all;

entity strobe is
generic (
    clk_in_hz: integer := 25000000;  -- Hz in system clock input frequency
    clk_out_hz: integer              -- Hz out strobe output frequency
);
port (
    clk_in: in std_logic; -- input clock
    strobe_out: out std_logic  -- otput strobe
);
end strobe;

architecture RTL of strobe is
    -- bit: number of bits that can represent input clock freq
    constant bit: integer := integer(floor((log2(real(clk_in_hz)))+1.0E-16));
    constant c_add_clk_out: std_logic_vector(bit downto 0) := std_logic_vector(conv_unsigned(clk_out_hz, bit+1));
    constant c_sub_clk_in: std_logic_vector(bit downto 0) := std_logic_vector(conv_unsigned(clk_in_hz, bit+1));
    signal d, dinc: std_logic_vector(bit downto 0); -- clock divider and increment
    signal R_strobe: std_logic;
begin
    dinc <= c_add_clk_out when d(bit) = '0'
       else c_add_clk_out - c_sub_clk_in;
    -- generate strobe
    -- change state on falling edge.
    -- strobe level will be
    -- stable when compared at rising edge
    process(clk_in)
    begin
      if falling_edge(clk_in) then
        d <= d + dinc;
      end if;
    end process;
    strobe_out <= d(bit);
end;
