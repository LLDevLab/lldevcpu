library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lldevcpu_pack is
	-- special purpose registers
	constant pc_reg_addr: integer := 15;
	constant stack_ptr_reg_addr: integer := 14;
	constant status_reg_addr: integer := 13;	
	
	-- flags
	constant carry_flag_pos: integer := 31;
	constant zero_flag_pos: integer := 30;
	constant negative_flag_pos: integer := 29;
	
	-- UART register indexes
	constant uart_control_reg_idx: integer := 0;
	constant uart_data_out_reg_idx: integer := 1;
	constant uart_data_in_reg_idx: integer := 2;
	constant uart_status_reg_idx: integer := 3;
	
	-- UART settings register bits
	constant uart_tx_enable_bit: integer := 15;
	constant uart_tx_started_bit: integer := 12;
	
	constant rom_addr_msb_num: integer := 11;
	constant ram_addr_msb_num: integer := 9;
	constant periph_addr_msb_num: integer := 2;
	constant max_addr_msb_num: integer := rom_addr_msb_num;
	
	constant uart_max_baud_rate_divider: integer := 2_604;

	type opcode is (noop, add, sub, br, breq, brne, brlts, brgts, brltu, brgtu, cmp, clr, ldi, or_op, and_op, xor_op, not_op, lsh,
					rsh, rtl, rtr, rtlc, rtrc, addc, subc, ld, st, mov, push, pop);
	type mem_type is (unknown, read_only_mem, rand_access_mem, peripherials);
	
	subtype data8 is std_logic_vector(7 downto 0);
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
	
	constant top_of_stack: unsigned32 := X"000002ff";
end lldevcpu_pack;