library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity alu is
	port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32 := X"00000000";
			sreg: out unsigned32 := X"00000000");
end entity;

architecture alu of alu is
	alias carry_flag_a: std_ulogic is sreg(carry_flag_pos);
	alias zero_flag_a: std_ulogic is sreg(zero_flag_pos);
	alias negative_flag_a: std_ulogic is sreg(negative_flag_pos);
	
	function get_zero_flag(result_param: unsigned(32 downto 0)) return std_ulogic is
	begin
		if(result_param(31 downto 0) = X"00000000") then
			return '1';
		else
			return '0';
		end if;
	end function;
begin	
	process(clk, enable)
		constant carry_bit_pos: integer := 32;
		variable is_opcode_processed_v: std_ulogic;
		variable result_v: unsigned(32 downto 0) := (others => '0');
		variable shift_rotate_imm_v: integer range 0 to 31;
		variable prev_carry_bit: std_logic := '0';
	begin	
		if(rising_edge(clk) and enable) then
			is_opcode_processed_v := '1';
			shift_rotate_imm_v := to_integer(src_data(4 downto 0));
		
			case op_code is
				when add =>
					result_v := ('0' & dest_data) + ('0' & src_data);
				when sub | cmp =>
					result_v := ('0' & dest_data) - ('0' & src_data);	
				when clr =>
					result_v := (others => '0');
				when or_op =>
					result_v := ('0' & dest_data) or ('0' & src_data);
				when and_op =>
					result_v := ('0' & dest_data) and ('0' & src_data);
				when xor_op =>
					result_v := ('0' & dest_data) xor ('0' & src_data);
				when not_op =>
					result_v := '0' & (not dest_data);
				when lsh =>
					result_v := shift_left('0' & dest_data, shift_rotate_imm_v);
				when rsh =>
					result_v := shift_right(dest_data & '0', shift_rotate_imm_v);
					-- After shifting carry bit will be at position 0, we should move it to position 32
					result_v := rotate_right(result_v, 1);
				when rtl =>
					result_v := '0' & rotate_left(dest_data, shift_rotate_imm_v);
					result_v(carry_bit_pos) := result_v(0);
				when rtr =>
					result_v := '0' & rotate_right(dest_data, shift_rotate_imm_v);
					result_v(carry_bit_pos) := result_v(31);
				when rtlc =>
					result_v := prev_carry_bit & dest_data;
					result_v := rotate_left(result_v, shift_rotate_imm_v);
				when rtrc =>
					result_v := prev_carry_bit & dest_data;
					result_v := rotate_right(result_v, shift_rotate_imm_v);
				when addc =>
					result_v := ('0' & dest_data) + ('0' & src_data) + ("00000000000000000000000000000000" & prev_carry_bit);
				when subc =>
					result_v := ('0' & dest_data) - ('0' & src_data) - ("00000000000000000000000000000000" & prev_carry_bit);
				when others =>
					result_v := (others => '0');
					is_opcode_processed_v := '0';
			end case;
			
			prev_carry_bit := result_v(carry_bit_pos);
			carry_flag_a <= result_v(carry_bit_pos); 	-- bit 32 of result_v is a carry bit (carry bit can be used as overflow bit)
			
			-- setting zero flag if opcode is processed by ALU 
			zero_flag_a <= is_opcode_processed_v and get_zero_flag(result_v); 
			
			negative_flag_a <= result_v(31);			-- Set negative flag if MSB of the result is set
			result <= result_v(31 downto 0);
		end if;
	end process;
end alu;