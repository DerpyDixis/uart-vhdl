library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : positive := 10
    );
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        start : in  std_logic;
        data  : in  std_logic_vector(7 downto 0);
        tx    : out std_logic;
        busy  : out std_logic;
        done  : out std_logic
    );
end entity;

architecture rtl of uart_tx is
    type state_t is (S_IDLE, S_START, S_DATA, S_STOP);

    signal state       : state_t := S_IDLE;
    signal data_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal clock_count : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_index   : integer range 0 to 7 := 0;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= S_IDLE;
                data_reg    <= (others => '0');
                clock_count <= 0;
                bit_index   <= 0;
                tx          <= '1';
                busy        <= '0';
                done        <= '0';

            else
                done <= '0';

                case state is
                    when S_IDLE =>
                        tx   <= '1';
                        busy <= '0';

                        if start = '1' then
                            data_reg    <= data;
                            clock_count <= 0;
                            bit_index   <= 0;
                            tx          <= '0';
                            busy        <= '1';
                            state       <= S_START;
                        end if;

                    when S_START =>
                        if clock_count = CLKS_PER_BIT - 1 then
                            clock_count <= 0;
                            tx          <= data_reg(0);
                            state       <= S_DATA;
                        else
                            clock_count <= clock_count + 1;
                        end if;

                    when S_DATA =>
                        if clock_count = CLKS_PER_BIT - 1 then
                            clock_count <= 0;

                            if bit_index = 7 then
                                tx    <= '1';
                                state <= S_STOP;
                            else
                                bit_index <= bit_index + 1;
                                tx        <= data_reg(bit_index + 1);
                            end if;
                        else
                            clock_count <= clock_count + 1;
                        end if;

                    when S_STOP =>
                        if clock_count = CLKS_PER_BIT - 1 then
                            clock_count <= 0;
                            busy        <= '0';
                            done        <= '1';
                            state       <= S_IDLE;
                        else
                            clock_count <= clock_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture;