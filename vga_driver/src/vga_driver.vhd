library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_driver is
	Port ( 	CLK: in STD_LOGIC;
			RST: in STD_LOGIC;
			sel: in STD_LOGIC_VECTOR( 2 downto 0);
			HSYNC: out STD_LOGIC;
			VSYNC: out STD_LOGIC;
			RGB: out STD_LOGIC_VECTOR (2 downto 0));
end vga_driver;

architecture Behavioral of vga_driver is
	signal clk25: std_logic:='0';	  
	
	constant HD: integer :=640;			 -- horizontal display
	constant HFP: integer :=16;		 -- front porch
	constant HSP: integer :=96;		  -- sync pulse
	constant HBP: integer :=48;		   -- back porch	 
	
	constant VD: integer :=480;			 -- vertical display
	constant VFP: integer :=10;		 -- front porch
	constant VSP: integer :=0;		  -- sync pulse	  !!! 
	constant VBP: integer :=33;		   -- back porch	 		
	
	signal hPos : integer :=0;
	signal vPos : integer :=0;	
	
	signal offset : integer :=0;
	
	signal turnedOn: std_logic:= '0';
	
begin
	clk_div:process(CLK)
	begin
		if(CLK'event and CLK='1') then
			clk25 <= not clk25;
		end if;
	end process;			 

	
Horizontal_pos_counter:process (clk25, RST)
begin
	if(RST = '1')then
		hpos <= 0;
	elsif(clk25'event and clk25='1') then
		if(hpos = HD + HFP + HSP + HBP)then
			hpos <= 0;
		else
			hpos <= hpos+1;
		end if;
	end if;
end process;		


Vertical_pos_counter:process (clk25, RST, hpos)		  
begin							  
	if(RST = '1')then
		vpos <= 0;
	elsif(clk25'event and clk25='1') then  
		if(hpos = HD + HFP + HSP + HBP)then -- count enable
			if(vpos = VD + VFP + VSP + VBP)then
				vpos <= 0;
			else
				vpos <= vpos+1;
			end if;
		end if;
	end if;
end process;


Horizontal_sync:process (clk25, RST, hpos)
begin
	if(RST = '1')then
		HSYNC <= '0';
	elsif(clk25'event and clk25 = '1')then 
		if(hpos <= (HD + HFP) or (hpos >HD + HFP + HSP))then
			HSYNC <= '1';
		else
			HSYNC <= '0';
		end if;
	end if;
end process; 

Vertical_sync:process (clk25, RST, vpos)
begin
	if(RST = '1')then
		VSYNC <= '0';
	elsif(clk25'event and clk25 = '1')then 
		if(vpos <= (VD + VFP) or (vpos >VD + VFP + VSP))then
			VSYNC <= '1';
		else
			VSYNC <= '0';
		end if;
	end if;
end process; 

checkVideo: process(clk25, RST, hpos, vpos)
begin
	if(RST = '1')then
		turnedOn <= '0';
	elsif(clk25'event and clk25='1')then
		if(hpos <= HD and vpos <=VD)then
			turnedOn <= '1';
		else
			turnedOn <= '0';
		end if;
	end if;
end process;

drawing: process (clk25, RST, hpos, vpos, turnedOn, sel)
begin
	case sel is
		when "000" =>  -- square
				if(RST = '1')then
					RGB <= "000";	-- black
				elsif(clk25'event and clk25= '1')then
					if(turnedOn = '1')then
						if((hpos >= 1 and hpos <= 60) and (vpos >= 0 and vpos <=60))then
							RGB <= "111" ;  -- white
						else
							RGB <= "000";
						end if;
					else
						RGB <= "000";
					end if;	
				end if;
		when "001" =>  -- rect
				if(RST = '1')then
					RGB <= "000";
				elsif(clk25'event and clk25= '1')then
					if(turnedOn = '1')then
						if((hpos >= 0 and hpos <= 300) and (vpos >= 0 and vpos <=250))then
							RGB <= "101" ;		-- pink
						else
							RGB <= "000";		
						end if;
					else
						RGB <= "000";
					end if;
				end if;
		when "010" => -- triangle
				if(RST = '1')then
					RGB <= "000";
				elsif(clk25'event and clk25= '1')then
					if(turnedOn = '1')then
						if((hpos >=0 and hpos<=60-offset) and (vpos >= 1 and vpos <=61))then
							RGB <= "010"; -- green
						else
							RGB <= "000";
						end if;
						if(hpos = 60 - offset)then
							offset <= offset+1;	
						end if;
					else   
						RGB <= "000";
					end if;
				end if;	
		when "011" => -- hlines
				if(RST = '1')then
					RGB <= "000";
				elsif(clk25'event and clk25= '1')then
					if(turnedOn = '1')then
						if((hpos >= 2 and hpos <= 30) and (vpos = 1 or vpos = 3))then
							RGB <= "001" ;		-- blue
						else
							RGB <= "000";
						end if;
					else
						RGB <= "000";
					end if;
				end if;
		when "100" => -- vlines
			if(RST = '1')then
				RGB <= "000";
			elsif(clk25'event and clk25= '1')then
				if(turnedOn = '1')then
					if((hpos = 2 or hpos = 4) and (vpos >= 1 and vpos <= 30))then
						RGB <= "011" ;	-- cyan
					else
						RGB <= "000";
					end if;
				else
					RGB <= "000";
				end if;
			end if;
		when others => null;
	end case;
end process;
end Behavioral;