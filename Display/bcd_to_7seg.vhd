library ieee;
use ieee.std_logic_1164.all;

entity bcd_to_7seg is
	port(bcd: in std_logic_vector(3 downto 0) := X"0"; disp_out: out std_logic_vector(7 downto 0) := X"00");
end entity bcd_to_7seg;

architecture bcd_to_7seg_arch of bcd_to_7seg is
	signal not_bcd_s: std_logic_vector(3 downto 0) := X"0";
begin
	not_bcd_s <= not bcd;

	disp_out(7) <= (bcd(2) and not_bcd_s(1) and not_bcd_s(0)) or 
					(not_bcd_s(3) and not_bcd_s(2) and not_bcd_s(1) and bcd(0));
					
	disp_out(6) <= (bcd(2) and not_bcd_s(1) and bcd(0)) or
					(bcd(2) and bcd(1) and not_bcd_s(0));
					
	disp_out(5) <= not_bcd_s(2) and bcd(1) and not_bcd_s(0);
	
	disp_out(4) <= (not_bcd_s(3) and not_bcd_s(2) and not_bcd_s(1) and bcd(0)) or
					(bcd(2) and not_bcd_s(1) and not_bcd_s(0)) or
					(bcd(2) and bcd(1) and bcd(0));
					
	disp_out(3) <= (bcd(2) and not_bcd_s(1)) or bcd(0);
	
	disp_out(2) <= (not_bcd_s(3) and not_bcd_s(2) and bcd(0)) or
					(not_bcd_s(3) and not_bcd_s(2) and bcd(1)) or
					(bcd(1) and bcd(0));
					
	disp_out(1) <= (not_bcd_s(3) and not_bcd_s(2) and not_bcd_s(1)) or
					(bcd(2) and bcd(1) and bcd(0));
	
	disp_out(0) <= '1';
	
end bcd_to_7seg_arch;