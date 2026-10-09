library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_nuclear_hnids is
end tb_nuclear_hnids;

architecture Simulation of tb_nuclear_hnids is

    signal clk             : std_logic := '0';
    signal rst_n           : std_logic := '0';
    signal data_valid      : std_logic := '0';
    signal rx_byte         : std_logic_vector(7 downto 0) := (others => '0');
    signal sabotage_alert  : std_logic;
    signal drop_packet     : std_logic;
    signal byte_index_out  : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz saat frekansı

    -- Python saldırımızdaki Modbus sabotaj paketi:
    -- 00 01 (Trans ID) 00 00 (Proto) 00 06 (Len) 01 (Unit) 05 (SABOTAJ) 00 00 FF 00
    type byte_stream is array (0 to 11) of std_logic_vector(7 downto 0);
    constant SABOTAGE_FRAME : byte_stream := (
        x"00", x"01", x"00", x"00", x"00", x"06", x"01", 
        x"05", -- İndeks 7: Write Single Coil (Kritik Komut)
        x"00", x"00", x"FF", x"00"
    );

begin

    -- UUT (Unit Under Test) Bağlantısı
    uut: entity work.nuclear_hnids
        port map (
            clk            => clk,
            rst_n          => rst_n,
            data_valid     => data_valid,
            rx_byte        => rx_byte,
            sabotage_alert => sabotage_alert,
            drop_packet    => drop_packet,
            byte_index_out => byte_index_out
        );

    -- 100 MHz Saat Sinyali
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Test Senaryosu
    stim_proc: process
    begin
        -- Donanımı Sıfırla
        rst_n <= '0';
        wait for 25 ns;
        rst_n <= '1';
        wait for 20 ns;

        -- Paketi hatta bayt bayt bas (100 MHz saat ile senkron)
        for i in 0 to 11 loop
            rx_byte    <= SABOTAGE_FRAME(i);
            data_valid <= '1';
            wait for CLK_PERIOD;
            data_valid <= '0';
            wait for CLK_PERIOD; -- Baytlar arası 1 çevrim boşluk
        end loop;

        -- Sonucu gözlemlemek için bekle
        wait for 100 ns;
        wait;
    end process;

end Simulation;