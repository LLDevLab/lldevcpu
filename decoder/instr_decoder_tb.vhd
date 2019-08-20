library ieee;
use ieee.std_logic_1164.all;

library lldevcpu;
use lldevcpu.lldevcpu_pack.all;

entity instr_decoder_tb is end;

architecture instr_decoder_tb_arch of instr_decoder_tb is
	component instr_decoder is
		port(clk: in std_logic; 
			instruction: in rom_data; 
			instr_opcode: out opcode;
			dest_reg_addr: out reg_addr;			
			src_reg_addr: out reg_addr);
	end component;
	
	signal clk: std_logic := '0';
	signal instruction_s: rom_data := X"00000000";
	signal opcode_s: opcode;
	signal src_reg_addr_s: reg_addr;
	signal dest_reg_addr_s: reg_addr;
begin
	clk <= not clk after 5 ns;
	
	instruction_s <= "00000100010011000000000000000000" after 10 ns,			-- Сложить (000001) значение регистра 3 (0011) со значением регистра 1 (0001) (1 и 3 - адреса регистров)  
						"00001000100101000000000000000000" after 20 ns,			-- Вычесть (000010) значение регистра 5 (0101) из значения регистра 2 (0010) (5 и 2 - адреса регистров)
						"00001100010101000000000000000000" after 30 ns;			-- Неизвестная операция

	docoder: instr_decoder port map(clk, instruction_s, opcode_s, dest_reg_addr_s, src_reg_addr_s);
end instr_decoder_tb_arch;