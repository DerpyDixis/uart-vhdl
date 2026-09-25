library ieee;
use ieee.std_logic_1164.all;

entity pulse_every_four is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        pulse : out std_logic
    );
end entity;

architecture rtl of pulse_every_four is
    signal count : integer range 0 to 3 := 0;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count <= 0;
                pulse <= '0';
            elsif count = 3 then
                count <= 0;
                pulse <= '1';
            else
                count <= count + 1;
                pulse <= '0';
            end if;
        end if;
    end process;
end architecture;