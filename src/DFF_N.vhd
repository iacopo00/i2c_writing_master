library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DFF_N is
    generic(
        N: positive
    );
    port(
        clk      : in std_logic;
        reset    : in std_logic;
        di       : in std_logic_vector (N-1 downto 0);
        do       : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture rtl of DFF_N is 

begin
    p_DFF: process(clk, reset)
    begin
        if (reset = '0') then
            do <= (others => '0');
        elsif rising_edge(clk) then
                do <= di;
            end if;
    end process;

end architecture;