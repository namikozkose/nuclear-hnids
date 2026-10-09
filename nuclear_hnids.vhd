library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Proje: Nuclear-HNIDS (Nükleer Reaktör Donanımsal Paket İnceleme Modülü)
-- Hedef: Modbus TCP başlık analizi ve anında donanımsal izolasyon
-- ============================================================================
entity nuclear_hnids is
    Port (
        clk             : in  std_logic;                     -- 100 MHz Sistem Saati (10 ns periyot)
        rst_n           : in  std_logic;                     -- Aktif-düşük asenkron reset
        data_valid      : in  std_logic;                     -- Hatta geçerli veri baytı olduğunu gösteren sinyal
        rx_byte         : in  std_logic_vector(7 downto 0);  -- Fiziksel PHY/MAC katmanından gelen 8-bit veri
        
        -- Donanımsal Güvenlik Çıkışları
        sabotage_alert  : out std_logic;                     -- Kritik nükleer sabotaj alarmı (Latching alarm)
        drop_packet     : out std_logic;                     -- Paketin PLC'ye geçişini engelleyen hat kesici
        byte_index_out  : out std_logic_vector(7 downto 0)   -- Anlık incelenen byte sırası (Gözlem amaçlı)
    );
end nuclear_hnids;

architecture Behavioral of nuclear_hnids is

    type fsm_state is (IDLE, PARSE_MBAP, INSPECT_FUNCTION, PASS_THROUGH, LOCKDOWN);
    signal state : fsm_state := IDLE;

    signal byte_cnt   : unsigned(7 downto 0) := (others => '0');
    signal alert_reg  : std_logic := '0';
    signal drop_reg   : std_logic := '0';

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state        <= IDLE;
            byte_cnt     <= (others => '0');
            alert_reg    <= '0';
            drop_reg     <= '0';
        elsif rising_edge(clk) then
            if data_valid = '1' then
                case state is

                    -- Paket başlangıcı bekleniyor (Byte 0: Transaction ID High)
                    when IDLE =>
                        byte_cnt  <= to_unsigned(1, 8);
                        drop_reg  <= '0';
                        state     <= PARSE_MBAP;

                    -- Modbus MBAP Başlığı Geçiliyor (Byte 1-6)
                    -- Byte 2-3 Protocol ID (0x0000), Byte 4-5 Length, Byte 6 Unit ID
                    when PARSE_MBAP =>
                        byte_cnt <= byte_cnt + 1;
                        if byte_cnt = to_unsigned(6, 8) then
                            -- Sıradaki byte 7. byte (Function Code) olacak
                            state <= INSPECT_FUNCTION;
                        end if;

                    -- Kritik Güvenlik Denetimi (Byte 7: Modbus Function Code)
                    when INSPECT_FUNCTION =>
                        byte_cnt <= byte_cnt + 1;
                        
                        -- 0x05: Write Single Coil (Vana Kapatma/Pompa Durdurma)
                        -- 0x0F: Write Multiple Coils (Toplu Röle Değişimi)
                        if (rx_byte = x"05" or rx_byte = x"0F") then
                            alert_reg <= '1';      -- Donanımsal alarm pinini 1 yap
                            drop_reg  <= '1';      -- Hatta paket geçişini anında engelle
                            state     <= LOCKDOWN; -- Sistemi fiziksel kilitlenmeye sok
                        else
                            -- Masum okuma veya güvenli fonksiyon (0x01, 0x03 vb.)
                            drop_reg <= '0';
                            state    <= PASS_THROUGH;
                        end if;

                    -- Güvenli paket: Kalan byte'ların PLC'ye akmasına izin ver
                    when PASS_THROUGH =>
                        byte_cnt <= byte_cnt + 1;

                    -- Sabotaj algılandı: Paket düşürüldü, kilit devam ediyor
                    when LOCKDOWN =>
                        drop_reg <= '1';
                        -- Bir sonraki pakete veya reset gelene kadar kilitli kalır

                end case;
            end if;
        end if;
    end process;

    -- Çıkış sinyalleri
    sabotage_alert <= alert_reg;
    drop_packet    <= drop_reg;
    byte_index_out <= std_logic_vector(byte_cnt);

end Behavioral;