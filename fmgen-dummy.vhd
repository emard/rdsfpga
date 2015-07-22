library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity fmgen is
generic (
	C_fm_acclen: integer := 28;
	C_fdds: real := 250000000.0
);
port (
	clk_25m: in std_logic;
	-- cw_freq: in std_logic_vector(31 downto 0);
	pwm_in: in std_logic;
	fm_out: out std_logic
);
end fmgen;

architecture x of fmgen is
	signal fm_acc, fm_inc: std_logic_vector((C_fm_acclen - 1) downto 0);
	signal clk_250m: std_logic;

	signal R_pcm, R_pcm_avg: std_logic_vector(15 downto 0);
	signal R_cnt: integer;
	signal R_pwm_in: std_logic;
	signal R_dds_mul_x1, R_dds_mul_x2: std_logic_vector(31 downto 0);
	constant C_dds_mul_y: std_logic_vector(31 downto 0) :=
	    std_logic_vector(conv_signed(integer(2.0**30 / C_fdds * 2.0**28), 32));
	signal R_dds_mul_res: std_logic_vector(63 downto 0);
	constant cw_freq: std_logic_vector(31 downto 0) := 100000000;

begin
    fm_out <= clk_25m;
end;
