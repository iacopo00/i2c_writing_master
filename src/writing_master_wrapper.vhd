library ieee;
use ieee.std_logic_1164.all;

entity writing_master_wrapper is
    port (
        clk : in std_logic;
        reset : in std_logic;
        addr : in std_logic_vector(6 downto 0);
        data : in std_logic_vector(7 downto 0);
        valid : in std_logic;
        sda : inout std_logic;
        scl : out std_logic
    );
end entity;

architecture structural of writing_master_wrapper is

    component writing_master is
        port (
            clk : in std_logic;
            reset : in std_logic;
            addr : in std_logic_vector(6 downto 0);
            data : in std_logic_vector(7 downto 0);
            valid : in std_logic;
            sda_in : in std_logic;
            sda_out : out std_logic;
            sda_en : out std_logic;
            scl : out std_logic
        );
    end component;

    -- valid and scl FF
    component DFF is
    port(
        clk      : in std_logic;
        reset   : in std_logic;
        di       : in std_logic;
        do       : out std_logic
    );
    end component;

    -- addr and data FF
    component DFF_N is
    generic(
        N: positive
    );
    port(
        clk      : in std_logic;
        reset   : in std_logic;
        di       : in std_logic_vector (N-1 downto 0);
        do       : out std_logic_vector(N-1 downto 0)
    );
    end component;

    signal valid_reg : std_logic;
    signal addr_reg : std_logic_vector(6 downto 0);
    signal data_reg : std_logic_vector(7 downto 0);
    signal scl_master_out : std_logic;
    signal sda_out_from_master : std_logic;
    signal sda_en_from_master  : std_logic;
    signal sda_in_to_master    : std_logic;
    signal sda_out_reg : std_logic;
    signal sda_en_reg  : std_logic;

begin

    reg_valid: DFF
    port map(
        clk => clk,
        reset => reset,
        di => valid,
        do => valid_reg
    );

    reg_addr: DFF_N 
    generic map(
        N => 7
    )
    port map(
        clk => clk,
        reset => reset,
        di => addr,
        do => addr_reg 
    );

    reg_data: DFF_N 
    generic map(
        N => 8
    )
    port map(
        clk => clk,
        reset => reset,
        di => data,
        do => data_reg
    );

    reg_scl: DFF
    port map(
        clk => clk,
        reset => reset,
        di => scl_master_out,
        do => scl
    );

    reg_sda_in: DFF
    port map(
        clk => clk, 
        reset => reset,
        di => sda,
        do => sda_in_to_master
    );

    reg_sda_out: DFF
    port map(
        clk => clk,
        reset => reset,
        di => sda_out_from_master,
        do => sda_out_reg
    );

    reg_sda_en: DFF
    port map(
        clk => clk,
        reset => reset,
        di => sda_en_from_master,
        do => sda_en_reg
    );

    sda <= sda_out_reg when (sda_en_reg = '1') else 'Z';
    
    UUT: writing_master
    port map (
        clk => clk,
        reset => reset,
        addr => addr_reg,
        data => data_reg,
        valid => valid_reg,
        sda_in  => sda_in_to_master,
        sda_out => sda_out_from_master,
        sda_en  => sda_en_from_master,
        scl => scl_master_out
    );

end architecture;