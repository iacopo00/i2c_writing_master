library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DFF is
    port(
        clk      : in std_logic;
        reset    : in std_logic;
        di       : in std_logic;
        do       : out std_logic
    );
end entity;

architecture rtl of DFF is 

begin
    p_DFF: process(clk, reset)
    begin
        if (reset = '0') then
            do <= '0';
        elsif rising_edge(clk) then
                do <= di;
            end if;
    end process;

end architecture;