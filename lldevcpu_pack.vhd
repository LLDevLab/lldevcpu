library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lldevcpu_pack is
	constant pc_reg_addr: integer := 15;
	constant status_reg_addr: integer := 13;
	constant rom_addr_msb_num: integer := 11;
	constant ram_addr_msb_num: integer := 9;
	constant periph_addr_msb_num: integer := 2;
	
	constant carry_flag_pos: integer := 31;
	constant zero_flag_pos: integer := 30;
	constant negative_flag_pos: integer := 29;
	
	-- UART register indexes
	constant uart_settings_reg_idx: integer := 0;
	constant uart_data_out_reg_idx: integer := 1;
	constant uart_data_in_reg_idx: integer := 2;
	
	constant uart_max_baud_rate_divider: integer := 2_604;

	type opcode is (noop, add, sub, br, breq, brne, brlts, brgts, brltu, brgtu, cmp, clr, ldi, or_op, and_op, xor_op, not_op, lsh,
					rsh, rtl, rtr, rtlc, rtrc, addc, subc, ld, st, mov);
	type mem_type is (unknown, read_only_mem, rand_access_mem, peripherials);
	
	subtype rom_data is std_logic_vector(31 downto 0);
	subtype ram_data is std_logic_vector(31 downto 0);
	subtype reg_addr is integer range 0 to 15;
	subtype rom_addr is std_logic_vector(rom_addr_msb_num downto 0);
	subtype ram_addr is std_logic_vector(ram_addr_msb_num downto 0);
	subtype periph_addr is std_logic_vector(periph_addr_msb_num downto 0);
	subtype unsigned32 is unsigned(31 downto 0);
	subtype unsigned22 is unsigned(21 downto 0);
	subtype unsigned16 is unsigned(15 downto 0);
	subtype baud_rate is integer range 108 to uart_max_baud_rate_divider;
end lldevcpu_pack;