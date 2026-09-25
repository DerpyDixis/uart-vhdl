library ieee;
use ieee.std_logic_1164.all;

entity uart_loopback is
    generic (
        CLKS_PER_BIT : positive := 10
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        tx_start      : in  std_logic;
        tx_data       : in  std_logic_vector(7 downto 0);
        tx_busy       : out std_logic;
        tx_done       : out std_logic;

        rx_data       : out std_logic_vector(7 downto 0);
        rx_valid      : out std_logic;
        framing_error : out std_logic
    );
end entity;

architecture structural of uart_loopback is
    signal serial_line : std_logic;
begin
    transmitter : entity work.uart_tx
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            clk   => clk,
            reset => reset,
            start => tx_start,
            data  => tx_data,
            tx    => serial_line,
            busy  => tx_busy,
            done  => tx_done
        );

    receiver : entity work.uart_rx
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT
        )
        port map (
            clk           => clk,
            reset         => reset,
            rx            => serial_line,
            data          => rx_data,
            data_valid    => rx_valid,
            framing_error => framing_error
        );
end architecture;