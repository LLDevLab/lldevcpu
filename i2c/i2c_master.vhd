library ieee;
use ieee.std_logic_1164.all;

use work.lldevcpu_pack.all;

entity i2c_master is
	-- data_out - outgoing data
	-- data_in - incoming data 
	port(clk: in std_logic; start_send: in boolean; stop_send: in boolean; data_send: in boolean; 
			data_out: in i2c_data8; rw_init_state: in i2c_rw; sda: inout std_logic := '1'; data_in: out i2c_data8 := X"00";
			scl: out std_logic := '1'; ack: out std_logic := '1'; ready: out boolean := true);
end entity;

architecture i2c_master_arch of i2c_master is
	subtype data_range is integer range 0 to 9;

	signal sda_rw_s: i2c_rw := i2c_write;
	signal sda_s: std_logic := '1';
	signal sda_start_stop_s: std_logic := '1';
	signal sda_data_s: std_logic := '0';
	signal i2c_state_s: i2c_state;
	signal scl_s: std_logic := '1';
	signal rising_scl_cnt_s: data_range := 0;
	signal falling_scl_cnt_s: data_range := 0;
	signal data_in_s: i2c_data8 := X"00";
	signal ack_s: std_logic := '1';
begin
	sda <= sda_s when sda_rw_s = i2c_write else 'Z';
	scl <= scl_s;
	-- sda_data_s and sda_start_stop_s are setting in different processes
	sda_s <= sda_data_s when i2c_state_s = i2c_data_send else sda_start_stop_s;
	ack <= ack_s;
	
	state_proc: process(clk, start_send, stop_send, data_send)
		variable prev_start_send_v: boolean;
		variable prev_stop_send_v: boolean;
		variable prev_data_send_v: boolean;
		variable i2c_state_v: i2c_state;
		variable scl_v: std_logic := '1';
		variable sda_v: std_logic := '1';
		variable ready_v: boolean := true;
		variable rising_scl_cnt_v: data_range := 0;
		variable falling_scl_cnt_v: data_range := 0;
		variable sda_rw_v: i2c_rw := i2c_write;
	begin
		if(falling_edge(clk)) then
			sda_rw_v := sda_rw_s;
			if(prev_start_send_v) then
				case i2c_state_v is
					when i2c_start =>
						if(scl_v = '1' and sda_v = '1') then
							ready_v := false;
							sda_v := '0';
						elsif(sda_v = '0' and scl_v = '1') then
							scl_v := '0';
							ready_v := true;
						end if;
					when i2c_data_send =>
						-- after data was sending and ack was reading ready is setting to true and scl to 0
						if(rising_scl_cnt_v = 9 and scl_v = '1') then
							ready_v := true;
							scl_v := '0';
						end if;
						
						if(rising_scl_cnt_v < 9) then
							ready_v := false;
							
							if(scl_v = '0') then
								scl_v := '1';
								rising_scl_cnt_v := rising_scl_cnt_v + 1;
							else
								scl_v := '0';
								falling_scl_cnt_v := falling_scl_cnt_v + 1;
							end if;
							
							-- Reading or writing ack bit
							if(falling_scl_cnt_v = 8) then
								if(rw_init_state = i2c_write) then
									sda_rw_v := i2c_read;
								else
									sda_rw_v := i2c_write;
								end if;
							end if;
						end if;
					when i2c_stop =>
						-- this condition can occur at any time, so I'm checking all possible scl and sda states
						if(scl_v = '0') then
							if(sda_v = '0') then
								scl_v := '1';
							else
								sda_v := '0';
							end if;
						else
							if(sda_v = '0') then
								sda_v := '1';
								i2c_state_v := i2c_idle;
							end if;
						end if;
						
						if(sda_v = '1' and scl_v = '1') then
							ready_v := true;
						else
							ready_v := false;
						end if;
					when others => 
						null;
				end case;
			end if;
			
			-- Start and rstart conditions
			if(prev_start_send_v = not start_send) then
				-- Detecting when start_send was just set to true
				if(not prev_start_send_v) then
					-- overwrite current state
					i2c_state_v := i2c_start;
					ready_v := false;
					scl_v := '1';
					sda_v := '1';
					rising_scl_cnt_v := 0;
					falling_scl_cnt_v := 0;
					sda_rw_v := i2c_write;
				end if;
				prev_start_send_v := start_send;
			end if;
			
			-- Stop condition
			if(prev_stop_send_v = not stop_send) then
				-- Detecting when stop_send was just set to true
				if(not prev_stop_send_v) then
					-- overwrite current state
					i2c_state_v := i2c_stop;
					ready_v := false;
					rising_scl_cnt_v := 0;
					falling_scl_cnt_v := 0;
					sda_rw_v := i2c_write;
				end if;
				prev_stop_send_v := stop_send;
			end if;
			
			-- Sending data condition
			if(prev_data_send_v = not data_send) then
				-- Detecting when data_send was just set to true
				if(not prev_data_send_v) then
					-- Start sending data
					i2c_state_v := i2c_data_send;
					rising_scl_cnt_v := 0;
					falling_scl_cnt_v := 0;
					sda_rw_v := rw_init_state;
				end if;
				prev_data_send_v := data_send;
			end if;
			
			sda_rw_s <= sda_rw_v;
			i2c_state_s <= i2c_state_v;
			rising_scl_cnt_s <= rising_scl_cnt_v;
			falling_scl_cnt_s <= falling_scl_cnt_v;
			sda_start_stop_s <= sda_v;
			scl_s <= scl_v;
			ready <= ready_v;
		end if;
	end process state_proc;
	
	data_write_proc: process(clk, scl_s)
	begin
		if(rising_edge(clk) and scl_s = '0') then			
			if(sda_rw_s = i2c_write) then
				if(rw_init_state = i2c_write) then
					-- Sending data
					-- Here I'm setting next bit to send so I'm using rising_scl_cnt_s
					if(rising_scl_cnt_s < 8) then							-- sending bits 0 to 7
						sda_data_s <= data_out(rising_scl_cnt_s);
					end if;
				else
					-- Sending ack
					if(falling_scl_cnt_s = 8) then
						sda_data_s <= '0';
						data_in <= data_in_s;
					end if;
				end if;
			end if;
		end if;
	end process data_write_proc;
	
	data_read_proc: process(clk, scl_s)
	begin
		if(falling_edge(clk) and scl_s = '1') then
			if(sda_rw_s = i2c_read) then
				if(rw_init_state = i2c_read) then
					-- Read data from i2c
					if(falling_scl_cnt_s < 8) then					-- receiving bits 0 to 7
						ack_s <= '1';								-- Reset ack bit
						data_in_s(falling_scl_cnt_s) <= sda;
					end if;
				else
					-- Read ack
					if(rising_scl_cnt_s = 9 and falling_scl_cnt_s < 9) then
						ack_s <= sda;
					end if;
				end if;
			end if;
		end if;
	end process data_read_proc;
end i2c_master_arch;