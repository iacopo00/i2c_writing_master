library std;
    use std.standard.all;
    use std.textio.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.fixed_pkg.all;
    use ieee.math_real.all;



entity WritingMaster is
     -- I/O ports definition
    port (
        clk : in std_logic;                         -- system clock signal
        reset : in std_logic;                       -- reset signal
        addr : in std_logic_vector(6 downto 0);     -- slave's address
        data : in std_logic_vector(7 downto 0);     -- writing data
        valid : in std_logic;                       -- input validity signal ('1' or '0')
        sda : inout std_logic;                    -- data line for serial communication between master and slave
        scl : out std_logic                         -- device clock line
    );
end entity

architecture structure of WritingMaster is

    type state_t is (IDLE, START, ADDR, DATA, STOP);
    signal curr_state, next_state : state_t;
    signal scl_count :  unsigned(4 downto 0);               -- counter to set scl to '0' or '1' (32 times slowe than clk)
    signal addr_signal :  std_logic_vector(6 downto 0);     -- set to addr when valid is '1'
    signal data_signal :  std_logic_vector(7 downto 0);     -- set to data when valid is '1'

    -- 1. State memory update
    p_STATE_REG: process(clk, reset)
    begin
        if reset = '0' then
            -- initial state
            curr_state <= IDLE;
            scl_count <= (others => '0');
        elsif rising_edge(clk) then
            -- device clock is 32 times slower than clock, except for IDLE state
            case next_state is
                when IDLE =>
                    if valid = '1' then
                        addr_signal <= addr;
                        data_signal <= data;
                        curr_state <= START;
                    else
                        curr_state <= next_state;
                    end if;
                when others =>
                        if scl_count = 31 then
                            curr_state <= next_state;
                        end if;
                        scl_count <= scl_count + 1;
            end case;
        end if;
    end process;
    
    -- 2. Next state logic process
    p_NEXT_STATE_LOGIC: process(curr_state)
        variable count : integer;
    begin
        -- default
        next_state <= curr_state;

        case curr_state is
            when IDLE => null;
            when START =>
                next_state <= ADDR;
            when ADDR =>
                if (count = 7) and (scl = 0) and (sda = 0) then     -- Slave's address sent and exists (ACK)
                    next_state <= DATA;
                elsif (count != 7) then
                    next_state <= curr_state;
                else
                    -- NACK received, no availabel slave at addr
                    next_state <= STOP;
                end if;
            when DATA => 
                if (count = 8) and (scl = 0) and (sda = 0) then     -- Slave's address sent and exists (ACK)
                    next_state <= STOP;
                else
                    next_state <= curr_state;
                end if;
            when STOP =>
                next_state <= IDLE;
        end case;


                
                
    end process;
    
    -- 3. Output logic
    p_OUTPUT_LOGIC: process(curr_state)
    variable byte_sent : integer;
    begin
        -- default ('0' with counter < 16)
        scl <= scl_count(4);

        case curr_state is
            when IDLE =>
                scl <= '1';
                sda <= '1';     
            when START =>       -- send start bit (sda = 0 and scl = 1)
                scl <= '1';
                sda <= '0';
            when ADDR =>
                if (byte_sent < 7) and (scl = '1') then
                    sda <= addr(byte_sent);
                    byte_sent := byte_sent + 1;
                elsif byte_sent >= 7 then
                    sda <= 'Z';                        -- free sda to receive ACK
                    scl <= '0';
                    byte_sent := 0;
                else
                    sda <= sda;
                end if;
            when DATA =>
                if byte_sent < 8 then
                    case scl is 
                        when '1' => 
                            sda <= data(byte_sent);
                            byte_sent <= byte_sent + 1;
                        when '0' =>
                            sda <= sda;
                    end case;
                else
                    if (scl = '0') and (sda = '0') then     -- ACK received
                        byte_sent := 0;
                    else
                        sda <= 'Z';                         -- free sda to receive ACK
                        scl <= '0';
                    end if;
                end if;
            when STOP =>
                scl <= '1';
                sda <= '1';
        end case;
    end process;

end architecture;