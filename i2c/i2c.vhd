library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lldevcpu_pack.all;

entity i2c is
	-- data_out - outgoing data
	-- data_in - incoming data 
	port(clk: in std_logic; control_bits: in unsigned16; i2c_addr: in unsigned16; data_out: in data8; sda: inout std_logic := '1'; data_in: out data8 := X"00"; 
			scl: buffer std_logic := '1'; started: out boolean; ready: buffer boolean := true);
end entity;

architecture i2c_arch of i2c is
	
	type i2c_device_type is (i2c_master_dt, i2c_slave_dt);
	subtype i2c_scl_div_type is integer range 10 to 500;
	
	component i2c_clk_divider is 
		port(enable: in boolean; clk: in std_logic; delay_cnt: in i2c_clk_div; out_s: out std_logic := '0');
	end component;

	component i2c_master is
		port(clk: in std_logic; start: in boolean; addr: in data8; data_out: in data8; sda: inout std_logic; data_in: out data8; scl: buffer std_logic; 
			ready: out boolean);
	end component;
	
	signal clk_enable_s: boolean;
	signal clk_s: std_logic := '1';
	signal i2c_master_start_s: boolean;
	signal i2c_slave_start_s: boolean;
	signal control_bits_s: unsigned16 := X"0000";
	signal i2c_addr_s: data8 := X"00";
	signal i2c_device_type_s: i2c_device_type;
	signal i2c_clk_divider_s: i2c_scl_div_type := 10;
	signal i2c_master_ready_s: boolean;
	signal i2c_ready_s: boolean := true;
	signal i2c_tx_data_len_s: i2c_tx_data_len;
	
	alias i2c_enable_a: std_ulogic is control_bits_s(15);
	alias i2c_dev_type_a: std_ulogic is control_bits_s(14);
	alias i2c_clk_divider_a: unsigned(2 downto 0) is control_bits_s(13 downto 11);
	alias i2c_tx_started_a: std_ulogic is control_bits_s(10);
begin
	i2c_clk1: i2c_clk_divider port map(clk_enable_s, clk, i2c_clk_divider_s, clk_s);
	clk_enable_s <= true when i2c_enable_a = '1' else false;
	i2c_clk_divider_s <= 50 when i2c_clk_divider_a = "000" else 10;
	
	i2c_master1: i2c_master port map(clk_s, i2c_master_start_s, i2c_addr_s, data_out, sda, data_in, scl, i2c_master_ready_s);
	
	i2c_master_start_s <= i2c_device_type_s = i2c_master_dt and i2c_tx_started_a = '1';
	i2c_slave_start_s <= i2c_device_type_s = i2c_slave_dt and i2c_tx_started_a = '1';
	i2c_device_type_s <= i2c_master_dt when i2c_dev_type_a = '0' else i2c_slave_dt;
	
	ready <= i2c_ready_s and i2c_master_ready_s;
	
	process(clk)
		variable started_v: boolean;
		variable prev_tx_started_a_v: std_logic := '0';
		variable i2c_ready_v: boolean := true;
	begin
		if(falling_edge(clk)) then			
			if(ready and not started_v) then
				control_bits_s <= control_bits;
				if(i2c_master_start_s or i2c_slave_start_s) then
					i2c_ready_v := false;
					i2c_addr_s <= std_logic_vector(i2c_addr(7 downto 0));
					started_v := true;
				end if;
			elsif(ready and started_v) then
				started_v := not (prev_tx_started_a_v = '0' and i2c_tx_started_a = '1');
			end if;
			
			if(not i2c_master_ready_s) then
				i2c_ready_v := true;
			end if;
			
			i2c_ready_s <= i2c_ready_v;
			prev_tx_started_a_v := i2c_tx_started_a;
			started <= started_v;
		end if;
	end process;
end i2c_arch;