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

	type pipeline_status is (loading, running);
	type execution_states is (decode, exec, write_back, waiting);
	type regfile is array(0 to 15) of unsigned32;
	type periph_reg_file is array(0 to 2) of unsigned16;

	component rom is
		port(address: in rom_addr; 
				clock: in std_logic;
				q: out rom_data);
	end component;
	
	component ram is
		port(address: in std_logic_vector(9 downto 0);
				clock: in std_logic;
				data: in std_logic_vector(31 downto 0);
				wren: in std_logic;
				q: out std_logic_vector(31 downto 0));
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
	
	component uart is
		port(clk: in std_logic; 
			data_out: in std_logic_vector(7 downto 0);									
			settings: in unsigned16;
			tx_start_s: boolean;		
			bit_out: out std_logic;
			uart_clk: out std_logic;			
			tx_ready: buffer boolean);
	end component;
	
	signal reg_file_s: regfile := (X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
											X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", top_of_stack, X"00000000"); 
											
	signal periph_reg_file_s: periph_reg_file := (X"0000", X"0000", X"0000");
		
	-- ROM control signals
	signal rom_data_s: rom_data := X"00000000";
	signal rom_addr_s: rom_addr := "000000000000"; 
	
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
	signal uart_clk_out_s: std_logic;
	signal uart_tx_enable_s: boolean;
	signal uart_rx_enable_s: boolean;
	signal uart_rx_ready_s: boolean;
	signal uart_tx_ready_s: boolean;
	signal uart_bit_out_s: std_logic;
	signal uart_bit_in_s: std_logic;
	
	-- RAM control signals
	signal ram_data_in_s: ram_data := X"00000000";
	signal ram_data_out_s: ram_data := X"00000000";
	signal ram_addr_s: ram_addr := "0000000000";
	signal ram_wr_en_s: std_logic := '0';
	
	-- Peripherials control signals
	signal periph_addr_s: periph_addr := "000";
	
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
				op_code = rtr or
				op_code = rtlc or
				op_code = rtrc or
				op_code = addc or
				op_code = subc or
				op_code = ld or
				op_code = mov);
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
				op_code = clr or
				op_code = addc or
				op_code = subc);
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
				op_code = rtr or
				op_code = rtlc or
				op_code = rtrc);
	end function;
	
	function is_stack_op(op_code: opcode) return boolean is
	begin
		return (op_code = push);
	end function;
	
	procedure map_mem_addr(orig_addr: in unsigned(31 downto 0); 
							mapped_addr: out std_logic_vector(31 downto 0);
							memory_type: out mem_type) is
		alias mem_type_a: unsigned(3 downto 0) is orig_addr(31 downto 28);
	begin

		case mem_type_a is
			when "0001" =>
				memory_type := read_only_mem;
			when "0010" =>
				memory_type := rand_access_mem;
			when "0011" =>
				memory_type := peripherials;
			when others =>
				memory_type := unknown;
		end case;
		
		mapped_addr := "0000" & std_logic_vector(orig_addr(27 downto 0));
		
	end map_mem_addr;
begin
	
	sec_delay: clk_divider 
				generic map(25_000_000)	
				port map(clk, sec_s);

	rom1: rom port map(rom_addr_s,
						sec_s,
						rom_data_s);
						
	ram1: ram port map(ram_addr_s, sec_s, ram_data_in_s, ram_wr_en_s, ram_data_out_s);
				
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
						
	uart1: uart port map(clk,
							std_logic_vector(periph_reg_file_s(uart_data_out_reg_idx)(7 downto 0)),
							periph_reg_file_s(uart_settings_reg_idx),
							uart_tx_enable_s,
							uart_bit_out_s,
							uart_clk_out_s,
							uart_tx_ready_s);									
						
	bit_out <= uart_bit_out_s;
	
	uart_tx_process: process(uart_clk_out_s, periph_reg_file_s(uart_data_out_reg_idx), uart_tx_ready_s)
		variable tmp_reg_val: unsigned16 := periph_reg_file_s(uart_data_out_reg_idx);
	begin
		if(falling_edge(uart_clk_out_s)) then
			if(tmp_reg_val = periph_reg_file_s(uart_data_out_reg_idx)) then
				uart_tx_enable_s <= false;
			else
				uart_tx_enable_s <= uart_tx_ready_s;
			end if;
			tmp_reg_val := periph_reg_file_s(uart_data_out_reg_idx);
		end if;
	end process uart_tx_process;
	
	exec_proc: process(sec_s)
		variable next_pc_value: unsigned32 := X"00000000";
		variable alu_enable_v: boolean;
		variable need_write_back_v: boolean;
		variable memory_type_v: mem_type;
		variable mapped_addr_v: std_logic_vector(31 downto 0);
		variable origin_addr_v: unsigned(31 downto 0);
		variable next_exec_state_v: execution_states;
		variable return_exec_state: execution_states;
		variable waiting_count_v: integer range 0 to 10 := 0;
		variable ram_wr_en_v: std_logic := '0';
		variable rom_data_v: rom_data := X"00000000";
		variable periph_addr_v: periph_addr := "000";
		variable stack_ptr_val_v: unsigned32 := X"00000000";
	begin
		if(falling_edge(sec_s)) then
			alu_enable_v := false;
		
			case pipeline_status_s is
				when loading =>
					pipeline_status_s <= running;
				when running =>
					case cur_exec_state_s is
						when decode =>
							next_exec_state_v := exec;
							next_pc_value := reg_file_s(pc_reg_addr);
							next_pc_value := next_pc_value + 1;
								
							reg_file_s(pc_reg_addr) <= next_pc_value;
							rom_addr_s <= std_logic_vector(next_pc_value(rom_addr_msb_num downto 0));
							
							instruction_s <= rom_data_s;
							cur_exec_state_s <= next_exec_state_v;
						when exec =>
							ram_wr_en_v := '0';
							next_exec_state_v := write_back;
							need_write_back_v := need_writeback(opcode_s);
							
							if(is_arithmetic(opcode_s) or is_bitwise(opcode_s)) then							
								alu_dest_val_s <= reg_file_s(dest_reg_addr_s);
								alu_src_val_s <= reg_file_s(src_reg_addr_s);
								alu_enable_v := true;
							elsif(is_branch(opcode_s)) then
								if(need_branch(opcode_s, sreg_carry_a, sreg_zero_a, sreg_negative_a)) then
									reg_file_s(pc_reg_addr) <= reg_file_s(src_reg_addr_s);
									rom_addr_s <= std_logic_vector(reg_file_s(src_reg_addr_s)(rom_addr_msb_num downto 0));
								end if;	
							elsif(is_shift_rotate(opcode_s)) then
								alu_dest_val_s <= reg_file_s(dest_reg_addr_s);
								alu_src_val_s <= "000000000000000000000000000" & immediate_val_s(4 downto 0);
								alu_enable_v := true;
							elsif(opcode_s = ld) then
								origin_addr_v := reg_file_s(src_reg_addr_s);
								map_mem_addr(origin_addr_v, mapped_addr_v, memory_type_v);	
								waiting_count_v := 1;
								next_exec_state_v := waiting;
								return_exec_state := write_back;
								
								case memory_type_v is
									when rand_access_mem =>
										ram_addr_s <= mapped_addr_v(ram_addr_msb_num downto 0);										
									when read_only_mem =>
										rom_addr_s <= mapped_addr_v(rom_addr_msb_num downto 0);
									when peripherials =>
										periph_addr_v := mapped_addr_v(periph_addr_msb_num downto 0);
									when others =>
										null;
								end case;
							elsif(opcode_s = st) then
								origin_addr_v := reg_file_s(dest_reg_addr_s);
								map_mem_addr(origin_addr_v, mapped_addr_v, memory_type_v);
								
								case memory_type_v is
									when rand_access_mem =>
										ram_data_in_s <= std_logic_vector(reg_file_s(src_reg_addr_s));									
										ram_wr_en_v := '1';
									when peripherials =>
										periph_addr_v := mapped_addr_v(periph_addr_msb_num downto 0);
										periph_reg_file_s(to_integer(unsigned(periph_addr_v))) <= reg_file_s(src_reg_addr_s)(15 downto 0);										
									when others =>
										null;
								end case;
								
								next_exec_state_v := write_back;
							elsif(is_stack_op(opcode_s)) then
								stack_ptr_val_v := reg_file_s(stack_ptr_reg_addr);
								ram_addr_s <= std_logic_vector(stack_ptr_val_v(ram_addr_msb_num downto 0));
								
								if(opcode_s = push) then
									ram_data_in_s <= std_logic_vector(reg_file_s(src_reg_addr_s));
									ram_wr_en_v := '1';
									stack_ptr_val_v := stack_ptr_val_v - 1;									
								end if;
																
								reg_file_s(stack_ptr_reg_addr) <= stack_ptr_val_v;
							end if;
							
							periph_addr_s <= periph_addr_v;
							ram_wr_en_s <= ram_wr_en_v;
							cur_exec_state_s <= next_exec_state_v;
						when write_back =>
							next_exec_state_v := decode;
						
							if(need_write_back_v) then
								if(opcode_s = ldi) then
									reg_file_s(dest_reg_addr_s) <= "0000000000" & immediate_val_s;
								elsif(opcode_s = ld) then
									case memory_type_v is
										when rand_access_mem =>
											reg_file_s(dest_reg_addr_s)	<= unsigned(ram_data_out_s);
										when read_only_mem =>
											reg_file_s(dest_reg_addr_s) <= unsigned(rom_data_v);
										when peripherials =>
											reg_file_s(dest_reg_addr_s) <= X"0000" & periph_reg_file_s(to_integer(unsigned(periph_addr_s))); 
										when others =>
											null;
									end case;
								elsif(opcode_s = mov) then
									reg_file_s(dest_reg_addr_s) <= reg_file_s(src_reg_addr_s);
								else
									reg_file_s(dest_reg_addr_s) <= alu_result_s;
								end if;
							end if;
							
							reg_file_s(status_reg_addr) <= alu_sreg_val_s;
							cur_exec_state_s <= next_exec_state_v;
						
						when waiting =>
							if(waiting_count_v >= 1) then
								waiting_count_v := waiting_count_v - 1;
							else
								if(memory_type_v = read_only_mem) then
									rom_data_v := rom_data_s;
									rom_addr_s <= std_logic_vector(next_pc_value(rom_addr_msb_num downto 0));
								end if;
								
								next_exec_state_v := return_exec_state;
							end if;
							
							cur_exec_state_s <= next_exec_state_v;
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