library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lldevcpu_pack.all;

entity lldevcpu is
	port(clk: in std_logic; sclk, rclk, dio: out std_logic := '0');
end entity lldevcpu;

architecture lldevcpu_arch of lldevcpu is
	signal sec_s: std_logic := '0';
	
	component clk_divider is
		generic (delay_cnt: integer); 
		port(clk: in std_logic; out_s: out std_logic := '0');
	end component;

	component display is
		port(clk: in std_logic; display_data: in std_logic_vector(3 downto 0); sclk, rclk, dio: out std_logic);
	end component;

	type pipeline_status is (loading, running);
	type execution_states is (decode, exec, write_back);
	type regfile is array(0 to 15) of unsigned32;
	constant pc_reg_addr: integer := 15;

	component rom is
		port(address: in rom_addr; 
				clock: in std_logic;
				q: out rom_data);
	end component;
	
	component instr_decoder is
		port(clk: in std_logic; 
			instruction: in rom_data; 
			instr_opcode: out opcode; 
			dest_reg_addr: out reg_addr;
			src_reg_addr: out reg_addr);
	end component;
	
	component alu is
		port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32);
	end component;
	
	signal reg_file_s: regfile := (X"00000000", X"00000005", X"00000004", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
											X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000"); 
	
	-- Сигналы ROM
	signal rom_data_s: rom_data := X"00000000";
	
	-- Сигналы декодера
	signal instruction_s: rom_data := X"00000000";
	signal opcode_s: opcode;
	signal dest_reg_addr_s: reg_addr := 0;
	signal src_reg_addr_s: reg_addr := 0;
	
	-- Сигналы АЛУ
	signal alu_enable_s: boolean;
	signal alu_result_s: unsigned32 := X"00000000";
	signal alu_dest_val_s: unsigned32 := X"00000000";
	signal alu_src_val_s: unsigned32 := X"00000000";
	
	-- Управляющие сигналы
	signal pipeline_status_s: pipeline_status;
	signal cur_exec_state_s: execution_states;
begin
	sec_delay: clk_divider 
				generic map(25_000_000)	
				port map(clk, sec_s);
				
	display1: display port map(clk, std_logic_vector(reg_file_s(0)(3 downto 0)), sclk, rclk, dio);		

	rom1: rom port map(std_logic_vector(reg_file_s(pc_reg_addr)(rom_addr_msb_num downto 0)),
						sec_s,
						rom_data_s);
				
	instr_decoder1: instr_decoder port map(sec_s,
											instruction_s,
											opcode_s,
											dest_reg_addr_s,
											src_reg_addr_s);
											
	alu1: alu port map(alu_enable_s,
						sec_s,
						opcode_s,
						alu_dest_val_s,
						alu_src_val_s,
						alu_result_s);
	
	exec_proc: process(sec_s)
		variable next_pc_value: unsigned32 := X"00000000";
		variable alu_enable_v: boolean;
		variable need_write_back_v: boolean;
	begin
		if(falling_edge(sec_s)) then
			alu_enable_v := false;
		
			case pipeline_status_s is
				when loading =>
					pipeline_status_s <= running;
				when running =>
					case cur_exec_state_s is
						when decode =>
							next_pc_value := reg_file_s(pc_reg_addr);
							
							-- Ограничиваю количество инструкций
							if(next_pc_value < 5) then
								next_pc_value := next_pc_value + 1;
							end if;	
								
							reg_file_s(pc_reg_addr) <= next_pc_value;
							
							instruction_s <= rom_data_s;
							cur_exec_state_s <= exec;
						when exec =>
							need_write_back_v := opcode_s = add or opcode_s = sub;
						
							alu_dest_val_s <= reg_file_s(dest_reg_addr_s);
							alu_src_val_s <= reg_file_s(src_reg_addr_s);
							
							alu_enable_v := true;
							cur_exec_state_s <= write_back;
						when write_back =>
							if(need_write_back_v) then
								reg_file_s(dest_reg_addr_s) <= alu_result_s;								
							end if;
							
							cur_exec_state_s <= decode;
						when others =>
							null;
					end case;
				when others =>
					null;
			end case;
			
			alu_enable_s <= alu_enable_v;
		end if;
	end process exec_proc;
end lldevcpu_arch;