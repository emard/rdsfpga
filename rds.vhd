-- RDS and DBPSK modulation
-- (c) Davor Jadrijevic
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity rds is
port (
    clk_25m: in std_logic;
    pcm_in: in signed(15 downto 0); -- from tone generator
    pcm_out: out signed(15 downto 0); -- to FM transmitter
    tone_out: out std_logic
);
end rds;

architecture RTL of rds is
    -- RDS related registers
    -- rds message converted from pic assember to stream of bytes
    -- PS="Radio4", RT="HELLO", PID=0xC000
    type rds_msg_type is array(0 to 259) of std_logic_vector(7 downto 0);
    constant rds_msg_map: rds_msg_type := (
x"c0",x"00",x"9b",x"02",x"03",x"29",x"fc",x"00",x"07",x"01",x"49",x"86",x"a9",
x"c0",x"00",x"9b",x"02",x"02",x"47",x"bc",x"00",x"07",x"01",x"91",x"a7",x"c6",
x"c0",x"00",x"9b",x"02",x"02",x"ab",x"0c",x"00",x"07",x"01",x"bc",x"d3",x"94",
x"c0",x"00",x"9b",x"02",x"02",x"f0",x"9c",x"00",x"07",x"00",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"00",x"23",x"74",x"84",x"50",x"f5",x"31",x"33",x"13",
x"c0",x"00",x"9b",x"08",x"00",x"78",x"e4",x"f2",x"08",x"f4",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"00",x"94",x"52",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"00",x"cf",x"c2",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"01",x"16",x"a2",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"01",x"4d",x"32",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"01",x"a1",x"82",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"01",x"fa",x"12",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"02",x"13",x"42",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"02",x"48",x"d2",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"02",x"a4",x"62",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"02",x"ff",x"f2",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"03",x"26",x"92",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"03",x"7d",x"02",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"03",x"91",x"b2",x"02",x"08",x"e0",x"80",x"80",x"dc",
x"c0",x"00",x"9b",x"08",x"03",x"ca",x"22",x"02",x"08",x"e0",x"80",x"80",x"dc"
    );
    -- testing 1 group of 13 bytes, PID=0x1234
    type urds_msg_type is array(0 to 12) of std_logic_vector(7 downto 0);
    constant urds_msg_map: urds_msg_type := (
x"12",x"34",x"1a",x"89",x"01",x"96",x"82",x"02",x"00",x"00",x"80",x"80",x"dc"
    );
    -- testing 8 bits
    type yrds_msg_type is array(0 to 8) of std_logic_vector(7 downto 0);
    constant yrds_msg_map: yrds_msg_type := (
      x"00", x"01", x"03", x"07", x"0f", x"1f", x"3f", x"7f", x"ff"
    );
    -- testing 8 bits
    type zrds_msg_type is array(0 to 3) of std_logic_vector(7 downto 0);
    constant zrds_msg_map: zrds_msg_type := (
      x"00", x"00", x"01", x"00"
    );
    -- get length of RDS message
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
    signal R_rds_mod_pcm: signed(15 downto 0);
    signal S_rds_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    signal S_dbpsk_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    signal S_dbpsk_wav_value: signed(7 downto 0);
    signal S_rds_pcm: signed(7 downto 0); -- 8 bit ADC value for RDS waveform

    signal R_pilot_counter: std_logic_vector(4 downto 0) := (others => '0'); -- 5-bit wav counter 0..31
    signal R_pilot_cdiv: std_logic_vector(1 downto 0); -- 2-bit divisor 0..2
    signal R_pilot_pcm: signed(7 downto 0); -- 8 bit ADC value

    signal R_subc_counter: std_logic_vector(4 downto 0) := (others => '0'); -- 5-bit wav counter 0..31
    signal R_subc_pcm: signed(7 downto 0); -- 8 bit ADC value for 19kHz pilot sine wave
    signal S_subc_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    signal S_subc_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    signal S_subc_wav_value: signed(7 downto 0);
    signal S_subc_pcm: signed(7 downto 0); -- 8 bit ADC value for 19kHz pilot sine wave
    
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

    -- ****************** PILOT 19kHz (only for stereo, not used for mono) *******************
    process(clk_25m)
    variable V_pilot_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    variable V_pilot_wav_value: signed(7 downto 0);
    variable V_pilot_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    begin
        if rising_edge(clk_25m) then
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
	        -- pilot 57/3 = 19 kHz generation
	        if R_pilot_cdiv = 2 then
	          R_pilot_cdiv <= 0;
	          R_pilot_counter <= R_pilot_counter + 1;
                  V_pilot_sign := R_pilot_counter(4);
                  V_pilot_wav_index := "10"                             -- or 32 (sine)
                                     &  R_pilot_counter(3 downto 0);    -- 0..15 running
                  V_pilot_wav_value := signed(dbpsk_wav_map(conv_integer(V_pilot_wav_index)) - x"40");
                  -- convert from 8-bit wav table to 16-bit R_rds_pcm
                  -- dbpsk_wav_map has range 1..127
                  -- as we have counted up to 2 until
                  -- we get here, phase is changed by 180, related to 57 kHz subc
                  -- so we correct phase comparing V_pilot_sign = 1 
                  if V_pilot_sign = '1' then
                    -- positive wave (y)
                    R_pilot_pcm <= V_pilot_wav_value;
                  else
                    -- negative wave (128 - y) (64 is 0-point)
                    R_pilot_pcm <= -V_pilot_wav_value;
                  end if;
                  -- R_pilot_pcm range (-63 .. +63)
	        else
	          R_pilot_cdiv <= R_pilot_cdiv + 1;  
	        end if;
	    end if;
	end if;
    end process;
    -- ************************** END PILOT 19kHz ******************************

    -- ****************** SUBCARRIER 57kHz *******************
    
    -- S_subc_sign <= R_subc_counter(4);
    S_subc_wav_index <= "10"                         -- or 32 (sine)
                      &  R_subc_counter(3 downto 0); -- 0..15 running
    -- dbpsk_wav_map has range 1..127, need to subtract 64
    -- phase warning: negative sine values at index 32..47
    S_subc_wav_value <= signed(dbpsk_wav_map(conv_integer(S_subc_wav_index)) - x"40");
    S_subc_pcm <= S_subc_wav_value when R_subc_counter(4) = '0'
           else  -S_subc_wav_value;
    -- S_subc_pcm range: (-63 .. +63)

    process(clk_25m)
    begin
        if rising_edge(clk_25m) then
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
	        -- 57 kHz generation
	          R_subc_counter <= R_subc_counter + 1;
                  -- V_subc_sign := R_subc_counter(4);
                  --V_subc_wav_index := "10"                             -- or 32 (sine)
                  --                   &  R_subc_counter(3 downto 0);    -- 0..15 running
                  -- V_subc_wav_value := signed(dbpsk_wav_map(conv_integer(S_subc_wav_index)) - x"40");
                  if S_subc_sign = '0' then
                    -- positive wave
                    R_subc_pcm <= S_subc_wav_value;
                  else
                    -- negative wave
                    R_subc_pcm <= -S_subc_wav_value;
                  end if;
                  -- R_subc_pcm range: (-63 .. +63)
	    end if;
	end if;
    end process;
    -- ************************** END SUBCARRIER 57kHz ******************************

    -- ****************** RDS MODULATOR 1187.5 Hz *******************

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
    S_rds_pcm <= S_dbpsk_wav_value when S_rds_sign = '1'
           else -S_dbpsk_wav_value;
    -- S_rds_pcm range: (-63 .. +63)

    process(clk_25m)
    variable V_dbpsk_wav_index: std_logic_vector(5 downto 0); -- 6-bit index 0..63
    variable V_dbpsk_wav_value: signed(7 downto 0);
    variable V_rds_sign: std_logic; -- current sign of waveform 0:(+) 1:(-)
    begin
        if rising_edge(clk_25m) then
	    -- ************************** RDS ******************************
            -- clocked at 25 MHz
            -- strobed at 1.824 MHz
	    if R_rds_strobe = '1' then
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
                  -- take next bit
                  R_rds_bit_index <= R_rds_bit_index - 1;
                  if R_rds_bit_index = 0 then
                     -- take next byte
                     R_rds_msg_index <= R_rds_msg_index + 1;
                     if R_rds_msg_index >= (C_rds_msg_len-1) then
                       R_rds_msg_index <= 0;
                     end if;
                  end if;
                  R_rds_bit <= rds_msg_map(conv_integer(R_rds_msg_index))(conv_integer(R_rds_bit_index));
                end if;
                if R_rds_bit = '0' then
                  -- rds bit 0: continuous sine wave
                  -- use lookup table values 32..47
                  -- index = (counter and 15) or 32
                  V_rds_sign := not(R_rds_counter(4) xor R_rds_phase);
                else
                  -- rds bit 1: phase changing sine wave
                  -- use lookup table values 0..31
                  -- index = counter and 31
                  V_rds_sign := R_rds_phase;
                end if;
                V_dbpsk_wav_index := (not(R_rds_bit))                 -- 32 (sine)
                                   & (R_rds_counter(4) and R_rds_bit) -- 0..15 (sine) or 0..31 (phase change)
                                   &  R_rds_counter(3 downto 0);      -- 0..15 same for both
                V_dbpsk_wav_value := signed(dbpsk_wav_map(conv_integer(V_dbpsk_wav_index)) - x"40");
                -- convert from 8-bit wav table to 16-bit R_rds_pcm
                -- dbpsk_wav_map has range 1..127
                if S_rds_sign = '0' then
                  -- positive wave
                  R_rds_pcm <= V_dbpsk_wav_value;
                else
                  -- negative wave
                  R_rds_pcm <= -V_dbpsk_wav_value;
                end if;
                -- R_rds_pcm range: (-63 .. +63)
              else
                R_rds_cdiv <= R_rds_cdiv - 1; -- countdown from 47 to 0
              end if;
              -- AM modulation of subcarrier with rds dbpsk wave
              R_rds_mod_pcm <= S_subc_pcm * R_rds_pcm;
              -- R_rds_mod_pcm range: 63*63 = (-3969 .. +3969)
              -- take care not to overmodulate RDS signal
	    end if;
	end if;
    end process;
    -- ************************** END RDS MODULATOR 1187.5 Hz ******************************

    pcm_out <= pcm_in + R_rds_mod_pcm;
end;
