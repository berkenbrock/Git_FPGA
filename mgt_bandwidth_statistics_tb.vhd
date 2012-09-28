library ieee;
use ieee.std_logic_1164.all;

use work.mgt_statistics_package.all;

entity mgt_bandwidth_statistics_tb is
end mgt_bandwidth_statistics_tb;

architecture behavioral of mgt_bandwidth_statistics_tb is
    -- CONSTANTS
    constant CLK_TIMEPERIOD  : time     := 8 ns; 
    constant TIMEFRAME_NBITS : integer  := 32;
    constant BANDWIDTH_NBITS : integer  := 32;
    
    -- COMPONENTS
    component mgt_bandwidth_statistics is
    generic
    (
        TIMEFRAME_NBITS : integer := TIMEFRAME_NBITS;
        BANDWIDTH_NBITS : integer := BANDWIDTH_NBITS
    );
    port
    (
        clk             : in    std_logic;
        rst             : in    std_logic;
        opmode          : in    std_logic_vector(1 downto 0);
        timeframe       : in    std_logic_vector((TIMEFRAME_NBITS-1) downto 0);
        nbytes          : in    std_logic_vector(1 downto 0);
        trigger         : in    std_logic;
        bandwidth       : out   std_logic_vector((BANDWIDTH_NBITS-1) downto 0)
    );
    end component;

    -- SIGNALS
    signal clk              : std_logic;
    signal rst              : std_logic;
    signal opmode           : std_logic_vector(1 downto 0);
    signal timeframe        : std_logic_vector((TIMEFRAME_NBITS-1) downto 0);
    signal nbytes           : std_logic_vector(1 downto 0);
    signal trigger          : std_logic;
    signal bandwidth        : std_logic_vector((BANDWIDTH_NBITS-1) downto 0);
    
begin
    -- Instantiations
    mgt_bandwidth_statistics_inst: mgt_bandwidth_statistics
    port map
    (
        clk => clk,
        rst => rst,
        opmode => opmode,
        timeframe => timeframe,
        nbytes => nbytes,
        trigger => trigger,
        bandwidth => bandwidth
    );

    -- Clock generation
    process
    begin
        clk <= '0';
        wait for CLK_TIMEPERIOD/2;
        clk <= '1';
        wait for CLK_TIMEPERIOD/2;
    end process;
    
    -- Stimuli
    process
    begin
        opmode <= "00";
        rst <= '1';
        timeframe <= X"00000014";
        nbytes <= "00";
        trigger <= '0';
        
        wait for 2*CLK_TIMEPERIOD;
        rst <= '0';
        wait for 10*CLK_TIMEPERIOD;
        
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 5*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 100*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 4*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 1*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 6*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 9*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 22*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 17*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 10*CLK_TIMEPERIOD;
        
        timeframe <= X"00000005";
        wait for 10*CLK_TIMEPERIOD;
        
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 5*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 1*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 4*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 1*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 6*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 9*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 22*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 17*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 40*CLK_TIMEPERIOD;

        timeframe <= X"00000014";
        wait for CLK_TIMEPERIOD;
        opmode <= "01";
        wait for 10*CLK_TIMEPERIOD;
        
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "10";
        trigger <= '1';
        wait for 5*CLK_TIMEPERIOD;
        nbytes <= "10";
        trigger <= '0';
        wait for 8*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 4*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 1*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 6*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 9*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 22*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 17*CLK_TIMEPERIOD;
        nbytes <= "00";

        wait for 2*CLK_TIMEPERIOD;
        timeframe <= X"00000022";
        wait for 2*CLK_TIMEPERIOD;
        nbytes <= "10";
        trigger <= '1';
        wait for 3*CLK_TIMEPERIOD;
        nbytes <= "10";
        trigger <= '0';
        wait for 4*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 1*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 6*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 9*CLK_TIMEPERIOD;
        nbytes <= "00";
        wait for 22*CLK_TIMEPERIOD;
        nbytes <= "10";
        wait for 17*CLK_TIMEPERIOD;
        nbytes <= "00";        
        wait;    
    end process;
    
end behavioral;


