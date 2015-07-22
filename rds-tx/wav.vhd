constant C_dbpsk_wav_len: std_logic_vector(7 downto 0) := 48;
type dbpsk_wav_type is array(0 to 47) of std_logic_vector(7 downto 0);
constant dbpsk_wav_map: dbpsk_wav_type := (
x"47",x"53",x"5e",x"67",x"6e",x"73",x"75",x"75",x"73",x"6f",x"6a",x"66",x"61",x"5e",x"5c",x"5c",
x"5e",x"62",x"67",x"6d",x"73",x"79",x"7d",x"7f",x"7f",x"7d",x"78",x"71",x"68",x"5e",x"52",x"46",
x"3a",x"2e",x"22",x"18",x"0f",x"08",x"03",x"01",x"01",x"03",x"08",x"0f",x"18",x"22",x"2e",x"3a"
);
