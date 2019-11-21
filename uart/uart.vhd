library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lldevcpu_pack.all;

entity uart is
	port(clk: in std_logic; 
			data_out: in std_logic_vector(7 downto 0);		-- outgoint data
			--bit_in: in std_logic;							-- incoming data bit
			settings: in unsigned16;
			--rx_start_s: in boolean;
			tx_start_s: in boolean;
			--data_in: out std_logic_vector(7 downto 0);		-- incoming data
			bit_out: out std_logic;							-- outgoing data bit
			--rx_ready: buffer boolean := true;
			tx_ready: buffer boolean := true);
end entity;
	
architecture uart_arch of uart is
	constant tx_enable_bit: integer := 15;
	constant rx_enable_bit: integer := 14;

	component uat is		-- universal asynchronous transmitter
		port(clk: in std_logic; enable: in boolean; data: in std_logic_vector(0 to 7); bit_out: out std_logic; ready: buffer boolean);
	end component;
	
	alias tx_enable_a: std_ulogic is settings(tx_enable_bit);
	--alias rx_enable_a: std_ulogic is settings(rx_enable_bit);
	
	signal tx_enable_s: boolean;
begin
	uat1: uat port map(clk, tx_enable_s, data_out, bit_out, tx_ready);
	
	tx_enable_s <= tx_enable_a = '1' and tx_start_s;
end uart_arch;