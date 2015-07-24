-- Tone with MIDI frequencies
-- (c) Marko Zec
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tonegen is
port (
    clk_25m: in std_logic;
    code: in std_logic_vector(6 downto 0);
    pcm_out: out signed(15 downto 0);
    tone_out: out std_logic -- pwm output
);
end tonegen;

architecture RTL of tonegen is
    type freq_rom_type is array(0 to 127) of std_logic_vector(31 downto 0);
    constant freq_map: freq_rom_type := (
	x"00000000", -- c  0.00 Hz (MIDI #0)
	x"000005d0", -- c# 8.66 Hz (MIDI #1)
	x"00000628", -- d  9.18 Hz (MIDI #2)
	x"00000686", -- d# 9.72 Hz (MIDI #3)
	x"000006e9", -- e  10.30 Hz (MIDI #4)
	x"00000752", -- f  10.91 Hz (MIDI #5)
	x"000007c2", -- f# 11.56 Hz (MIDI #6)
	x"00000838", -- g  12.25 Hz (MIDI #7)
	x"000008b5", -- g# 12.98 Hz (MIDI #8)
	x"0000093a", -- a  13.75 Hz (MIDI #9)
	x"000009c6", -- a# 14.57 Hz (MIDI #10)
	x"00000a5b", -- h  15.43 Hz (MIDI #11)
	x"00000af9", -- c  16.35 Hz (MIDI #12)
	x"00000ba0", -- c# 17.32 Hz (MIDI #13)
	x"00000c51", -- d  18.35 Hz (MIDI #14)
	x"00000d0c", -- d# 19.45 Hz (MIDI #15)
	x"00000dd3", -- e  20.60 Hz (MIDI #16)
	x"00000ea5", -- f  21.83 Hz (MIDI #17)
	x"00000f84", -- f# 23.12 Hz (MIDI #18)
	x"00001071", -- g  24.50 Hz (MIDI #19)
	x"0000116b", -- g# 25.96 Hz (MIDI #20)
	x"00001274", -- a  27.50 Hz (MIDI #21)
	x"0000138d", -- a# 29.14 Hz (MIDI #22)
	x"000014b7", -- h  30.87 Hz (MIDI #23)
	x"000015f2", -- c  32.70 Hz (MIDI #24)
	x"00001740", -- c# 34.65 Hz (MIDI #25)
	x"000018a2", -- d  36.71 Hz (MIDI #26)
	x"00001a19", -- d# 38.89 Hz (MIDI #27)
	x"00001ba6", -- e  41.20 Hz (MIDI #28)
	x"00001d4b", -- f  43.65 Hz (MIDI #29)
	x"00001f09", -- f# 46.25 Hz (MIDI #30)
	x"000020e2", -- g  49.00 Hz (MIDI #31)
	x"000022d6", -- g# 51.91 Hz (MIDI #32)
	x"000024e8", -- a  55.00 Hz (MIDI #33)
	x"0000271a", -- a# 58.27 Hz (MIDI #34)
	x"0000296e", -- h  61.74 Hz (MIDI #35)
	x"00002be4", -- c  65.41 Hz (MIDI #36)
	x"00002e80", -- c# 69.30 Hz (MIDI #37)
	x"00003144", -- d  73.42 Hz (MIDI #38)
	x"00003432", -- d# 77.78 Hz (MIDI #39)
	x"0000374d", -- e  82.41 Hz (MIDI #40)
	x"00003a97", -- f  87.31 Hz (MIDI #41)
	x"00003e13", -- f# 92.50 Hz (MIDI #42)
	x"000041c4", -- g  98.00 Hz (MIDI #43)
	x"000045ad", -- g# 103.83 Hz (MIDI #44)
	x"000049d1", -- a  110.00 Hz (MIDI #45)
	x"00004e35", -- a# 116.54 Hz (MIDI #46)
	x"000052dc", -- h  123.47 Hz (MIDI #47)
	x"000057c9", -- c  130.81 Hz (MIDI #48)
	x"00005d01", -- c# 138.59 Hz (MIDI #49)
	x"00006289", -- d  146.83 Hz (MIDI #50)
	x"00006865", -- d# 155.56 Hz (MIDI #51)
	x"00006e9a", -- e  164.81 Hz (MIDI #52)
	x"0000752e", -- f  174.61 Hz (MIDI #53)
	x"00007c26", -- f# 185.00 Hz (MIDI #54)
	x"00008388", -- g  196.00 Hz (MIDI #55)
	x"00008b5a", -- g# 207.65 Hz (MIDI #56)
	x"000093a3", -- a  220.00 Hz (MIDI #57)
	x"00009c6b", -- a# 233.08 Hz (MIDI #58)
	x"0000a5b8", -- h  246.94 Hz (MIDI #59)
	x"0000af92", -- c  261.63 Hz (MIDI #60)
	x"0000ba03", -- c# 277.18 Hz (MIDI #61)
	x"0000c513", -- d  293.66 Hz (MIDI #62)
	x"0000d0cb", -- d# 311.13 Hz (MIDI #63)
	x"0000dd35", -- e  329.63 Hz (MIDI #64)
	x"0000ea5c", -- f  349.23 Hz (MIDI #65)
	x"0000f84c", -- f# 369.99 Hz (MIDI #66)
	x"00010710", -- g  392.00 Hz (MIDI #67)
	x"000116b4", -- g# 415.30 Hz (MIDI #68)
	x"00012747", -- a  440.00 Hz (MIDI #69)
	x"000138d6", -- a# 466.16 Hz (MIDI #70)
	x"00014b70", -- h  493.88 Hz (MIDI #71)
	x"00015f25", -- c  523.25 Hz (MIDI #72)
	x"00017407", -- c# 554.37 Hz (MIDI #73)
	x"00018a26", -- d  587.33 Hz (MIDI #74)
	x"0001a196", -- d# 622.25 Hz (MIDI #75)
	x"0001ba6b", -- e  659.26 Hz (MIDI #76)
	x"0001d4b9", -- f  698.46 Hz (MIDI #77)
	x"0001f099", -- f# 739.99 Hz (MIDI #78)
	x"00020e20", -- g  783.99 Hz (MIDI #79)
	x"00022d69", -- g# 830.61 Hz (MIDI #80)
	x"00024e8e", -- a  880.00 Hz (MIDI #81)
	x"000271ac", -- a# 932.33 Hz (MIDI #82)
	x"000296e1", -- h  987.77 Hz (MIDI #83)
	x"0002be4b", -- c  1046.50 Hz (MIDI #84)
	x"0002e80e", -- c# 1108.73 Hz (MIDI #85)
	x"0003144c", -- d  1174.66 Hz (MIDI #86) 25e6/(2^32/0x3144c)Hz
	x"0003432c", -- d# 1244.51 Hz (MIDI #87)
	x"000374d6", -- e  1318.51 Hz (MIDI #88)
	x"0003a973", -- f  1396.91 Hz (MIDI #89)
	x"0003e132", -- f# 1479.98 Hz (MIDI #90)
	x"00041c41", -- g  1567.98 Hz (MIDI #91)
	x"00045ad3", -- g# 1661.22 Hz (MIDI #92)
	x"00049d1d", -- a  1760.00 Hz (MIDI #93)
	x"0004e359", -- a# 1864.66 Hz (MIDI #94)
	x"00052dc2", -- h  1975.53 Hz (MIDI #95)
	x"00057c97", -- c  2093.00 Hz (MIDI #96)
	x"0005d01c", -- c# 2217.46 Hz (MIDI #97)
	x"00062899", -- d  2349.32 Hz (MIDI #98)
	x"00068659", -- d# 2489.02 Hz (MIDI #99)
	x"0006e9ac", -- e  2637.02 Hz (MIDI #100)
	x"000752e7", -- f  2793.83 Hz (MIDI #101)
	x"0007c264", -- f# 2959.96 Hz (MIDI #102)
	x"00083882", -- g  3135.96 Hz (MIDI #103)
	x"0008b5a6", -- g# 3322.44 Hz (MIDI #104)
	x"00093a3b", -- a  3520.00 Hz (MIDI #105)
	x"0009c6b2", -- a# 3729.31 Hz (MIDI #106)
	x"000a5b84", -- h  3951.07 Hz (MIDI #107)
	x"000af92e", -- c  4186.01 Hz (MIDI #108)
	x"000ba039", -- c# 4434.92 Hz (MIDI #109)
	x"000c5133", -- d  4698.64 Hz (MIDI #110)
	x"000d0cb3", -- d# 4978.03 Hz (MIDI #111)
	x"000dd359", -- e  5274.04 Hz (MIDI #112)
	x"000ea5cf", -- f  5587.65 Hz (MIDI #113)
	x"000f84c8", -- f# 5919.91 Hz (MIDI #114)
	x"00107104", -- g  6271.93 Hz (MIDI #115)
	x"00116b4c", -- g# 6644.88 Hz (MIDI #116)
	x"00127476", -- a  7040.00 Hz (MIDI #117)
	x"00138d65", -- a# 7458.62 Hz (MIDI #118)
	x"0014b708", -- h  7902.13 Hz (MIDI #119)
	x"0015f25d", -- c  8372.02 Hz (MIDI #120)
	x"00174073", -- c# 8869.84 Hz (MIDI #121)
	x"0018a267", -- d  9397.27 Hz (MIDI #122)
	x"001a1966", -- d# 9956.06 Hz (MIDI #123)
	x"001ba6b2", -- e  10548.08 Hz (MIDI #124)
	x"001d4b9e", -- f  11175.30 Hz (MIDI #125)
	x"001f0991", -- f# 11839.82 Hz (MIDI #126)
	x"0020e209"  -- g  12543.85 Hz (MIDI #127)
    );

    type sin_rom_type is array(0 to 255) of std_logic_vector(15 downto 0);
    constant sin_map: sin_rom_type := (
	x"8000",x"8324",x"8647",x"896a",x"8c8b",x"8fab",x"92c8",x"95e2",
	x"98f8",x"9c0b",x"9f19",x"a223",x"a527",x"a826",x"ab1f",x"ae10",
	x"b0fb",x"b3de",x"b6ba",x"b98c",x"bc56",x"bf17",x"c1ce",x"c47a",
	x"c71c",x"c9b3",x"cc3f",x"cebf",x"d133",x"d39b",x"d5f5",x"d842",
	x"da82",x"dcb3",x"ded7",x"e0ec",x"e2f1",x"e4e8",x"e6cf",x"e8a6",
	x"ea6d",x"ec24",x"edc9",x"ef5e",x"f0e2",x"f255",x"f3b5",x"f504",
	x"f641",x"f76c",x"f884",x"f98a",x"fa7c",x"fb5c",x"fc29",x"fce3",
	x"fd8a",x"fe1d",x"fe9d",x"ff09",x"ff62",x"ffa7",x"ffd8",x"fff6",
	x"ffff",x"fff6",x"ffd8",x"ffa7",x"ff62",x"ff09",x"fe9d",x"fe1d",
	x"fd8a",x"fce3",x"fc2a",x"fb5d",x"fa7d",x"f98a",x"f884",x"f76c",
	x"f641",x"f505",x"f3b6",x"f255",x"f0e3",x"ef5f",x"edca",x"ec24",
	x"ea6d",x"e8a6",x"e6cf",x"e4e8",x"e2f2",x"e0ec",x"ded7",x"dcb4",
	x"da82",x"d843",x"d5f6",x"d39b",x"d134",x"cec0",x"cc40",x"c9b4",
	x"c71d",x"c47b",x"c1ce",x"bf17",x"bc57",x"b98d",x"b6ba",x"b3df",
	x"b0fc",x"ae11",x"ab1f",x"a827",x"a528",x"a224",x"9f1a",x"9c0c",
	x"98f9",x"95e2",x"92c8",x"8fab",x"8c8c",x"896b",x"8648",x"8324",
	x"8000",x"7cdc",x"79b8",x"7696",x"7374",x"7055",x"6d38",x"6a1e",
	x"6708",x"63f5",x"60e6",x"5ddd",x"5ad8",x"57da",x"54e1",x"51ef",
	x"4f05",x"4c21",x"4946",x"4673",x"43aa",x"40e9",x"3e32",x"3b85",
	x"38e3",x"364c",x"33c0",x"3140",x"2ecc",x"2c65",x"2a0b",x"27bd",
	x"257e",x"234c",x"2129",x"1f14",x"1d0e",x"1b18",x"1931",x"1759",
	x"1592",x"13dc",x"1236",x"10a1",x"0f1d",x"0dab",x"0c4a",x"0afb",
	x"09be",x"0894",x"077b",x"0676",x"0583",x"04a3",x"03d6",x"031c",
	x"0275",x"01e2",x"0162",x"00f6",x"009d",x"0058",x"0027",x"0009",
	x"0000",x"0009",x"0027",x"0058",x"009d",x"00f6",x"0162",x"01e2",
	x"0275",x"031b",x"03d5",x"04a2",x"0582",x"0675",x"077b",x"0893",
	x"09bd",x"0afa",x"0c49",x"0daa",x"0f1c",x"10a0",x"1235",x"13db",
	x"1591",x"1758",x"192f",x"1b16",x"1d0d",x"1f12",x"2127",x"234a",
	x"257c",x"27bc",x"2a09",x"2c63",x"2ecb",x"313f",x"33bf",x"364a",
	x"38e1",x"3b84",x"3e30",x"40e7",x"43a8",x"4671",x"4944",x"4c1f",
	x"4f02",x"51ed",x"54df",x"57d7",x"5ad6",x"5dda",x"60e4",x"63f3",
	x"6705",x"6a1c",x"6d36",x"7053",x"7372",x"7693",x"79b6",x"7cda"
    );

    signal R_code_in, R_code_old, R_code: std_logic_vector(6 downto 0);
    signal R_debounce: std_logic_vector(7 downto 0);
    signal R_clkdiv: std_logic_vector(11 downto 0);
    signal R_vol: signed(15 downto 0);
    signal R_mul: signed(31 downto 0);
    signal R_time: std_logic_vector(31 downto 0);
    signal R_sin: signed(15 downto 0);
    signal R_tone_pcm: signed(15 downto 0);
    signal R_pwm: signed(16 downto 0);

    constant C_attack: signed(15 downto 0) := 291;
    constant C_deccay: signed(15 downto 0) := 24;
    constant C_maxvol: signed(15 downto 0) := 32767;
    constant C_debounce: std_logic_vector(7 downto 0) := 0; -- require n identical readings, 0 to disable
begin
    -- play tone on keyboard
    process(clk_25m)
    begin
	if rising_edge(clk_25m) then
	    R_clkdiv <= R_clkdiv + 1; -- R_clkdiv size 12 bit (0-4095)
	    if R_clkdiv = x"000" then
		R_code_in <= code;
                -- simple debounce: check if code is still the same
                if R_code_in = R_code_old then
                    -- code is still the same
                    -- to be accepted, new code reading must be the same C_debounce times
                    if R_debounce >= C_debounce then
		        if R_code_in /= "0000000" then
		            -- code is persistent and non-zero
                            -- accept new code if it is different than current code
                            if R_code /= R_code_in then
                                R_code <= R_code_in;
                                R_debounce <= 0;
                            else
                                -- incr volume until saturation
                                if R_vol <= C_maxvol - C_attack then
                                    R_vol <= R_vol + C_attack;
                                else
                                    R_vol <= C_maxvol;
                                end if;
                            end if;
                        else
                            -- code is persistent and zero
                            -- decr volume until mute
                            if R_vol >= C_deccay then
			        R_vol <= R_vol - C_deccay;
                            else
			        R_vol <= 0;
                            end if;
                        end if;
                    else
                        R_debounce <= R_debounce + 1;
                    end if;
                else
                    -- different code
                    R_code_old <= R_code_in; -- debounce register
                    R_debounce <= 0;
                end if;
	    end if;

	    -- R_time(31) pulses in f(midi_code)
	    R_time <= R_time + freq_map(conv_integer(R_code));
            -- index: take upper 8 bits (shift right 24 bits)
            -- value: sine_table(index)-0x8000 casted to signed number around 0
	    R_sin <= signed(sin_map(conv_integer(R_time(31 downto 24)))-x"8000");
	    R_mul <= R_vol * R_sin; -- signed multiplication

	    R_tone_pcm <= R_mul(31 downto 16);
	    R_pwm <= R_pwm + (R_pwm(16) & R_tone_pcm);
	    
        end if;
    end process;
    pcm_out <= R_tone_pcm;
    tone_out <= R_pwm(16);
end;
