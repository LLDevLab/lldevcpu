library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity instr_decoder is
	port(clk: in std_logic; 
			instruction: in rom_data; 
			instr_opcode: out opcode; 
			dest_reg_addr: out reg_addr := 0;
			src_reg_addr: out reg_addr := 0;
			immediate_val: out unsigned22 := (others => '0'));
end entity instr_decoder;

architecture instr_decoder_arch of instr_decoder is
	alias opcode_bin_s: std_logic_vector(5 downto 0) is instruction(31 downto 26);
	alias dest_reg_addr_s: std_logic_vector(3 downto 0) is instruction(25 downto 22);
	alias src_reg_addr_s: std_logic_vector(3 downto 0) is instruction(21 downto 18);
	alias br_reg_addr_s: std_logic_vector(3 downto 0) is instruction(25 downto 22);
	alias ldi_immediate_val_s: std_logic_vector(21 downto 0) is instruction(21 downto 0);
	alias shift_rotate_imm_val_s: std_logic_vector(4 downto 0) is instruction(21 downto 17);
begin
	process(clk)
		variable src_reg_addr_v: reg_addr := 0;
		variable dest_reg_addr_v: reg_addr := 0;
		variable immediate_val_v: unsigned22 := (others => '0');
	begin
		if(rising_edge(clk)) then
			src_reg_addr_v := 0;
			dest_reg_addr_v := 0;
			immediate_val_v := (others => '0');
					
			case opcode_bin_s is
				when "000001" =>
					instr_opcode <= add;
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "000010" =>
					instr_opcode <= sub;
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "000011" =>
					instr_opcode <= br;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "000100" =>
					instr_opcode <= breq;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "000101" =>
					instr_opcode <= brne;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "000110" =>
					instr_opcode <= brlts;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "000111" =>
					instr_opcode <= brgts;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "001000" =>
					instr_opcode <= brltu;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "001001" =>
					instr_opcode <= brgtu;
					dest_reg_addr_v := pc_reg_addr;
					src_reg_addr_v := to_integer(unsigned(br_reg_addr_s));
				when "001010" =>
					instr_opcode <= cmp;
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "001011" =>
					instr_opcode <= clr;
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "001100" =>
					instr_opcode <= ldi;
					immediate_val_v := unsigned(ldi_immediate_val_s);
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "001101" =>
					instr_opcode <= or_op;					
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "001110" =>
					instr_opcode <= and_op;					
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "001111" =>
					instr_opcode <= xor_op;					
					src_reg_addr_v := to_integer(unsigned(src_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010000" =>
					instr_opcode <= not_op;					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010001" =>
					instr_opcode <= lsh;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010010" =>
					instr_opcode <= rsh;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010011" =>
					instr_opcode <= rtl;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010100" =>
					instr_opcode <= rtr;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010101" =>
					instr_opcode <= rtlc;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when "010110" =>
					instr_opcode <= rtrc;	
					immediate_val_v := "00000000000000000" & unsigned(shift_rotate_imm_val_s);					
					src_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
					dest_reg_addr_v := to_integer(unsigned(dest_reg_addr_s));
				when others =>
					instr_opcode <= noop;
			end case;
			
			immediate_val <= immediate_val_v;
			src_reg_addr <= src_reg_addr_v;
			dest_reg_addr <= dest_reg_addr_v;
		end if;
	end process;
end instr_decoder_arch;