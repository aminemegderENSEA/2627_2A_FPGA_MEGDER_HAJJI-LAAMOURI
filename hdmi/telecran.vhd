library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
	generic (
		
		h_res 	: positive := 720;
		v_res 	: positive := 480;

		
		h_sync	: positive := 61;
		h_fp	: positive := 58;
		h_bp	: positive := 18;

		v_sync	: positive := 5;
		v_fp	: positive := 30;
		v_bp	: positive := 9
	);
	port (
		i_clk  		: in std_logic;
    	i_rst_n 	: in std_logic;
		
    	o_hdmi_hs   : out std_logic;
    	o_hdmi_vs   : out std_logic;
    	o_hdmi_de   : out std_logic;

		o_pixel_en : out std_logic;
		o_pixel_address : out natural range 0 to (h_res * v_res - 1);
		o_x_counter : out natural range 0 to (h_res - 1);
		o_y_counter : out natural range 0 to (v_res - 1)
  	);
end hdmi_controler;

architecture rtl of hdmi_controler is
    constant h_start: positive := h_sync + h_fp;	
	constant h_end  : positive := h_res + h_start;	
	constant h_total: positive := h_end + h_bp;	    

	constant v_start: positive := v_sync + v_fp;	
	constant v_end  : positive := v_res + v_start;	
	constant v_total: positive := v_end + v_bp;	    

	constant pixel_number : natural := h_res*v_res;

    signal r_h_count : natural range 0 to h_total := 0;
    signal r_h_active: std_logic := '0';

	signal r_v_count : natural range 0 to v_total := 0;
    signal r_v_active: std_logic := '0';

	signal s_x_counter : natural range 0 to (h_res - 1) := 0;
	signal s_y_counter : natural range 0 to (v_res - 1) := 0;
begin
    
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			r_h_count   <= 0;
			o_hdmi_hs    <= '1';
			r_h_active     <= '0';
		elsif rising_edge(i_clk) then
			if (r_h_count = h_total) then
				r_h_count <= 0;
			else
				r_h_count <= r_h_count + 1;
			end if;

			if ((r_h_count >= h_sync) and (r_h_count /= h_total)) then
				o_hdmi_hs <= '1';
			else
				o_hdmi_hs <= '0';
			end if;

			if (r_h_count = h_start) then
				r_h_active <= '1';
			elsif (r_h_count = h_end) then
				r_h_active <= '0';
			end if;
		end if;
	end process;

	
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			r_v_count <= 0;
			o_hdmi_vs  <= '1';
			r_v_active   <= '0';
		elsif rising_edge(i_clk) then
			if (r_h_count = h_total) then
				if (r_v_count = v_total) then
					r_v_count <= 0;
				else
					r_v_count <= r_v_count + 1;
				end if;
	
				if ((r_v_count >= v_sync) and (r_v_count /= v_total)) then
					o_hdmi_vs <= '1';
				else
					o_hdmi_vs <= '0';
				end if;

				if (r_v_count = v_start) then
					r_v_active <= '1';
				elsif (r_v_count = v_end) then
					r_v_active <= '0';
				end if;
			end if;
		end if;
	end process;

	
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			o_hdmi_de <= '0';
		elsif rising_edge(i_clk) then
			o_hdmi_de <= r_v_active and r_h_active;
		end if;
	end process;


	o_pixel_en <= '1' when (r_v_active = '1') and (r_h_active = '1') else '0';


	s_x_counter <= (r_h_count - h_start - 1) when (r_h_count > h_start) and (r_h_count < h_res + h_start + 1) else 0;
	s_y_counter <= (r_v_count - v_start - 1) when (r_v_count > v_start) and (r_v_count < v_res + v_start + 1) else 0;

	o_pixel_address <= s_x_counter + (s_y_counter * h_res);
	
	o_x_counter <= s_x_counter;
	o_y_counter <= s_y_counter;
end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity telecran is
    port (
        i_clk_50 : in std_logic;

        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk   : out std_logic;
        o_hdmi_tx_d     : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de    : out std_logic;
        o_hdmi_tx_hs    : out std_logic;
        i_hdmi_tx_int   : in std_logic;
        o_hdmi_tx_vs    : out std_logic;

        i_rst_n : in std_logic;

        o_leds      : out std_logic_vector(9 downto 0);
        o_de10_leds : out std_logic_vector(7 downto 0);

        i_left_ch_a  : in std_logic;
        i_left_ch_b  : in std_logic;
        i_left_pb    : in std_logic;
        i_right_ch_a : in std_logic;
        i_right_ch_b : in std_logic;
        i_right_pb   : in std_logic
    );
end entity telecran;

architecture rtl of telecran is
    component I2C_HDMI_Config
        port (
            iCLK        : in std_logic;
            iRST_N      : in std_logic;
            I2C_SCLK    : out std_logic;
            I2C_SDAT    : inout std_logic;
            HDMI_TX_INT : in std_logic
        );
    end component;

    component pll
        port (
            refclk   : in std_logic;
            rst      : in std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    constant H_RES : positive := 720;
    constant V_RES : positive := 480;

    signal s_clk_27 : std_logic;
    signal s_pll_locked : std_logic;
    signal s_rst_n : std_logic;

    signal s_x : natural range 0 to H_RES - 1 := 0;
    signal s_y : natural range 0 to V_RES - 1 := 0;
    signal s_x_counter : natural range 0 to H_RES - 1 := 0;
    signal s_y_counter : natural range 0 to V_RES - 1 := 0;

    signal s_x_counter_d : natural range 0 to H_RES - 1 := 0;
    signal s_y_counter_d : natural range 0 to V_RES - 1 := 0;
    signal s_hs, s_vs, s_de : std_logic;
    signal s_rgb : std_logic_vector(23 downto 0);
begin
    
    pll0 : component pll
        port map (
            refclk => i_clk_50,
            rst => not i_rst_n,
            outclk_0 => s_clk_27,
            locked => s_pll_locked
        );

   
    s_rst_n <= i_rst_n and s_pll_locked;

    video0 : entity work.hdmi_controler
        generic map (h_res => H_RES, v_res => V_RES)
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            o_hdmi_hs => s_hs,
            o_hdmi_vs => s_vs,
            o_hdmi_de => s_de,
            o_pixel_en => open,
            o_pixel_address => open,
            o_x_counter => s_x_counter,
            o_y_counter => s_y_counter
        );

 
    encoder_x : entity work.encoder
        generic map (max_count => H_RES)
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            i_ch_a => i_left_ch_a,
            i_ch_b => i_left_ch_b,
            i_pb => i_left_pb,
            o_count => s_x
        );

    encoder_y : entity work.encoder
        generic map (max_count => V_RES)
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            i_ch_a => i_right_ch_a,
            i_ch_b => i_right_ch_b,
            i_pb => i_right_pb,
            o_count => s_y
        );

    
    hdmi_config0 : component I2C_HDMI_Config
        port map (
            iCLK => i_clk_50,
            iRST_N => i_rst_n,
            I2C_SCLK => io_hdmi_i2c_scl,
            I2C_SDAT => io_hdmi_i2c_sda,
            HDMI_TX_INT => i_hdmi_tx_int
        );

   
    process(s_clk_27, s_rst_n)
    begin
        if s_rst_n = '0' then
            s_x_counter_d <= 0;
            s_y_counter_d <= 0;
        elsif rising_edge(s_clk_27) then
            s_x_counter_d <= s_x_counter;
            s_y_counter_d <= s_y_counter;
        end if;
    end process;


    process(s_de, s_x, s_y, s_x_counter_d, s_y_counter_d)
    begin
        s_rgb <= x"000000";
        if (s_de = '1') and (s_x = s_x_counter_d) and (s_y = s_y_counter_d) then
            s_rgb <= x"FFFFFF";
        end if;
    end process;

    o_hdmi_tx_clk <= s_clk_27;
    o_hdmi_tx_d   <= s_rgb;
    o_hdmi_tx_de  <= s_de;
    o_hdmi_tx_hs  <= s_hs;
    o_hdmi_tx_vs  <= s_vs;

    o_leds <= (others => '0');
    o_de10_leds <= (others => '0');
end architecture rtl;
