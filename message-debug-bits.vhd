-- RDS message
-- LICENSE=BSD

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package message is
    -- testing 8 bits, 0 to 1 bit by bit
    type rds_msg_type is array(0 to 8) of std_logic_vector(7 downto 0);
    constant rds_msg_map: rds_msg_type := (
      x"00", x"01", x"03", x"07", x"0f", x"1f", x"3f", x"7f", x"ff"
    );
end message;
