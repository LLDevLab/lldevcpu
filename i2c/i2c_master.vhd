library ieee;
use ieee.std_logic_1164.all;

use work.lldevcpu_pack.all;

entity i2c_master is
	-- data_out - outgoing data
	-- data_in - incoming data 
	port(clk: in std_logic; enable: in boolean; addr: in data8; data_out: in data16; sda: inout std_logic := '1'; data_in: out data16 := X"0000"; 
			scl: buffer std_logic := '1'; ready: out boolean := true);
end entity;

architecture i2c_master_arch of i2c_master is	
	type bool_arr_2 is array(0 to 1) of boolean;

	component clk_divider is
		generic (delay_cnt: integer := 50;
				out_s_initial: std_logic := '1'); 
		port(clk: in std_logic; out_s: out std_logic := '0');
	end component;
	
	signal clk_s: std_logic := '1';
	signal sda_rw_s: i2c_rw := i2c_write;
	signal sda_s: std_logic := '1';
	signal i2c_state_s: i2c_state;
	signal i2c_state_addr_s: i2c_send_state;
	signal i2c_state_data_s: i2c_send_state;
	signal addr_ack_s: std_logic := '1';
	signal data_ack_s: std_logic_vector(0 to 1) := "11";
	signal addr_s: data8 := X"00";
	signal data_s: data16 := X"0000";
	
	signal sda_ready_s: boolean := true;
	signal scl_ready_s: boolean := true;
	
	function generate_scl(scl_in: std_logic) return std_logic is
	begin
		if(scl_in = '1') then
			return '0';
		else
			return '1';
		end if;
	end generate_scl;
begin
	i2c_clk1: clk_divider port map(clk, clk_s);
	--clk_s <= clk;
	sda <= sda_s when sda_rw_s = i2c_write else 'Z';
	ready <= sda_ready_s and scl_ready_s;
	
	-- process, that manages i2c states
	state_proc: process(clk_s, enable)
	begin
		if(falling_edge(clk_s)) then
			case i2c_state_s is
				when i2c_idle =>
					if(enable) then
						i2c_state_s <= i2c_start;
						scl_ready_s <= false;
						scl <= '1';
					end if;
				when i2c_start =>
					if(sda = '0' and scl = '0') then
						i2c_state_s <= i2c_addr_send;
						sda_rw_s <= i2c_write;
					elsif(sda = '0' and scl = '1') then
						scl <= '0';
					end if;
				when i2c_addr_send =>
					if(scl = '1') then
						case i2c_state_addr_s is
							when i2c_sending_ack =>
								sda_rw_s <= i2c_read;
							when i2c_sending_rdy =>
								i2c_state_s <= i2c_data_send;
								
								if(addr_s(i2c_addr_rw_bit) = '0') then
									sda_rw_s <= i2c_write;
								else
									sda_rw_s <= i2c_read;
								end if;
							when others =>
								null;
						end case;
					end if;
					
					scl <= generate_scl(scl);
				when i2c_data_send =>
					if(scl = '1') then
						if(addr_s(i2c_addr_rw_bit) = '0') then
							case i2c_state_data_s is
								when i2c_sending =>
									sda_rw_s <= i2c_write;
								when i2c_sending_ack =>
									sda_rw_s <= i2c_read;
								when i2c_sending_rdy =>
									i2c_state_s <= i2c_stop;
									sda_rw_s <= i2c_write;
								when others =>
									null;
							end case;
						else
							case i2c_state_data_s is
								when i2c_sending =>
									sda_rw_s <= i2c_read;
								when i2c_sending_ack =>
									sda_rw_s <= i2c_write;
								when i2c_sending_rdy =>
									i2c_state_s <= i2c_stop;
									sda_rw_s <= i2c_write;
								when others =>
									null;
							end case;
						end if;
					end if;

					scl <= generate_scl(scl);
				when i2c_stop =>
					scl <= '1';
					if(sda_s = '1') then
						i2c_state_s <= i2c_idle;
						scl_ready_s <= true;
					end if;
				when others =>
					null;
			end case;
		end if;
	end process state_proc;
	
	sda_proc: process(clk_s)
		variable cnt_v: data8_range := 0;
		variable data_block_cnt_v: int_0_to_1 := 0;
	begin
		if(rising_edge(clk_s)) then
			case i2c_state_s is
				when i2c_start =>
					data_s <= data_out;
					addr_s <= addr;
					sda_s <= '0';
					sda_ready_s <= false;
					i2c_state_addr_s <= i2c_sending;
					i2c_state_data_s <= i2c_sending;
					data_block_cnt_v := 0;
				when i2c_addr_send =>
					case i2c_state_addr_s is
						when i2c_sending =>
							if(scl = '0') then
								sda_s <= addr_s(cnt_v);
							else
								if(cnt_v < 7) then
									cnt_v := cnt_v + 1;
								else
									cnt_v := 0;
									i2c_state_addr_s <= i2c_sending_ack;
								end if;
							end if;
						when i2c_sending_ack =>
							if(scl = '1') then
								addr_ack_s <= sda;
								i2c_state_addr_s <= i2c_sending_rdy;
							end if;
						when others =>
							null;
					end case;
				when i2c_data_send =>
					if(addr_s(i2c_addr_rw_bit) = '0') then
						case i2c_state_data_s is
							when i2c_sending =>
								if(scl = '0') then
									sda_s <= data_s(data_block_cnt_v * byte_len + cnt_v);
								else
									if(cnt_v < 7) then
										cnt_v := cnt_v + 1;
									else
										cnt_v := 0;
										i2c_state_data_s <= i2c_sending_ack;
									end if;
								end if;
							when i2c_sending_ack =>
								if(scl = '1') then
									sda_s <= '0';											-- reset sda_s, just in case
									data_ack_s(data_block_cnt_v) <= sda;
									
									if(data_block_cnt_v = 0) then
										data_block_cnt_v := 1;
										i2c_state_data_s <= i2c_sending;
									else
										i2c_state_data_s <= i2c_sending_rdy;
									end if;
								end if;
							when others =>
								null;
						end case;
					else
						case i2c_state_data_s is
							when i2c_sending =>
								if(scl = '1') then
									sda_s <= '0';											-- reset sda_s, just in case
									data_s(data_block_cnt_v * byte_len + cnt_v) <= sda;
									
									if(cnt_v < 7) then
										cnt_v := cnt_v + 1;
									else
										cnt_v := 0;
										i2c_state_data_s <= i2c_sending_ack;
									end if;
								end if;
							when i2c_sending_ack =>
								if(scl = '0') then
									sda_s <= '0';
								else
									if(data_block_cnt_v = 0) then
										data_block_cnt_v := 1;
										i2c_state_data_s <= i2c_sending;
									else
										i2c_state_data_s <= i2c_sending_rdy;
									end if;
								end if;
							when others =>
								null;
						end case;
					end if;
				when i2c_stop =>
					if(scl = '1') then
						sda_s <= '1';
					end if;
					
					data_in <= data_s;					
					sda_ready_s <= true;
				when others =>
					null;
			end case;
		end if;
	end process sda_proc;
end i2c_master_arch;