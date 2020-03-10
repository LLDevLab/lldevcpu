library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lldevcpu_pack.all;

entity i2c is
	-- data_out - outgoing data
	-- data_in - incoming data 
	port(clk: in std_logic; control_bits: in unsigned16; i2c_addr: in unsigned16; data_out: in i2c_data8; sda: inout std_logic := '1'; data_in: out i2c_data8 := X"00"; 
			i2c_data_ack: out std_logic; scl: buffer std_logic := '1'; ready: buffer boolean := true);
end entity;

architecture i2c_arch of i2c is
	
	type i2c_device_type is (i2c_master_dt, i2c_slave_dt);
	subtype i2c_scl_div_type is integer range 10 to 500;
	
	component i2c_clk_divider is 
		port(enable: in boolean; clk: in std_logic; delay_cnt: in i2c_clk_div; out_s: out std_logic := '0');
	end component;

	component i2c_master is
		port(clk: in std_logic; start_send: in boolean; stop_send: in boolean; data_send: in boolean; 
				data_out: in i2c_data8; rw_init_state: in i2c_rw; sda: inout std_logic; data_in: out i2c_data8;
				scl: out std_logic; ack: out std_logic; ready: out boolean);
	end component;
	
	signal clk_enable_s: boolean;
	signal clk_s: std_logic := '1';
	signal i2c_master_start_s: boolean;
	signal i2c_master_stop_s: boolean;
	signal i2c_data_send_s: boolean;
	signal i2c_device_type_s: i2c_device_type;
	signal i2c_clk_divider_s: i2c_scl_div_type := 10;
	signal i2c_master_ready_s: boolean;
	signal i2c_ready_s: boolean := true;
	signal i2c_rw_init_state_s: i2c_rw;
	
	alias i2c_enable_a: std_ulogic is control_bits(15);
	alias i2c_dev_type_a: std_ulogic is control_bits(14);
	alias i2c_clk_divider_a: unsigned(2 downto 0) is control_bits(13 downto 11);
	alias i2c_start_send_a: std_ulogic is control_bits(10);
	alias i2c_stop_send_a: std_ulogic is control_bits(9);
	alias i2c_data_send_a: std_ulogic is control_bits(8);
	alias i2c_rw_init_state_a: std_ulogic is control_bits(7);
begin
	i2c_clk1: i2c_clk_divider port map(clk_enable_s, clk, i2c_clk_divider_s, clk_s);
	clk_enable_s <= true when i2c_enable_a = '1' else false;
	i2c_clk_divider_s <= 50 when i2c_clk_divider_a = "000" else 10;
	
	i2c_master1: i2c_master port map(clk_s, i2c_master_start_s, i2c_master_stop_s, i2c_data_send_s, data_out, i2c_rw_init_state_s,
										sda, data_in, scl, i2c_data_ack, i2c_master_ready_s);
	i2c_master_start_s <= i2c_device_type_s = i2c_master_dt and i2c_start_send_a = '1';
	i2c_master_stop_s <= i2c_device_type_s = i2c_master_dt and i2c_stop_send_a = '1';
	i2c_data_send_s <= i2c_data_send_a = '1';
	i2c_rw_init_state_s <= i2c_write when i2c_rw_init_state_a = '0' else i2c_read;
	
	i2c_device_type_s <= i2c_master_dt when i2c_dev_type_a = '0' else i2c_slave_dt;
	
	ready <= i2c_ready_s and i2c_master_ready_s;
	
	process(clk)
		variable i2c_ready_v: boolean := true;
		variable i2c_master_start_v: boolean;
		variable i2c_master_stop_v: boolean;
		variable i2c_data_send_v: boolean;
	begin
		if(falling_edge(clk)) then			
			if(ready) then
				if((not i2c_master_start_v and i2c_master_start_s) or
					(not i2c_master_stop_v and i2c_master_stop_s) or
					(not i2c_data_send_v and i2c_data_send_s)) then
					i2c_ready_v := false;
				end if;
			end if;
			
			if(not i2c_master_ready_s) then
				i2c_ready_v := true;
			end if;
			
			i2c_master_start_v := i2c_master_start_s;
			i2c_master_stop_v := i2c_master_stop_s;
			i2c_data_send_v := i2c_data_send_s;
			i2c_ready_s <= i2c_ready_v;
		end if;
	end process;
end i2c_arch;