library std;
    use std.standard.all;
    use std.textio.all;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.fixed_pkg.all;
    use ieee.math_real.all;



entity writing_master is
     -- I/O ports definition
    port (
        clk : in std_logic;                         -- system clock signal
        reset : in std_logic;                       -- reset signal
        addr : in std_logic_vector(6 downto 0);     -- slave's address
        data : in std_logic_vector(7 downto 0);     -- writing data
        valid : in std_logic;                       -- input validity signal ('1' or '0')
        sda : inout std_logic;                      -- data line for serial communication between master and slave
        scl : out std_logic                         -- device clock line
    );
end entity;

architecture structure of writing_master is

    type state_t is (IDLE, START, ADDR_STATE, ACK_ADDR, DATA_STATE, ACK_DATA, STOP);
    signal curr_state, next_state : state_t;
    signal scl_count :  unsigned(4 downto 0);               -- counter to set scl to '0' or '1' (32 times slowe than clk)
    signal bit_count :  unsigned(3 downto 0);               -- index of the next bit to send (MSB first), max 9 (8 bit data + ACK)
    signal addr_signal :  std_logic_vector(6 downto 0);     -- set to addr when valid is '1'
    signal data_signal :  std_logic_vector(7 downto 0);     -- set to data when valid is '1'
    signal scl_signal : std_logic;                          -- used to read/set scl signal without error
    signal sda_signal : std_logic;                          -- used to read/set sda signal without error

begin
    scl <= scl_signal;
    sda <= sda_signal;

    -- 1. State memory update
    p_STATE_REG: process(clk, reset)
    begin
        if reset = '0' then
            -- initial state
            curr_state <= IDLE;
            scl_count <= (others => '0');
            bit_count <= (others => '0');
        elsif rising_edge(clk) then
            -- device clock is 32 times slower than clock, except for IDLE state
            curr_state <= next_state;
            scl_count <= scl_count + 1;

            case curr_state is
                when IDLE =>
                    scl_count <= (others => '0');
                    bit_count <= (others => '0');

                    if valid = '1' then
                        addr_signal <= addr;
                        data_signal <= data;
                    end if;
                when ADDR_STATE | DATA_STATE =>
                    if scl_count = 31 then
                        bit_count <= bit_count + 1;
                    end if;
                when ACK_ADDR =>
                    bit_count <= (others => '0');
                when ACK_DATA =>
                    bit_count <= (others => '0');
                    if (scl_count = 31) and (valid = '1') then 
                        addr_signal <= addr;
                        data_signal <= data;
                    end if;
                when others => null;
            end case;
        end if;
    end process;
    
    -- 2. Next state logic process
    p_NEXT_STATE_LOGIC: process(curr_state, valid, scl_count, bit_count, sda)
    begin
        next_state <= curr_state;
        case curr_state is
            when IDLE =>
                if valid = '1' then
                    next_state <= START;
                end if;
            when START =>
                if scl_count = 31 then
                    next_state <= ADDR_STATE;
                end if;
            when ADDR_STATE => 
                if (scl_count = 31) and (bit_count = 7) then
                    next_state <= ACK_ADDR;
                end if;
            when ACK_ADDR =>
                -- ACK signal is sda low 
                if scl_count = 31 then
                    if sda = '0' then
                        next_state <= DATA_STATE;
                    else
                        next_state <= STOP;
                    end if;
                end if;
            when DATA_STATE =>
                if (scl_count = 31) and (bit_count = 7) then
                    next_state <= ACK_DATA;
                end if;
            when ACK_DATA =>
                if scl_count = 31 then
                    if sda = '0' then
                        if valid = '1' then
                            next_state <= START;
                        else
                            next_state <= STOP;
                        end if;
                    else
                        next_state <= STOP;
                    end if;
                end if;
            when STOP => 
                if scl_count = 31 then
                    next_state <= IDLE;
                end if;
        end case;
    end process;
    
    -- 3. Output logic
    p_OUTPUT_LOGIC: process(curr_state, scl_count, bit_count)
    begin
        -- default ('0' with counter < 16, '1' >= 16)
        scl_signal <= scl_count(4);
        sda_signal <= '1';

        case curr_state is
            when IDLE =>
                scl_signal <= '1';
                sda_signal <= '1';
            when START =>
                scl_signal <= '1';
                if scl_count < 16 then
                    sda_signal <= '1';
                else
                    -- START signal with scl high and high to low transition of sda
                    sda_signal <= '0';
                end if;
            when ADDR_STATE =>
                if bit_count < 7 then
                    -- MSB first order
                    sda_signal <= addr_signal(6 - to_integer(bit_count));
                else
                    -- send write (W) command
                    sda_signal <= '0';
                end if;
            when ACK_ADDR | ACK_DATA =>
                sda_signal <= 'Z';
            when DATA_STATE =>
                sda_signal <= data_signal(7 - to_integer(bit_count));
            when STOP =>
                -- wait a little more to avoid a new START transition 
                if scl_count < 24 then
                    sda_signal <= '0';
                else
                    -- STOP signal with scl high and low to high transition of sda
                    sda_signal <= '1';
                end if;
        end case;
    end process;

end architecture;