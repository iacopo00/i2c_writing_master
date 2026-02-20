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

    constant CLK_PERIOD : time := 8 ns;

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
    signal sda_ext   : std_logic := 'Z';
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
            -- ONE MESSAGE SCENARIO --
            -- 1. Reset device
            reset_ext <= '0';
            wait for CLK_PERIOD;
            reset_ext <= '1';

            -- 2. Set data, addr and setting valid to 1
            addr_ext <= "1010101";
            data_ext <= "11001100";
            valid_ext <= '1';
            wait until falling_edge(clk_ext);
            -- 3. Release valid
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
    
            -- 8. Send the ACK waiting enough time to be sure master received it
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            -- 9. Receive data
            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;

            -- 10. Wait for the master to release the bus for the ACK phase
            wait until sda_ext = 'Z';

            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            -- 11. Wait for STOP condition
            wait until rising_edge(sda_ext) and scl_ext = '1';
            report "One message scenario completed!";

            -- MULTIPLE MESSAGES SCENARIO --
            -- Same until point 10
            wait for 8 * CLK_PERIOD;
            addr_ext <= "1101010";
            data_ext <= "00110011";
            valid_ext <= '1';

            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';
            
            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;


            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;

            wait until sda_ext = 'Z';
    
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;

            wait until sda_ext = 'Z';

            -- Prepare data to transmit
            addr_ext <= "1101010";
            data_ext <= "10001011";
            valid_ext <= '1';

            sda_ext <= '0';
            wait until rising_edge(scl_ext);
            sda_ext <= 'Z';

            -- Second START
            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';

            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;


            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;


            wait until sda_ext = 'Z';
    
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;


            wait until sda_ext = 'Z';
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            wait until rising_edge(sda_ext) and scl_ext = '1';

            -- MULTIPLE MESSAGES SCENARIO --
            -- Same until point 10
            wait for 8 * CLK_PERIOD;
            addr_ext <= "1101010";
            data_ext <= "00110011";
            valid_ext <= '1';

            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';
            
            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;


            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;

            wait until sda_ext = 'Z';
    
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;

            wait until sda_ext = 'Z';

            -- Prepare data to transmit
            addr_ext <= "0010011";
            data_ext <= "10001011";
            valid_ext <= '1';

            sda_ext <= '0';
            wait until rising_edge(scl_ext);
            sda_ext <= 'Z';

            -- Second START
            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';

            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;


            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;


            wait until sda_ext = 'Z';
    
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;


            wait until sda_ext = 'Z';
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            wait until rising_edge(sda_ext) and scl_ext = '1';

            report "Multiple messages scenario completed!";

            -- NACK ADDR SCENARIO --
            wait for 8 * CLK_PERIOD;
            addr_ext <= "0110101";
            data_ext <= "11011100";
            valid_ext <= '1';
            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';

            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;

            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;

            wait until sda_ext = 'Z';
    
            sda_ext <= '1'; -- NACK ADDR
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            wait until rising_edge(sda_ext) and scl_ext = '1';
            report "NACK ADDR scenario completed!";

            -- NACK DATA SCENARIO -- 
            wait for 8 * CLK_PERIOD;
            addr_ext <= "0110101";
            data_ext <= "11011100";
            valid_ext <= '1';
            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';

            for i in 6 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = addr_ext(i)) 
                    report "Error: No slaves match!" severity error;
            end loop;

            wait until rising_edge(scl_ext);
            assert (sda_ext = '0') 
                report "Error: R/W bit should be '0' for writing!" severity error;

            wait until sda_ext = 'Z';
    
            sda_ext <= '0';
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            for i in 7 downto 0 loop
                wait until rising_edge(scl_ext);
                assert (sda_ext = data_ext(i)) 
                    report "Error: Wrong data!" severity error;
            end loop;


            wait until sda_ext = 'Z';
            sda_ext <= '1'; -- NACK DATA
            wait until falling_edge(scl_ext);
            sda_ext <= 'Z';

            wait until rising_edge(sda_ext) and scl_ext = '1';
            report "NACK DATA scenario completed!";
            
            valid_ext <= '0';
            addr_ext  <= (others => '0');
            data_ext  <= (others => '0');

            -- ASYNCHRONOUS RESET SCENARIO --
            wait for 8 * CLK_PERIOD;
            addr_ext <= "1010100";
            data_ext <= "11110010";
            valid_ext <= '1';
            wait until falling_edge(sda_ext) and scl_ext = '1';
            valid_ext <= '0';

            for i in 1 to 10 loop
                wait until rising_edge(scl_ext);
            end loop;

            wait for 3 ns;
            reset_ext <= '0'; 

            wait for 1 ns;
            assert (sda_ext = '1' and scl_ext = '1') 
                report "Error: master is not in IDLE state!" severity failure;

            wait for 2 * CLK_PERIOD;
            reset_ext <= '1';

            report "ASYNCHRONOUS SCENARIO COMPLETED";

            valid_ext <= '0';
            addr_ext  <= (others => '0');
            data_ext  <= (others => '0');

            wait until rising_edge(clk_ext);
            wait for 8 * CLK_PERIOD;
            testing <= false;
            wait;
        end process;
end architecture;