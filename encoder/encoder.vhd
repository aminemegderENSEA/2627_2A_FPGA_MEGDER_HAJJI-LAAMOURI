library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Decodeur d'encodeur rotatif en quadrature.
-- Les entrees A et B sont synchronisees sur i_clk.
-- Le comptage suit les conditions du TP :
--   increment : front montant de A avec B='0', ou front descendant de A avec B='1'
--   decrement : front montant de B avec A='0', ou front descendant de B avec A='1'
-- i_rst_n et i_pb sont actifs a l'etat bas.
entity encoder is
    generic (
        max_count : positive := 10
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        i_ch_a  : in  std_logic;
        i_ch_b  : in  std_logic;
        i_pb    : in  std_logic;
        o_count : out natural range 0 to max_count - 1
    );
end entity encoder;

architecture rtl of encoder is
    signal a_meta    : std_logic := '0';
    signal a_sync    : std_logic := '0';
    signal b_meta    : std_logic := '0';
    signal b_sync    : std_logic := '0';
    signal a_prev    : std_logic := '0';
    signal b_prev    : std_logic := '0';
    signal count_reg : natural range 0 to max_count - 1 := 0;
begin
    o_count <= count_reg;

    process(i_clk, i_rst_n)
        variable increment_v : boolean;
        variable decrement_v : boolean;
    begin
        if i_rst_n = '0' then
            a_meta    <= '0';
            a_sync    <= '0';
            b_meta    <= '0';
            b_sync    <= '0';
            a_prev    <= '0';
            b_prev    <= '0';
            count_reg <= 0;
        elsif rising_edge(i_clk) then
            -- Synchronise les entrees asynchrones sur l'horloge FPGA.
            a_meta <= i_ch_a;
            a_sync <= a_meta;
            b_meta <= i_ch_b;
            b_sync <= b_meta;

            if i_pb = '0' then
                count_reg <= 0;
                -- Evite de compter une transition survenue pendant le bouton.
                a_prev <= a_sync;
                b_prev <= b_sync;
            else
                increment_v := false;
                decrement_v := false;

                -- Voie A : seuls les fronts indiques dans le sujet incrementent.
                if (a_sync /= a_prev) and (b_sync = b_prev) then
                    if ((a_prev = '0') and (a_sync = '1') and (b_sync = '0')) or
                       ((a_prev = '1') and (a_sync = '0') and (b_sync = '1')) then
                        increment_v := true;
                    end if;
                -- Voie B : seuls les fronts indiques dans le sujet decrementent.
                elsif (b_sync /= b_prev) and (a_sync = a_prev) then
                    if ((b_prev = '0') and (b_sync = '1') and (a_sync = '0')) or
                       ((b_prev = '1') and (b_sync = '0') and (a_sync = '1')) then
                        decrement_v := true;
                    end if;
                end if;

                if increment_v then
                    if count_reg < max_count - 1 then
                        count_reg <= count_reg + 1;
                    end if;
                elsif decrement_v then
                    if count_reg > 0 then
                        count_reg <= count_reg - 1;
                    end if;
                end if;

                -- Met a jour l'etat precedent apres la detection des fronts.
                a_prev <= a_sync;
                b_prev <= b_sync;
            end if;
        end if;
    end process;
end architecture rtl;
