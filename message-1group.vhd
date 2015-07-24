-- RDS message
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package message is
    -- testing 1 group of 13 bytes, PID=0x1234
    type rds_msg_type is array(0 to 12) of std_logic_vector(7 downto 0);
    constant rds_msg_map: rds_msg_type := (
x"12",x"34",x"1a",x"89",x"01",x"96",x"82",x"02",x"00",x"00",x"80",x"80",x"dc"
    );
end message;
