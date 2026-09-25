library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : positive := 10
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        rx            : in  std_logic;
        data          : out std_logic_vector(7 downto 0);
        data_valid    : out std_logic;
        framing_error : out std_logic
    );
end entity;

architecture rtl of uart_rx is
    constant HALF_BIT : natural := CLKS_PER_BIT / 2;

    type state_t is (
        S_IDLE,
        S_START,
        S_DATA,
        S_STOP,
        S_RECOVER
    );

    signal state       : state_t := S_IDLE;
    signal rx_meta     : std_logic := '1';
    signal rx_sync     : std_logic := '1';
    signal data_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal clock_count : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index   : integer range 0 to 7 := 0;
begin
    assert CLKS_PER_BIT >= 4
        report "uart_rx requires CLKS_PER_BIT >= 4"
        severity failure;

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state         <= S_IDLE;
                rx_meta       <= '1';
                rx_sync       <= '1';
                data_reg      <= (others => '0');
                clock_count   <= 0;
                bit_index     <= 0;
                data          <= (others => '0');
                data_valid    <= '0';
                framing_error <= '0';

            else
                rx_meta <= rx;
                rx_sync <= rx_meta;

                data_valid    <= '0';
                framing_error <= '0';

                case state is
                    when S_IDLE =>
                        clock_count <= 0;
                        bit_index   <= 0;

                        if rx_sync = '0' then
                            state <= S_START;
                        end if;

                    when S_START =>
                        if clock_count = HALF_BIT - 1 then
                            clock_count <= 0;

                            if rx_sync = '0' then
                                state <= S_DATA;
                            else
                                state <= S_IDLE;
                            end if;
                        else
                            clock_count <= clock_count + 1;
                        end if;

                    when S_DATA =>
                        if clock_count = CLKS_PER_BIT - 1 then
                            clock_count         <= 0;
                            data_reg(bit_index) <= rx_sync;

                            if bit_index = 7 then
                                state <= S_STOP;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            clock_count <= clock_count + 1;
                        end if;

                    when S_STOP =>
                        if clock_count = CLKS_PER_BIT - 1 then
                            clock_count <= 0;

                            if rx_sync = '1' then
                                data       <= data_reg;
                                data_valid <= '1';
                                state      <= S_IDLE;
                            else
                                framing_error <= '1';
                                state         <= S_RECOVER;
                            end if;
                        else
                            clock_count <= clock_count + 1;
                        end if;

                    when S_RECOVER =>
                        if rx_sync = '1' then
                            state <= S_IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture;