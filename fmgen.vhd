library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity fmgen is
generic (
	C_use_pcm_in: boolean := true;
	C_fm_acclen: integer := 28;
	C_fdds: real := 250000000.0 -- input clock frequency
);
port (
        clk_25m: in std_logic;
	clk_250m: in std_logic;
	cw_freq: in std_logic_vector(31 downto 0);
	pcm_in: in signed(15 downto 0);
	fm_out: out std_logic
);
end fmgen;

architecture x of fmgen is
	signal fm_acc, fm_inc: std_logic_vector((C_fm_acclen - 1) downto 0);

	signal R_pcm, R_pcm_avg: signed(15 downto 0);
	signal R_cnt: integer;
	signal R_dds_mul_x1, R_dds_mul_x2: std_logic_vector(31 downto 0);
	constant C_dds_mul_y: std_logic_vector(31 downto 0) :=
	    std_logic_vector(conv_signed(integer(2.0**30 / C_fdds * 2.0**28), 32));
	signal R_dds_mul_res: std_logic_vector(63 downto 0);

begin
    --
    -- Instanciraj PLL blok
    --
    -- I_pll250m: entity pll251m port map (clk => clk_25m, clkop => clk_250m, lock => lock_250m);
    -- clk_250m <= clk_25m;

    --
    -- PWM -> PCM
    --

    R_pcm <= pcm_in;

    -- calculate signal average to remove DC offset
    process(clk_25m)
    variable delta: std_logic_vector(15 downto 0);
    variable R_clk_div: std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk_25m) then
	    R_clk_div := R_clk_div + 1;
	    if R_clk_div = x"0" then
		if (R_pcm - R_pcm_avg) > 0 then
		    R_pcm_avg <= R_pcm_avg + 1;
		-- elsif R_pcm < R_pcm_avg then
		else
		    R_pcm_avg <= R_pcm_avg - 1;
		end if;
	    end if;
        end if;
    end process;

    --
    -- Izracun trenutne frekvencije signala nosioca (frekvencijska modulacija)
    --
    process (clk_25m)
    begin
	if (rising_edge(clk_25m)) then
	    R_dds_mul_x1 <= cw_freq + std_logic_vector(resize((R_pcm-R_pcm_avg) & "0", 32)); -- "0" multiply by 2
	end if;
    end process;
	
    --
    -- Generiranje signala nosioca
    --
    process (clk_250m)
    begin
	if (rising_edge(clk_250m)) then
	    -- Cross clock domains
    	    R_dds_mul_x2 <= R_dds_mul_x1;
	    R_dds_mul_res <= R_dds_mul_x2 * C_dds_mul_y;
	    fm_inc <= R_dds_mul_res(57 downto (58 - C_fm_acclen));
	    fm_acc <= fm_acc + fm_inc;
	end if;
    end process;

    fm_out <= fm_acc((C_fm_acclen - 1));
end;
