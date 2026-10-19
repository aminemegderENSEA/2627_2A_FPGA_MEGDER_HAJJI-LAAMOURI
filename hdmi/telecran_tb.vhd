library ieee;
use ieee.std_logic_1164.all;


entity pll is
    port (
        refclk   : in std_logic;
        rst      : in std_logic;
        outclk_0 : out std_logic;
        locked   : out std_logic
    );
end entity pll;

architecture simulation of pll is
begin
    
    outclk_0 <= refclk;
    process
    begin
        locked <= '0';
        wait until rst = '0';
        for k in 1 to 8 loop
            wait until rising_edge(refclk);
        end loop;
        locked <= '1';
        wait until rst = '1';
    end process;
end architecture simulation;

library ieee;
use ieee.std_logic_1164.all;

entity I2C_HDMI_Config is
    port (
        iCLK        : in std_logic;
        iRST_N      : in std_logic;
        I2C_SCLK    : out std_logic;
        I2C_SDAT    : inout std_logic;
        HDMI_TX_INT : in std_logic
    );
end entity I2C_HDMI_Config;

architecture simulation of I2C_HDMI_Config is
begin
   
    I2C_SCLK <= '1';
    I2C_SDAT <= 'Z';
end architecture simulation;

library ieee;
use ieee.std_logic_1164.all;

entity telecran_tb is
end entity telecran_tb;

architecture sim of telecran_tb is
    constant CLK_PERIOD : time := 20 ns;
    signal clk50 : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal i2c_scl, i2c_sda : std_logic := 'Z';
    signal hdmi_clk, hdmi_de, hdmi_hs, hdmi_vs : std_logic;
    signal hdmi_d : std_logic_vector(23 downto 0);
    signal hdmi_int : std_logic := '0';
    signal leds : std_logic_vector(9 downto 0);
    signal de10_leds : std_logic_vector(7 downto 0);
    signal la, lb, lpb, ra, rb, rpb : std_logic := '0';
    signal saw_de      : std_logic := '0';
    signal saw_hs_low  : std_logic := '0';
    signal saw_vs_low  : std_logic := '0';
begin
    clk50 <= not clk50 after CLK_PERIOD / 2;

    dut : entity work.telecran
        port map (
            i_clk_50 => clk50,
            io_hdmi_i2c_scl => i2c_scl,
            io_hdmi_i2c_sda => i2c_sda,
            o_hdmi_tx_clk => hdmi_clk,
            o_hdmi_tx_d => hdmi_d,
            o_hdmi_tx_de => hdmi_de,
            o_hdmi_tx_hs => hdmi_hs,
            i_hdmi_tx_int => hdmi_int,
            o_hdmi_tx_vs => hdmi_vs,
            i_rst_n => rst_n,
            o_leds => leds,
            o_de10_leds => de10_leds,
            i_left_ch_a => la,
            i_left_ch_b => lb,
            i_left_pb => lpb,
            i_right_ch_a => ra,
            i_right_ch_b => rb,
            i_right_pb => rpb
        );

   
    monitor_video : process
    begin
        loop
            wait on hdmi_de, hdmi_hs, hdmi_vs;
            if hdmi_de = '1' then
                saw_de <= '1';
            end if;
            if hdmi_hs = '0' then
                saw_hs_low <= '1';
            end if;
            if hdmi_vs = '0' then
                saw_vs_low <= '1';
            end if;
        end loop;
    end process;

    stimulus : process
    begin
      
        lpb <= '1';
        rpb <= '1';
        rst_n <= '0';
        wait for 200 ns;
        rst_n <= '1';

        
        wait for 2 us;
        la <= '1'; wait for 300 ns;
        lb <= '1'; wait for 300 ns;
        la <= '0'; wait for 300 ns;
        lb <= '0'; wait for 300 ns;

      
        ra <= '1'; wait for 300 ns;
        rb <= '1'; wait for 300 ns;
        ra <= '0'; wait for 300 ns;
        rb <= '0'; wait for 300 ns;


        wait for 1 ms;
        assert saw_hs_low = '1'
            report "ECHEC : aucune impulsion basse HS observee" severity error;
        assert saw_vs_low = '1'
            report "ECHEC : aucune impulsion basse VS observee" severity error;
        assert saw_de = '1'
            report "ECHEC : la zone active DE n'a pas ete atteinte pendant le test" severity error;

        assert (hdmi_clk = '0') or (hdmi_clk = '1')
            report "ECHEC : horloge HDMI inconnue" severity error;
        assert (hdmi_d = x"000000") or (hdmi_d = x"FFFFFF")
            report "ECHEC : les donnees RGB ne sont ni noires ni blanches" severity error;

        report "SUCCES : balayage video HS/VS/DE observe dans le banc de test" severity note;
        wait;
    end process;
end architecture sim;
