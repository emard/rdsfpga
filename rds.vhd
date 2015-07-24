-- RDS and DBPSK modulation
-- (c) Davor Jadrijevic
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.message.all; -- RDS message in file message.vhd

entity rds is
generic (
    C_external_strobe: boolean := false; -- external 1.864 MHz strobe (doesn't work)
    C_stereo: boolean := false; -- true: generate 19kHz pilot wave
    -- true: spend more LUTs to use 32-point sinewave and multiply 
    -- false: save LUTs, use 4-point multiplexer, no multiply
    C_fine_subc: boolean := false
);
port (
    clk_25m: in std_logic;
    pcm_in: in signed(15 downto 0); -- from tone generator
    pcm_out: out signed(15 downto 0); -- to FM transmitter
    tone_out: out std_logic
);
end rds;

architecture RTL of rds is
    -- RDS related registers
    -- get length of RDS message (file message.vhd)
    constant C_rds_msg_len: integer := rds_msg_map'length;

    -- DBPSK waveform is used to modulate RDS at 1187.5 Hz
    -- and to generate sine wave for 57kHz subcarrier
    -- 48 elements of 7 bits (range 1..127) in lookup table 
    -- provide sufficient resolution for time and amplitude
    constant C_dbpsk_bits: integer := 8;

    -- DBPSK lookup table
    type dbpsk_wav_type is array(0 to 47) of std_logic_vector(7 downto 0);
    constant dbpsk_wav_map: dbpsk_wav_type := (
x"47",x"53",x"5e",x"67",x"6e",x"73",x"75",x"75",x"73",x"6f",x"6a",x"66",x"61",x"5e",x"5c",x"5c",
x"5e",x"62",x"67",x"6d",x"73",x"79",x"7d",x"7f",x"7f",x"7d",x"78",x"71",x"68",x"5e",x"52",x"46",
x"3a",x"2e",x"22",x"18",x"0f",x"08",x"03",x"01",x"01",x"03",x"08",x"0f",x"18",x"22",x"2e",x"3a"
    );
    signal R_rds_cdiv: std_logic_vector(5 downto 0); -- 6-bit divisor 0..47
    signal R_rds_pcm: signed(7 downto 0); -- 8 bit ADC value for RDS waveform
    signal R_rds_msg_index: std_logic_vector(15 downto 0); -- 16 bit index for message
    signal R_rds_byte: std_logic_vector(7 downto 0); -- current byte to send
    signal R_rds_bit_index: std_logic_vector(2 downto 0); -- current bit index 0..7
    signal R_rds_bit: std_logic; -- current bit to send
    signal R_rds_phase: std_logic; -- current phase 0:(+) 1:(-)
    signal R_rds_counter: std_logic_vector(4 downto 0); -- 5-bit wav counter 0..31
    signal S_rds_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    signal S_dbpsk_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    signal S_dbpsk_wav_value: signed(7 downto 0);
    signal S_rds_pcm: signed(7 downto 0); -- 8 bit ADC value for RDS waveform
    signal S_rds_mod_pcm: signed(15 downto 0);
    signal S_rds_coarse_pcm: signed(7 downto 0);

    signal R_pilot_counter: std_logic_vector(4 downto 0) := (others => '0'); -- 5-bit wav counter 0..31
    signal R_pilot_cdiv: std_logic_vector(1 downto 0); -- 2-bit divisor 0..2
    signal S_pilot_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    signal S_pilot_wav_value: signed(7 downto 0);
    signal S_pilot_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    signal S_pilot_pcm: signed(7 downto 0) := (others => '0'); -- 8 bit ADC value

    signal R_subc_counter: std_logic_vector(4 downto 0) := (others => '0'); -- 5-bit wav counter 0..31
    signal R_subc_cdiv: std_logic_vector(4 downto 0) := (others => '0'); -- divide to 57kHz
    signal S_subc_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    signal S_subc_wav_value: signed(7 downto 0);
    signal S_subc_pcm: signed(7 downto 0); -- 8 bit ADC value for 19kHz pilot sine wave

    signal S_strobe_1M824: std_logic;
    
    constant C_clkdiv_bits: integer := 20; -- enough for 1M counts
    signal R_rds_t_ps: std_logic_vector(C_clkdiv_bits-1 downto 0); -- RDS timer in picoseconds (20 bit max range 1e6 ps)
    constant C_rds_clock_in_period: std_logic_vector(C_clkdiv_bits-1 downto 0) := 40000; -- 40 ns = 40000 ps = 25 MHz
    -- constant C_rds_clock_in_period: std_logic_vector(C_clkdiv_bits-1 downto 0) := 400; -- 100x slower for audible debug
    constant C_rds_clock_out_period: std_logic_vector(C_clkdiv_bits-1 downto 0) := 548246; -- 548245.6 ps = 1.824 MHz -> 57 kHz
    signal R_rds_strobe: std_logic; -- 1.824 MHz strobe signal
begin
    -- generate 1.824 MHz RDS strobe
    -- RDS needs 57 kHz carrier wave.
    -- lookup table period length is 32 entries
    -- so we need strobe frequency of 32*57 kHz = 1.824 MHz
    -- or period of 548245.6 ps
    -- change state on falling edge, so strobe level is
    -- stable when compared at rising edge
    internal_strobe: if not C_external_strobe generate
    process(clk_25m)
    begin
      if falling_edge(clk_25m) then
        if R_rds_t_ps < C_rds_clock_out_period  then
          -- add 40ns (1/25MHz)
          R_rds_t_ps <= R_rds_t_ps + C_rds_clock_in_period;
          R_rds_strobe <= '0';
        else
          -- add 40ns (1/25MHz) as always and step back one out-period
          R_rds_t_ps <= R_rds_t_ps + C_rds_clock_in_period - C_rds_clock_out_period;
          R_rds_strobe <= '1';
        end if;
      end if;
    end process;
    end generate;
    
    external_strobe: if C_external_strobe generate
    -- strange, why this doesn't work?
    -- it creates the same frequency, but if
    -- R_rds_strobe is replaced with this external strube
    -- and passed to RDS modulator 
    -- then RDS text is not received
    clk1M824: entity work.strobe
    generic map(
      clk_in_hz => 3125,   -- Hz (25 MHz)
      strobe_out_hz => 228 -- Hz (1.824 MHz)
    )
    port map(
      clk_in => clk_25m,
      strobe_out => R_rds_strobe
    );
    end generate;

    -- ****************** PILOT 19kHz (only for stereo, not used for mono) *******************
    generate_pilot_19kHz: if C_stereo generate
    process(clk_25m)
    begin
        if rising_edge(clk_25m) then
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
	        -- pilot 57/3 = 19 kHz generation
	        if R_pilot_cdiv = 0 then
	          R_pilot_cdiv <= 2;
	          R_pilot_counter <= R_pilot_counter + 1;
	        else
	          R_pilot_cdiv <= R_pilot_cdiv - 1;
	        end if;
	    end if;
	end if;
    end process;
    S_pilot_wav_index <= "10"                         -- or 32 (sine)
                      &  R_pilot_counter(3 downto 0); -- 0..15 running
    -- dbpsk_wav_map has range 1..127, need to subtract 64
    -- phase warning: negative sine values at index 32..47
    -- pilot should be in phase with 57kHz subcarrier
    -- (rising slope cross 0 at the same point)
    S_pilot_wav_value <= signed(dbpsk_wav_map(conv_integer(S_pilot_wav_index)) - x"40");
    S_pilot_pcm <= S_pilot_wav_value when R_pilot_counter(4) = '1'
             else -S_pilot_wav_value;
    -- S_pilot_pcm range: (-63 .. +63)
    end generate;
    -- ****************** END PILOT 19kHz ***************************

    -- ****************** SUBCARRIER 57kHz **************************
    fine_subcarrier_sine: if C_fine_subc generate
    process(clk_25m)
    begin
        if rising_edge(clk_25m) then
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
              -- 57 kHz subcarrier generation
              -- using counter 0..31
              R_subc_counter <= R_subc_counter + 1;
	    end if;
	end if;
    end process;
    S_subc_wav_index <= "10"                         -- or 32 (sine)
                      &  R_subc_counter(3 downto 0); -- 0..15 running
    -- dbpsk_wav_map has range 1..127, need to subtract 64
    -- phase warning: negative sine values at index 32..47
    S_subc_wav_value <= signed(dbpsk_wav_map(conv_integer(S_subc_wav_index)) - x"40");
    S_subc_pcm <= S_subc_wav_value when R_subc_counter(4) = '1'
           else  -S_subc_wav_value;
    -- S_subc_pcm range: (-63 .. +63)
    end generate;
    -- ****************** END SUBCARRIER 57kHz **********************

    -- *********** RDS MODULATOR 57 kHz / 1187.5 Hz *****************
    process(clk_25m)
    begin
        if rising_edge(clk_25m) then
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
	      -- divides by 32 to get 57 kHz subcarrier
	      R_subc_cdiv <= R_subc_cdiv + 1;
	      -- 0-47: divide by 48 to get 1187.5 Hz from 32-element lookup table
              if R_rds_cdiv = 0 then
                R_rds_cdiv <= 47; -- countdown from 47 to 0
	        -- RDS works on 1187.5 bit rate
	        -- 57KHz subcarrier should be AM modulated using RDS
	        -- adjust modulation to obtain
	        -- +-2kHz FM width on the main carrier
                R_rds_counter <= R_rds_counter + 1; -- increment counter 0..31
                if R_rds_counter = 31 then
                  -- fetch new bit
                  -- R_rds_bit <= rds_msg_map(conv_integer(R_rds_msg_index))(conv_integer(R_rds_bit_index));
                  -- R_rds_bit <= not(R_rds_bit);
                  -- R_rds_bit <= '0'; -- test: bit 0 should output 1187.5 kHz
                  -- change phase if bit was 1
                  R_rds_phase <= R_rds_phase xor R_rds_bit; -- change the phase
                  -- take next bit. Send bits from bit 7 downto bit 0
                  R_rds_bit_index <= R_rds_bit_index - 1;
                  if R_rds_bit_index = 0 then
                     -- when bit index is at LSB bit pos 0
                     -- for next clock cycle prepare next byte
                     -- (byte sending start at MSB bit pos 7)
                     R_rds_msg_index <= R_rds_msg_index + 1;
                     if R_rds_msg_index >= (C_rds_msg_len-1) then
                       R_rds_msg_index <= 0;
                     end if;
                  end if;
                  R_rds_bit <= rds_msg_map(conv_integer(R_rds_msg_index))(conv_integer(R_rds_bit_index));
                end if;
              else
                R_rds_cdiv <= R_rds_cdiv - 1; -- countdown from 47 to 0
              end if;
	    end if;
	end if;
    end process;
    -- rds bit 0: continuous sine wave
    -- use lookup table values 32..47
    -- index = (counter and 15) or 32
    -- rds bit 1: phase changing sine wave
    -- use lookup table values 0..31
    -- index = counter and 31
    S_rds_sign <= R_rds_phase when R_rds_bit='1'
             else not(R_rds_counter(4) xor R_rds_phase);
    S_dbpsk_wav_index <= (not(R_rds_bit))                 -- 32 (sine)
                       & (R_rds_counter(4) and R_rds_bit) -- 0..15 (sine) or 0..31 (phase change)
                       &  R_rds_counter(3 downto 0);      -- 0..15 same for both
    S_dbpsk_wav_value <= signed(dbpsk_wav_map(conv_integer(S_dbpsk_wav_index)) - x"40");

    -- AM modulation of subcarrier with DBPSK wave
    -- do not overmodulate RDS signal
    -- signed value is passed to fmgen modulator
    -- transmits value*2Hz carrier frequency shift
    -- modulated range of cca -4000 ... +4000 works

    fine_subcarrier: if C_fine_subc generate
    S_rds_pcm <= S_dbpsk_wav_value when S_rds_sign = '1'
           else -S_dbpsk_wav_value;
    -- S_rds_pcm range: (-63 .. +63)
    S_rds_mod_pcm <= S_subc_pcm * S_rds_pcm;
    -- S_rds_mod_pcm range: 63*63 = (-3969 .. +3969)
    end generate;

    -- simple 57kHz mixer with multiplexer
    -- using 4 points coarse sampled subcarrier at 228 kHz
    -- no multiplication needed
    coarse_subcarrier: if not C_fine_subc generate
    -- sign manipulation with the multiplexer
    -- avoids calculating double minus
    with S_rds_sign & R_subc_cdiv(4 downto 3) select
    S_rds_coarse_pcm <= S_dbpsk_wav_value when "101" | "011",
                       -S_dbpsk_wav_value when "111" | "001",
                        0         when others;
    S_rds_mod_pcm <= S_rds_coarse_pcm * 64; -- signed multiply by 64
    -- 64 or 63 is the same from amplitude point of view
    -- 64 is more simple as it uses only bit shifting
    -- S_rds_mod_pcm range: 63*64 = (-4032 .. +4032)
    end generate;
    -- ****************** END RDS MODULATOR **************

    -- mixing input audio with RDS DBPSK
    mix_no_pilot:  if not C_stereo generate
    pcm_out <= pcm_in + S_rds_mod_pcm;
    end generate;

    mix_pilot:  if C_stereo generate
    pcm_out <= pcm_in + S_pilot_pcm + S_rds_mod_pcm;
    end generate;
end;
