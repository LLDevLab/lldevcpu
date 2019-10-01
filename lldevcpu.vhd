library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lldevcpu_pack.all;

entity lldevcpu is
	port(clk: in std_logic; bit_out: out std_logic := '1');
end entity lldevcpu;

architecture lldevcpu_arch of lldevcpu is

	signal sec_s: std_logic := '0';
	
	component clk_divider is
		generic (delay_cnt: integer); 
		port(clk: in std_logic; out_s: out std_logic := '0');
	end component;

	component uat is		-- universal asynchronous transmitter
		port(clk: in std_logic; enable: in boolean; data: in std_logic_vector(0 to 7); bit_out: out std_logic; ready: buffer boolean);
	end component;

	type pipeline_status is (loading, running);
	type execution_states is (decode, exec, write_back);
	type regfile is array(0 to 15) of unsigned32;

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
			src_reg_addr: out reg_addr;
			immediate_val: out unsigned22);
	end component;
	
	component alu is
		port(enable: in boolean; 
			clk: in std_logic; 
			op_code: in opcode; 
			dest_data, src_data: in unsigned32; 
			result: out unsigned32;
			sreg: out unsigned32);
	end component;
	
	signal reg_file_s: regfile := (X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
											X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000"); 
		
	-- ROM control signals
	signal rom_data_s: rom_data := X"00000000";
	
	-- Decoder control signals
	signal instruction_s: rom_data := X"00000000";
	signal opcode_s: opcode;
	signal dest_reg_addr_s: reg_addr := 0;
	signal src_reg_addr_s: reg_addr := 0;
	signal immediate_val_s: unsigned22 := (others => '0');
	
	-- ALU control signals
	signal alu_enable_s: boolean;
	signal alu_result_s: unsigned32 := X"00000000";
	signal alu_dest_val_s: unsigned32 := X"00000000";
	signal alu_src_val_s: unsigned32 := X"00000000";
	signal alu_sreg_val_s: unsigned32 := X"00000000";
	
	-- CPU control signals
	signal pipeline_status_s: pipeline_status;
	signal cur_exec_state_s: execution_states;
	
	-- UART control signals 
	signal clk_uart: std_logic := '0';
	signal uart_enable_s: boolean;
	signal uart_ready_s: boolean;
	signal bit_out_s: std_logic;
	
	-- status register flags aliases
	alias sreg_carry_a: std_ulogic is reg_file_s(status_reg_addr)(carry_flag_pos);
	alias sreg_zero_a: std_ulogic is reg_file_s(status_reg_addr)(zero_flag_pos);
	alias sreg_negative_a: std_ulogic is reg_file_s(status_reg_addr)(negative_flag_pos);
	
	function need_writeback(op_code: opcode) return boolean is
	begin
		return (op_code = add or 
				op_code = sub or
				op_code = clr or
				op_code = ldi or
				op_code = or_op or
				op_code = and_op or
				op_code = xor_op or
				op_code = not_op or
				op_code = lsh or
				op_code = rsh or
				op_code = rtl or
				op_code = rtr);
	end function;
	
	function is_branch(op_code: opcode) return boolean is
	begin
		return (op_code = br or
				op_code = breq or
				op_code = brne or
				op_code = brlts or
				op_code = brgts or
				op_code = brltu or
				op_code = brgtu);
	end function;
	
	function need_branch(op_code: opcode; sreg_carry, sreg_zero, sreg_negative: std_ulogic) return boolean is
		variable ret: boolean;
	begin
		case op_code is
			when br =>
				ret := true;
			when breq =>
				ret := sreg_zero = '1';
			when brne =>
				ret := sreg_zero = '0';
			when brlts =>											-- rd is less than rs (this instruction is using with signed integer numbers)
				ret := sreg_negative = '1';
			when brgts =>											-- rd is greater than rs (this instruction is using with signed integer numbers)
				ret := sreg_negative = '0';
			when brltu =>
				ret := sreg_carry = '1';							-- rd is less than rs (this instruction is using with unsigned integer numbers)
			when brgtu =>
				ret := sreg_carry = '0';							-- rd is greater than rs (this instruction is using with unsigned integer numbers)					
			when others =>
				ret := false;
		end case;
		
		return ret;
	end function;
	
	function is_arithmetic(op_code: opcode) return boolean is
	begin
		return (op_code = add or 
				op_code = sub or
				op_code = cmp or
				op_code = clr);
	end function;
	
	function is_bitwise(op_code: opcode) return boolean is
	begin
		return (op_code = or_op or
				op_code = and_op or
				op_code = xor_op or
				op_code = not_op);
	end function;
	
	function is_shift_rotate(op_code: opcode) return boolean is
	begin
		return (op_code = lsh or
				op_code = rsh or
				op_code = rtl or
				op_code = rtr);
	end function;
begin
	
	sec_delay: clk_divider 
				generic map(25_000_000)	
				port map(clk, sec_s);
				
	uart_delay: clk_divider
				generic map(2_604)	
				port map(clk, clk_uart);
				
	uart_transmit: uat
				port map(clk_uart, uart_enable_s, std_logic_vector(reg_file_s(0)(7 downto 0)), bit_out_s, uart_ready_s);	

	rom1: rom port map(std_logic_vector(reg_file_s(pc_reg_addr)(rom_addr_msb_num downto 0)),
						sec_s,
						rom_data_s);
				
	instr_decoder1: instr_decoder port map(sec_s,
											instruction_s,
											opcode_s,
											dest_reg_addr_s,
											src_reg_addr_s, 
											immediate_val_s);
											
	alu1: alu port map(alu_enable_s,
						sec_s,
						opcode_s,
						alu_dest_val_s,
						alu_src_val_s,
						alu_result_s,
						alu_sreg_val_s);
						
	bit_out <= bit_out_s;
	
	uart_process: process(clk_uart, reg_file_s(0), uart_ready_s)
		variable tmp_reg_val: unsigned32 := reg_file_s(0);
	begin
		if(falling_edge(clk_uart)) then
			if(tmp_reg_val = reg_file_s(0)) then
				uart_enable_s <= false;
			else
				uart_enable_s <= uart_ready_s;
			end if;
			tmp_reg_val := reg_file_s(0);
		end if;
	end process uart_process;
	
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
							next_pc_value := next_pc_value + 1;
								
							reg_file_s(pc_reg_addr) <= next_pc_value;
							
							instruction_s <= rom_data_s;
							cur_exec_state_s <= exec;
						when exec =>
							need_write_back_v := need_writeback(opcode_s);
							
							if(is_arithmetic(opcode_s) or is_bitwise(opcode_s)) then							
								alu_dest_val_s <= reg_file_s(dest_reg_addr_s);
								alu_src_val_s <= reg_file_s(src_reg_addr_s);
								alu_enable_v := true;
							elsif(is_branch(opcode_s)) then
								if(need_branch(opcode_s, sreg_carry_a, sreg_zero_a, sreg_negative_a)) then
									reg_file_s(pc_reg_addr) <= reg_file_s(src_reg_addr_s);
								end if;	
							elsif(is_shift_rotate(opcode_s)) then
								alu_dest_val_s <= reg_file_s(dest_reg_addr_s);
								alu_src_val_s <= "000000000000000000000000000" & immediate_val_s(4 downto 0);
								alu_enable_v := true;
							end if;
														
							cur_exec_state_s <= write_back;
						when write_back =>
							if(need_write_back_v) then
								if(opcode_s = ldi) then
									reg_file_s(dest_reg_addr_s) <= "0000000000" & immediate_val_s;
								else
									reg_file_s(dest_reg_addr_s) <= alu_result_s;
								end if;
							end if;
							
							reg_file_s(status_reg_addr) <= alu_sreg_val_s;
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