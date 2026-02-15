library std;
    use std.standard.all;
    use std.textio.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.fixed_pkg.all;
    use ieee.math_real.all;

entity tb_writing_master is
end entity;

architecture behavior of tb_writing_master is

    constant CLK_PERIOD : time := 20 ns;

    -- component declaration
    component writing_master is
        port (
            clk   : in std_logic;
            reset : in std_logic;
            addr  : in std_logic_vector(6 downto 0);
            data  : in std_logic_vector(7 downto 0);
            valid : in std_logic;
            sda   : inout std_logic;
            scl   : out std_logic
        );
    end component;

    -- test bench signals
    signal clk_ext   : std_logic := '0';
    signal reset_ext : std_logic := '0';
    signal addr_ext  : std_logic_vector(6 downto 0) := (others => '0');
    signal data_ext  : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_ext : std_logic := '0';
    signal sda_ext   : std_logic;
    signal scl_ext   : std_logic;
    signal testing   : boolean := true;

    begin
        i_DUT: writing_master
            port map (
                clk => clk_ext,
                reset => reset_ext,
                addr => addr_ext,
                data => data_ext,
                valid => valid_ext,
                sda => sda_ext,
                scl => scl_ext
            );

        clk_ext <= not clk_ext after CLK_PERIOD/2 when testing else '0';

        p_STIMULUS: process 
        begin
            -- 1. Reset device
            reset_ext <= '0';
            wait for CLK_PERIOD;
            reset_ext <= '1';
            wait until rising_edge(clk_ext);

            -- 2. Send data, addr and setting valid to 1
            addr_ext <= "1010101";
            data_ext <= "11001100";
            valid_ext <= '1';

            -- 3. Release valid
            wait for CLK_PERIOD;
            valid_ext <= '0';

            -- 4. Wait for START condition (SDA goes low while SCL is high)
            wait until falling_edge(sda_ext) and scl_ext = '1';

            -- 5. Verify the 7 Address bits (MSB first: index 6 down to 0)
            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;

            -- 6. Verify the R/W bit (Write = '0')
            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;

            -- 7. Wait for the master to release the bus for the ACK phase
            wait until sda_ext = 'Z';
    
            -- 8. Send the ACK
            sda_ext <= '0';
            wait for 32 * CLK_PERIOD;
            sda_ext <= 'Z';

            -- 9. Receive data
            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;

            -- 10. Wait for the master to release the bus for the ACK phase
            wait until sda_ext = 'Z';

            -- 11. Send the ACK
            sda_ext <= '0';
            wait for 32 * CLK_PERIOD;
            sda_ext <= 'Z';

            -- 12. Wait for STOP condition (SDA goes high while SCL is high)
            wait until rising_edge(sda_ext) and scl_ext = '1';
            testing <= false;
            wait;
        end process;
end architecture;