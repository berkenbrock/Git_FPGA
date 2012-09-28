 library ieee;
use ieee.std_logic_1164.all;

package mgt_statistics_package is

    component mgt_loopback_statistics is
    port
    (
        clk	                    : in    std_logic;
        rst                     : in    std_logic;
        en_seqgen               : in    std_logic;
        en_error_counter        : in    std_logic;
        seq_rcv                 : in    std_logic_vector(15 downto  0);
        seq_snd                 : out   std_logic_vector(15 downto  0);
        error_count             : out   std_logic_vector(31 downto  0);
        lossofsync              : in    std_logic;
        lossofsync_count        : out   std_logic_vector(31 downto  0);
        latency                 : out   std_logic_vector(15 downto  0)        
    );
    end component;

    component mgt_bandwidth_statistics is
    generic
    (
        TIMEFRAME_NBITS : integer := 32;
        BANDWIDTH_NBITS : integer := 32
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

end mgt_statistics_package;

use work.mgt_statistics_package.all;

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mgt_loopback_statistics is
port
(
    clk	                    : in    std_logic;
    rst                     : in    std_logic;
    en_seqgen               : in    std_logic;
    en_error_counter        : in    std_logic;
    seq_rcv                 : in    std_logic_vector(15 downto  0);
    seq_snd                 : out   std_logic_vector(15 downto  0);
    lossofsync              : in    std_logic;
    error_count             : out   std_logic_vector(31 downto  0);
    lossofsync_count        : out   std_logic_vector(31 downto  0);
    latency                 : out   std_logic_vector(15 downto  0)
);
end mgt_loopback_statistics;

architecture behavioral of mgt_loopback_statistics is
    signal s_seq_number         : unsigned(seq_snd'range);
    signal s_seq_rcv_reg0       : unsigned(seq_rcv'range);
    signal s_diff_seq_number    : unsigned(seq_rcv'range);

    signal s_error_count        : unsigned(error_count'range);

    signal s_lossofsync_count   : unsigned(lossofsync_count'range);
    signal s_lossofsync_reg0    : std_logic;
    
begin
    -- Sequence number generator
    process (clk) 
    begin
        if clk'event and clk = '1' then
            if rst = '1' then 
                s_seq_number <= (others => '0');
            else
                if en_error_counter = '1' then
                    s_seq_number <= s_seq_number + 1;
                end if;
            end if;
        end if;
    end process;
    
    seq_snd <= std_logic_vector(s_seq_number);

    -- Registered seq_rcv
    process (clk)
    begin
       if clk'event and clk = '1' then  
          s_seq_rcv_reg0 <= unsigned(seq_rcv);
       end if;
    end process;

    -- Error counter - increments when successive data has not consecutive sequence numbers
    process (clk) 
    begin
        if clk'event and clk = '1' then
            s_diff_seq_number <= unsigned(seq_rcv) - s_seq_rcv_reg0;
            
            if rst = '1' then 
                s_error_count <= (others => '0');
            elsif s_diff_seq_number /= 1 then
                if en_seqgen = '1' then
                    s_error_count <= s_error_count + 1;
                end if;
            end if;
        end if;
    end process;
    
    error_count <= std_logic_vector(s_error_count);

    -- Loss of sync counter - increments on each rising edge of the MGT's loss of sync
    process (clk) 
    begin
        if clk'event and clk = '1' then
            if rst = '1' then 
                s_lossofsync_count <= (others => '0');
            elsif lossofsync = '1' and s_lossofsync_reg0 = '0' then
                s_lossofsync_count <= s_lossofsync_count + 1;
            end if;
            s_lossofsync_reg0 <= lossofsync;
        end if;
    end process;
    
    lossofsync_count <= std_logic_vector(s_lossofsync_count);
    
    
    -- Latency calculation
    process (clk) 
    begin
        if clk'event and clk = '1' then    
            latency <= std_logic_vector(s_seq_number - unsigned(seq_rcv));
        end if;
    end process;
    
end behavioral;



---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mgt_bandwidth_statistics is
generic
(
    TIMEFRAME_NBITS : integer := 32;
    BANDWIDTH_NBITS : integer := 32
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
end mgt_bandwidth_statistics;

architecture behavioral of mgt_bandwidth_statistics is
    -- SIGNALS
    signal s_timeframe_count        : unsigned(timeframe'range);
    signal s_bandwidth_count        : unsigned(bandwidth'range);
    
    signal s_timeframe_rst          : std_logic;
    signal s_bandwidth_rst          : std_logic;

    signal s_timeframe_finished     : std_logic;
    signal s_timeframe_finished_reg : std_logic;

begin
    -- Operation modes
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_timeframe_rst <= '1';
                s_bandwidth_rst <= '1';
                
                bandwidth <= (others=>'0');
            
            elsif opmode = "00" then -- continuous mode
                if s_timeframe_finished = '1' and s_timeframe_finished_reg = '0' then
                    bandwidth <= std_logic_vector(s_bandwidth_count);
                    s_timeframe_rst <= '1';
                    s_bandwidth_rst <= '1';
                else
                    s_timeframe_rst <= '0';
                    s_bandwidth_rst <= '0';
                end if;
                    
            elsif opmode = "01" then -- trigger mode
                if trigger = '1' then
                    s_timeframe_rst <= '1';
                    s_bandwidth_rst <= '1';
                elsif s_timeframe_finished = '1' and s_timeframe_finished_reg = '0' then
                    bandwidth <= std_logic_vector(s_bandwidth_count);
                else
                    s_timeframe_rst <= '0';
                    s_bandwidth_rst <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Register of 
    process (clk)
    begin
        if rising_edge(clk) then
            s_timeframe_finished_reg <= s_timeframe_finished;
        end if;
    end process;

    -- Time frame counter
    process (clk)
    begin
        if rising_edge(clk) then
            if s_timeframe_rst = '1' then
                s_timeframe_count <= unsigned(timeframe);
                s_timeframe_finished <= '0';
            elsif s_timeframe_count = 0 then
                s_timeframe_finished <= '1';
            else
                s_timeframe_count <= s_timeframe_count - 1;
                s_timeframe_finished <= '0';
            end if;
        end if;
    end process;

    -- Bandwidth counter
    process (clk)
    begin
        if rising_edge(clk) then
            if s_bandwidth_rst = '1' then
                s_bandwidth_count <= (others=>'0');
            else
                s_bandwidth_count <= s_bandwidth_count + unsigned(nbytes);
            end if;
        end if;
    end process;
    
end behavioral;