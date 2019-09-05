library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lldevcpu_pack is
	constant pc_reg_addr: integer := 15;
	constant status_reg_addr: integer := 13;
	constant rom_addr_msb_num: integer := 11;
	
	constant carry_flag_pos: integer := 31;
	constant zero_flag_pos: integer := 30;
	constant negative_flag_pos: integer := 29;

	type opcode is (noop, add, sub, br, breq, brne, brlts, brgts, brltu, brgtu, cmp, clr);
	subtype rom_data is std_logic_vector(31 downto 0);
	subtype reg_addr is integer range 0 to 15;
	subtype rom_addr is std_logic_vector(rom_addr_msb_num downto 0);
	subtype unsigned32 is unsigned(31 downto 0);
end lldevcpu_pack;