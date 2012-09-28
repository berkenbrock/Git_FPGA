library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mgt_statistics_package.all;

entity gtx_test_top is
port
(
    ---------------------------------------------------------------------------
    -- GTX Interface
    ---------------------------------------------------------------------------
    CLK_MGT_P                      : in    std_logic;
    CLK_MGT_N                      : in    std_logic;
    SFP1_RX_P                      : in    std_logic;
    SFP1_RX_N                      : in    std_logic;
    SFP1_TX_P                      : out   std_logic;
    SFP1_TX_N                      : out   std_logic;     
    SFP2_RX_P                      : in    std_logic;
    SFP2_RX_N                      : in    std_logic;
    SFP2_TX_P                      : out   std_logic;
    SFP2_TX_N                      : out   std_logic;

    ---------------------------------------------------------------------------
    -- SFP Control Interface
    ---------------------------------------------------------------------------
    SFP1_CTRL_RX_LOS        : in    std_logic;
    SFP1_CTRL_TX_DISABLE    : out   std_logic;
    SFP1_CTRL_TX_FAULT      : inout std_logic;
    SFP1_1MGT_MOD_DETECT    : in    std_logic;
    SFP1_1MGT_SCL           : out   std_logic;
    SFP1_1MGT_SDA           : in    std_logic;
    SFP2_CTRL_RX_LOS        : in    std_logic;
    SFP2_CTRL_TX_DISABLE    : out   std_logic;
    SFP2_CTRL_TX_FAULT      : inout std_logic;
    SFP2_1MGT_MOD_DETECT    : in    std_logic;
    SFP2_1MGT_SCL           : out   std_logic;
    SFP2_1MGT_SDA           : in    std_logic
);
end gtx_test_top;

architecture structural of gtx_test_top is
    ---------------------------------------------------------------------------
    -- System
    ---------------------------------------------------------------------------
    signal   refclk                     : std_logic;
    signal   rst                        : std_logic;
    
    ---------------------------------------------------------------------------
    -- GTX
    ---------------------------------------------------------------------------
    signal   s_REFCLKOUT                : std_logic;

    signal   s_RESETDONE0               : std_logic;
    signal   s_RESETDONE1               : std_logic;

    signal   s_PLLLKDET                 : std_logic;
    
    signal   s_LOOPBACK0                : std_logic_vector(2 downto 0);
    signal   s_LOOPBACK1                : std_logic_vector(2 downto 0);

    signal   s_RXLOSSOFSYNC0            : std_logic_vector(1 downto 0);
    signal   s_RXLOSSOFSYNC1            : std_logic_vector(1 downto 0);

    signal   s_TXCHARISK0               : std_logic_vector(3 downto 0);
    signal   s_TXDATA0                  : std_logic_vector(31 downto 0);
    signal   s_RXCHARISK0               : std_logic_vector(3 downto 0);
    signal   s_RXCHARISCOMMA0           : std_logic_vector(3 downto 0);
    signal   s_RXDATA0                  : std_logic_vector(31 downto 0);

    signal   s_TXCHARISK1               : std_logic_vector(3 downto 0);
    signal   s_TXDATA1                  : std_logic_vector(31 downto 0);
    signal   s_RXCHARISK1               : std_logic_vector(3 downto 0);
    signal   s_RXCHARISCOMMA1           : std_logic_vector(3 downto 0);
    signal   s_RXDATA1                  : std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------------
    -- VIO interface
    ---------------------------------------------------------------------------
    signal icon_control0        : std_logic_vector(35 downto 0);
    signal vio_out              : std_logic_vector(255 downto 0);
    signal vio_in               : std_logic_vector(255 downto   0);

    ---------------------------------------------------------------------------
    -- Loopback statistics
    ---------------------------------------------------------------------------
    signal s_seq_snd            : std_logic_vector(15 downto 0);
    signal s_error_count        : std_logic_vector(31 downto 0);
    signal s_lossofsync_count   : std_logic_vector(31 downto 0);
    signal s_latency            : std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------------
    -- Bandwidth statistics
    ---------------------------------------------------------------------------
    signal s_bandwidth_RX0      : std_logic_vector(31 downto 0);
    signal s_nbytes_RX0         : std_logic_vector(1 downto 0);
    signal s_send_data          : std_logic;
    signal s_datarate          : std_logic_vector(15 downto 0);
    signal s_count              : unsigned(s_datarate'range);
    
    ---------------------------------------------------------------------------
    -- GTX
    ---------------------------------------------------------------------------
    component GTX_DUAL
    generic
    (
        ------------------------------------------------------------------------
        -- Simulation
        ------------------------------------------------------------------------
        SIM_RECEIVER_DETECT_PASS_0  : boolean := TRUE;
        SIM_RECEIVER_DETECT_PASS_1  : boolean := TRUE;
        SIM_MODE                    : string := "FAST";
        SIM_GTXRESET_SPEEDUP        : integer := 1;
        SIM_PLL_PERDIV2             : bit_vector := X"140";
        ------------------------------------------------------------------------
        -- CTRL
        ------------------------------------------------------------------------
        -- PLL
        OVERSAMPLE_MODE             : boolean := FALSE;
        PLL_DIVSEL_FB               : integer := 4;
        PLL_DIVSEL_REF              : integer := 1;

        PLL_COM_CFG                 : bit_vector := X"21680a";
        PLL_CP_CFG                  : bit_vector := X"00";
        PLL_FB_DCCEN                : boolean := FALSE;
        PLL_LKDET_CFG               : bit_vector := "101";
        PLL_TDCC_CFG                : bit_vector := "000";
        PMA_COM_CFG                 : bit_vector := X"000000000000000000";

        PLL_SATA_0                  : boolean := FALSE;
        PLL_SATA_1                  : boolean := FALSE;
        -- Shared clocking
        CLK25_DIVIDER               : integer := 10;
        CLKINDC_B                   : boolean := TRUE;
        CLKRCV_TRST                 : boolean := TRUE;
        -- Termination
        TERMINATION_CTRL            : bit_vector := "10100";
        TERMINATION_OVRD            : boolean := FALSE;
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CAL_TIME                : bit_vector := "00110";
        -- RX Out Of Band (OOB)
        OOB_CLK_DIVIDER             : integer := 6;
        -- RX Clock Data Recovery (CDR)
        CDR_PH_ADJ_TIME             : bit_vector := "01010";
        RX_EN_IDLE_RESET_FR         : boolean := TRUE;
        RX_EN_IDLE_HOLD_CDR         : boolean := FALSE;
        RX_EN_IDLE_RESET_PH         : boolean := TRUE;
        ------------------------------------------------------------------------
        -- RX 0
        ------------------------------------------------------------------------
        -- RX serial ports
        AC_CAP_DIS_0                : boolean := TRUE;
        CM_TRIM_0                   : bit_vector := "10";
        RCV_TERM_GND_0              : boolean := FALSE;
        RCV_TERM_VTTRX_0            : boolean := TRUE;
        TERMINATION_IMP_0           : integer := 50;
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CFG_0                   : bit_vector := "1101111011";
        RX_EN_IDLE_HOLD_DFE_0       : boolean := TRUE;
        -- RX Out Of Band (OOB)
        OOBDETECT_THRESHOLD_0       : bit_vector := "110";
        RX_STATUS_FMT_0             : string := "PCIE";
        -- RX PCIexpress
        RX_IDLE_HI_CNT_0            : bit_vector := "1000";
        RX_IDLE_LO_CNT_0            : bit_vector := "0000";
        -- RX SATA
        SATA_BURST_VAL_0            : bit_vector := "100";
        SATA_IDLE_VAL_0             : bit_vector := "100";
        SATA_MAX_BURST_0            : integer := 7;
        SATA_MAX_INIT_0             : integer := 16;
        SATA_MAX_WAKE_0             : integer := 7;
        SATA_MIN_BURST_0            : integer := 4;
        SATA_MIN_INIT_0             : integer := 12;
        SATA_MIN_WAKE_0             : integer := 4;
        TRANS_TIME_FROM_P2_0        : bit_vector := X"03c";
        TRANS_TIME_NON_P2_0         : bit_vector := X"19";
        TRANS_TIME_TO_P2_0          : bit_vector := X"064";
        -- RX Clock Data Recovery (CDR)
        PMA_CDR_SCAN_0              : bit_vector := X"6404035";
        PMA_RX_CFG_0                : bit_vector := X"0F44088";
        -- RX serial line rate clocks
        PLL_RXDIVSEL_OUT_0          : integer := 1;
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBS_ERR_THRESHOLD_0        : bit_vector := X"00000001";
        -- RX comma detection and alignment
        ALIGN_COMMA_WORD_0          : integer := 1;
        COMMA_10B_ENABLE_0          : bit_vector := "0001111111";
        COMMA_DOUBLE_0              : boolean := FALSE;
        MCOMMA_10B_VALUE_0          : bit_vector := "1010000011";
        MCOMMA_DETECT_0             : boolean := TRUE;
        PCOMMA_10B_VALUE_0          : bit_vector := "0101111100";
        PCOMMA_DETECT_0             : boolean := TRUE;
        RX_SLIDE_MODE_0             : string := "PCS";
        -- RX loss of sync fsm
        RX_LOS_INVALID_INCR_0       : integer := 1;
        RX_LOS_THRESHOLD_0          : integer := 3;
        RX_LOSS_OF_SYNC_FSM_0       : boolean := FALSE;
        -- RX 8b10b decoder
        DEC_MCOMMA_DETECT_0         : boolean := TRUE;
        DEC_PCOMMA_DETECT_0         : boolean := TRUE;
        DEC_VALID_COMMA_ONLY_0      : boolean := TRUE;
        -- RX elastic buffer
        PMA_RXSYNC_CFG_0            : bit_vector := X"00";
        RX_BUFFER_USE_0             : boolean := TRUE;
        RX_EN_IDLE_RESET_BUF_0      : boolean := TRUE;
        RX_XCLK_SEL_0               : string := "RXUSR";
        -- RX clock correction
        CLK_CORRECT_USE_0           : boolean := TRUE;
        CLK_COR_ADJ_LEN_0           : integer := 1;
        CLK_COR_DET_LEN_0           : integer := 1;
        CLK_COR_INSERT_IDLE_FLAG_0  : boolean := FALSE;
        CLK_COR_KEEP_IDLE_0         : boolean := FALSE;
        CLK_COR_MAX_LAT_0           : integer := 18;
        CLK_COR_MIN_LAT_0           : integer := 16;
        CLK_COR_PRECEDENCE_0        : boolean := TRUE;
        CLK_COR_REPEAT_WAIT_0       : integer := 0;
        CLK_COR_SEQ_1_1_0           : bit_vector := "0100011100";
        CLK_COR_SEQ_1_2_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_3_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_4_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_ENABLE_0      : bit_vector := "0001";
        CLK_COR_SEQ_2_1_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_2_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_3_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_4_0           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_ENABLE_0      : bit_vector := "0000";
        CLK_COR_SEQ_2_USE_0         : boolean := FALSE;
        RX_DECODE_SEQ_MATCH_0       : boolean := TRUE;
        -- RX channel bonding
        CB2_INH_CC_PERIOD_0         : integer := 8;
        CHAN_BOND_1_MAX_SKEW_0      : integer := 1;
        CHAN_BOND_2_MAX_SKEW_0      : integer := 1;
        CHAN_BOND_KEEP_ALIGN_0      : boolean := FALSE;
        CHAN_BOND_LEVEL_0           : integer := 0;
        CHAN_BOND_MODE_0            : string := "OFF";
        CHAN_BOND_SEQ_1_1_0         : bit_vector := "0101111100";
        CHAN_BOND_SEQ_1_2_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_3_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_4_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_ENABLE_0    : bit_vector := "0000";
        CHAN_BOND_SEQ_2_1_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_2_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_3_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_4_0         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_ENABLE_0    : bit_vector := "0000";
        CHAN_BOND_SEQ_2_USE_0       : boolean := FALSE;
        CHAN_BOND_SEQ_LEN_0         : integer := 1;
        PCI_EXPRESS_MODE_0          : boolean := FALSE;
        -- RX 64b66b and 64b67b gearbox
        RXGEARBOX_USE_0             : boolean := FALSE;
        ------------------------------------------------------------------------
        -- TX 0
        ------------------------------------------------------------------------
        -- TX 64b66b and 64b67b gearbox
        GEARBOX_ENDEC_0             : bit_vector := "000";
        TXGEARBOX_USE_0             : boolean := FALSE;
        -- TX serial line rate clocks
        PLL_TXDIVSEL_OUT_0          : integer := 1;
        -- TX elastic buffer
        TX_BUFFER_USE_0             : boolean := TRUE;
        TX_XCLK_SEL_0               : string := "TXOUT";
        TXRX_INVERT_0               : bit_vector := "011";
        -- TX Out Of Band (OOB) beaconing
        COM_BURST_VAL_0             : bit_vector := "1111";
        PMA_TX_CFG_0                : bit_vector := X"80082";
        TX_DETECT_RX_CFG_0          : bit_vector := X"1832";
        TX_IDLE_DELAY_0             : bit_vector := "010";
        ------------------------------------------------------------------------
        -- RX 1
        ------------------------------------------------------------------------
        -- RX serial ports
        AC_CAP_DIS_1                : boolean := TRUE;
        CM_TRIM_1                   : bit_vector := "10";
        RCV_TERM_GND_1              : boolean := FALSE;
        RCV_TERM_VTTRX_1            : boolean := FALSE;
        TERMINATION_IMP_1           : integer := 50;
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CFG_1                   : bit_vector := "1101111011";
        RX_EN_IDLE_HOLD_DFE_1       : boolean := TRUE;
        -- RX Out Of Band (OOB)
        OOBDETECT_THRESHOLD_1       : bit_vector := "111";
        RX_STATUS_FMT_1             : string := "PCIE";
        -- RX PCIexpress
        RX_IDLE_HI_CNT_1            : bit_vector := "1000";
        RX_IDLE_LO_CNT_1            : bit_vector := "0000";
        -- RX SATA
        SATA_BURST_VAL_1            : bit_vector := "100";
        SATA_IDLE_VAL_1             : bit_vector := "100";
        SATA_MAX_BURST_1            : integer := 7;
        SATA_MAX_INIT_1             : integer := 16;
        SATA_MAX_WAKE_1             : integer := 7;
        SATA_MIN_BURST_1            : integer := 4;
        SATA_MIN_INIT_1             : integer := 12;
        SATA_MIN_WAKE_1             : integer := 4;
        TRANS_TIME_FROM_P2_1        : bit_vector := X"03c";
        TRANS_TIME_NON_P2_1         : bit_vector := X"19";
        TRANS_TIME_TO_P2_1          : bit_vector := X"064";
        -- RX Clock Data Recovery (CDR)
        PMA_CDR_SCAN_1              : bit_vector := X"6404035";
        PMA_RX_CFG_1                : bit_vector := X"0F44089";
        -- RX serial line rate clocks
        PLL_RXDIVSEL_OUT_1          : integer := 1;
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBS_ERR_THRESHOLD_1        : bit_vector := X"00000001";
        -- RX comma detection and alignment
        ALIGN_COMMA_WORD_1          : integer := 1;
        COMMA_10B_ENABLE_1          : bit_vector := "0001111111";
        COMMA_DOUBLE_1              : boolean := FALSE;
        MCOMMA_10B_VALUE_1          : bit_vector := "1010000011";
        MCOMMA_DETECT_1             : boolean := TRUE;
        PCOMMA_10B_VALUE_1          : bit_vector := "0101111100";
        PCOMMA_DETECT_1             : boolean := TRUE;
        RX_SLIDE_MODE_1             : string := "PCS";
        -- RX loss of sync fsm
        RX_LOS_INVALID_INCR_1       : integer := 1;
        RX_LOS_THRESHOLD_1          : integer := 3;
        RX_LOSS_OF_SYNC_FSM_1       : boolean := FALSE;
        -- RX 8b10b decoder
        DEC_MCOMMA_DETECT_1         : boolean := TRUE;
        DEC_PCOMMA_DETECT_1         : boolean := TRUE;
        DEC_VALID_COMMA_ONLY_1      : boolean := TRUE;
        -- RX elastic buffer
        PMA_RXSYNC_CFG_1            : bit_vector := X"00";
        RX_BUFFER_USE_1             : boolean := TRUE;
        RX_EN_IDLE_RESET_BUF_1      : boolean := TRUE;
        RX_XCLK_SEL_1               : string := "RXUSR";
        -- RX clock correction
        CLK_CORRECT_USE_1           : boolean := TRUE;
        CLK_COR_ADJ_LEN_1           : integer := 1;
        CLK_COR_DET_LEN_1           : integer := 1;
        CLK_COR_INSERT_IDLE_FLAG_1  : boolean := FALSE;
        CLK_COR_KEEP_IDLE_1         : boolean := FALSE;
        CLK_COR_MAX_LAT_1           : integer := 20;
        CLK_COR_MIN_LAT_1           : integer := 18;
        CLK_COR_PRECEDENCE_1        : boolean := TRUE;
        CLK_COR_REPEAT_WAIT_1       : integer := 0;
        CLK_COR_SEQ_1_1_1           : bit_vector := "0100011100";
        CLK_COR_SEQ_1_2_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_3_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_4_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_1_ENABLE_1      : bit_vector := "0001";
        CLK_COR_SEQ_2_1_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_2_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_3_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_4_1           : bit_vector := "0000000000";
        CLK_COR_SEQ_2_ENABLE_1      : bit_vector := "0000";
        CLK_COR_SEQ_2_USE_1         : boolean := FALSE;
        RX_DECODE_SEQ_MATCH_1       : boolean := TRUE;
        -- RX channel bonding
        CB2_INH_CC_PERIOD_1         : integer := 8;
        CHAN_BOND_1_MAX_SKEW_1      : integer := 1;
        CHAN_BOND_2_MAX_SKEW_1      : integer := 1;
        CHAN_BOND_KEEP_ALIGN_1      : boolean := FALSE;
        CHAN_BOND_LEVEL_1           : integer := 0;
        CHAN_BOND_MODE_1            : string := "OFF";
        CHAN_BOND_SEQ_1_1_1         : bit_vector := "0101111100";
        CHAN_BOND_SEQ_1_2_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_3_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_4_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_1_ENABLE_1    : bit_vector := "0001";
        CHAN_BOND_SEQ_2_1_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_2_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_3_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_4_1         : bit_vector := "0000000000";
        CHAN_BOND_SEQ_2_ENABLE_1    : bit_vector := "0000";
        CHAN_BOND_SEQ_2_USE_1       : boolean := FALSE;
        CHAN_BOND_SEQ_LEN_1         : integer := 1;
        PCI_EXPRESS_MODE_1          : boolean := FALSE;
        -- RX 64b66b and 64b67b gearbox
        RXGEARBOX_USE_1             : boolean := FALSE;
        ------------------------------------------------------------------------
        -- TX 1
        ------------------------------------------------------------------------
        -- TX 64b66b and 64b67b gearbox
        GEARBOX_ENDEC_1             : bit_vector := "000";
        TXGEARBOX_USE_1             : boolean := FALSE;
        -- TX serial line rate clocks
        PLL_TXDIVSEL_OUT_1          : integer := 1;
        -- TX elastic buffer
        TX_BUFFER_USE_1             : boolean := TRUE;
        TX_XCLK_SEL_1               : string := "TXOUT";
        TXRX_INVERT_1               : bit_vector := "011";
        -- TX Out Of Band (OOB) beaconing
        COM_BURST_VAL_1             : bit_vector := "1111";
        PMA_TX_CFG_1                : bit_vector := X"80082";
        TX_DETECT_RX_CFG_1          : bit_vector := X"1832";
        TX_IDLE_DELAY_1             : bit_vector := "010"
    );
    port
    (
        ------------------------------------------------------------------------
        -- CTRL
        ------------------------------------------------------------------------
        -- Xilinx test ports
        GTXTEST                     : in    std_logic_vector(13 downto  0);
        -- Global ports
        GTXRESET                    : in    std_ulogic;
        RESETDONE0                  : out   std_ulogic;
        RESETDONE1                  : out   std_ulogic;
        INTDATAWIDTH                : in    std_ulogic;
        -- PLL
        CLKIN                       : in    std_ulogic;
        REFCLKPWRDNB                : in    std_ulogic;
        REFCLKOUT                   : out   std_ulogic;
        PLLLKDET                    : out   std_ulogic;
        PLLLKDETEN                  : in    std_ulogic;
        PLLPOWERDOWN                : in    std_ulogic;
        -- Loopback
        LOOPBACK0                   : in    std_logic_vector( 2 downto  0);
        LOOPBACK1                   : in    std_logic_vector( 2 downto  0);
        ------------------------------------------------------------------------
        -- DRP
        ------------------------------------------------------------------------
        -- Dynamic Reconfiguration Port (DRP)
        DCLK                        : in    std_ulogic;
        DEN                         : in    std_ulogic;
        DWE                         : in    std_ulogic;
        DADDR                       : in    std_logic_vector( 6 downto  0);
        DI                          : in    std_logic_vector(15 downto  0);
        DO                          : out   std_logic_vector(15 downto  0);
        DRDY                        : out   std_ulogic;
        ------------------------------------------------------------------------
        -- RX 0
        ------------------------------------------------------------------------
        -- RX resets
        RXRESET0                    : in    std_ulogic;
        -- RX power control
        RXPOWERDOWN0                : in    std_logic_vector( 1 downto  0);
        -- RX user clocks
        RXRECCLK0                   : out   std_ulogic;
        RXUSRCLK0                   : in    std_ulogic;
        RXUSRCLK20                  : in    std_ulogic;
        -- RX serial ports
        RXP0                        : in    std_ulogic;
        RXN0                        : in    std_ulogic;
        -- RX EQualizer (EQ)
        RXENEQB0                    : in    std_ulogic;
        RXEQMIX0                    : in    std_logic_vector( 1 downto  0);
        RXEQPOLE0                   : in    std_logic_vector( 3 downto  0);
        -- RX Decision Feedback Equalizer(DFE)
        DFECLKDLYADJ0               : in    std_logic_vector( 5 downto  0);
        DFECLKDLYADJMONITOR0        : out   std_logic_vector( 5 downto  0);
        DFEEYEDACMONITOR0           : out   std_logic_vector( 4 downto  0);
        DFESENSCAL0                 : out   std_logic_vector( 2 downto  0);
        DFETAP10                    : in    std_logic_vector( 4 downto  0);
        DFETAP1MONITOR0             : out   std_logic_vector( 4 downto  0);
        DFETAP20                    : in    std_logic_vector( 4 downto  0);
        DFETAP2MONITOR0             : out   std_logic_vector( 4 downto  0);
        DFETAP30                    : in    std_logic_vector( 3 downto  0);
        DFETAP3MONITOR0             : out   std_logic_vector( 3 downto  0);
        DFETAP40                    : in    std_logic_vector( 3 downto  0);
        DFETAP4MONITOR0             : out   std_logic_vector( 3 downto  0);
        -- RX Out Of Band (OOB)
        RXELECIDLE0                 : out   std_ulogic;
        RXVALID0                    : out   std_ulogic;
        PHYSTATUS0                  : out   std_ulogic;
        -- RX Clock Data Recovery (CDR)
        RXCDRRESET0                 : in    std_ulogic;
        -- RX oversampling
        RXENSAMPLEALIGN0            : in    std_ulogic;
        RXOVERSAMPLEERR0            : out   std_ulogic;
        -- RX polarity
        RXPOLARITY0                 : in    std_ulogic;
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBSCNTRESET0               : in    std_ulogic;
        RXENPRBSTST0                : in    std_logic_vector( 1 downto  0);
        RXPRBSERR0                  : out   std_ulogic;
        -- RX comma detection and alignment
        RXBYTEISALIGNED0            : out   std_ulogic;
        RXBYTEREALIGN0              : out   std_ulogic;
        RXCOMMADET0                 : out   std_ulogic;
        RXCOMMADETUSE0              : in    std_ulogic;
        RXENMCOMMAALIGN0            : in    std_ulogic;
        RXENPCOMMAALIGN0            : in    std_ulogic;
        RXSLIDE0                    : in    std_ulogic;
        -- RX loss of sync fsm
        RXLOSSOFSYNC0               : out   std_logic_vector( 1 downto  0);
        -- RX 8b10b decoder
        RXCHARISCOMMA0              : out   std_logic_vector( 3 downto  0);
        RXCHARISK0                  : out   std_logic_vector( 3 downto  0);
        RXDATAWIDTH0                : in    std_logic_vector( 1 downto  0);
        RXDEC8B10BUSE0              : in    std_ulogic;
        RXDISPERR0                  : out   std_logic_vector( 3 downto  0);
        RXNOTINTABLE0               : out   std_logic_vector( 3 downto  0);
        RXRUNDISP0                  : out   std_logic_vector( 3 downto  0);
        -- RX elastic buffer
        RXBUFRESET0                 : in    std_ulogic;
        RXBUFSTATUS0                : out   std_logic_vector( 2 downto  0);
        RXENPMAPHASEALIGN0          : in    std_ulogic;
        RXPMASETPHASE0              : in    std_ulogic;
        RXSTATUS0                   : out   std_logic_vector( 2 downto  0);
        -- RX clock correction
        RXCLKCORCNT0                : out   std_logic_vector( 2 downto  0);
        -- RX channel bonding
        RXCHANBONDSEQ0              : out   std_ulogic;
        RXCHANISALIGNED0            : out   std_ulogic;
        RXCHANREALIGN0              : out   std_ulogic;
        RXCHBONDI0                  : in    std_logic_vector( 3 downto  0);
        RXCHBONDO0                  : out   std_logic_vector( 3 downto  0);
        RXENCHANSYNC0               : in    std_ulogic;
        -- RX 64b66b and 64b67b gearbox
        RXDATAVALID0                : out   std_ulogic;
        RXGEARBOXSLIP0              : in    std_ulogic;
        RXHEADER0                   : out   std_logic_vector( 2 downto  0);
        RXHEADERVALID0              : out   std_ulogic;
        RXSTARTOFSEQ0               : out   std_ulogic;
        -- RX data ports
        RXDATA0                     : out   std_logic_vector(31 downto  0);
        ------------------------------------------------------------------------
        -- TX 0
        ------------------------------------------------------------------------
        -- TX resets
        TXRESET0                    : in    std_ulogic;
        -- TX power control
        TXPOWERDOWN0                : in    std_logic_vector( 1 downto  0);
        -- TX user clocks
        TXOUTCLK0                   : out   std_ulogic;
        TXUSRCLK0                   : in    std_ulogic;
        TXUSRCLK20                  : in    std_ulogic;
        -- TX data ports
        TXDATAWIDTH0                : in    std_logic_vector( 1 downto  0);
        TXDATA0                     : in    std_logic_vector(31 downto  0);
        -- TX 8b10b encoder
        TXBYPASS8B10B0              : in    std_logic_vector( 3 downto  0);
        TXCHARDISPMODE0             : in    std_logic_vector( 3 downto  0);
        TXCHARDISPVAL0              : in    std_logic_vector( 3 downto  0);
        TXCHARISK0                  : in    std_logic_vector( 3 downto  0);
        TXENC8B10BUSE0              : in    std_ulogic;
        TXKERR0                     : out   std_logic_vector( 3 downto  0);
        TXRUNDISP0                  : out   std_logic_vector( 3 downto  0);
        -- TX 64b66b and 64b67b gearbox
        TXGEARBOXREADY0             : out   std_ulogic;
        TXHEADER0                   : in    std_logic_vector( 2 downto  0);
        TXSEQUENCE0                 : in    std_logic_vector( 6 downto  0);
        TXSTARTSEQ0                 : in    std_ulogic;
        -- TX Pseudo Random Bit Sequences (PRBS)
        TXENPRBSTST0                : in    std_logic_vector( 1 downto  0);
        -- TX elastic buffer
        TXBUFSTATUS0                : out   std_logic_vector( 1 downto  0);
        -- TX phase alignment fifo
        TXENPMAPHASEALIGN0          : in    std_ulogic;
        TXPMASETPHASE0              : in    std_ulogic;
        -- TX polarity
        TXPOLARITY0                 : in    std_ulogic;
        -- TX Out Of Band (OOB) beaconing
        TXELECIDLE0                 : in    std_ulogic;
        -- TX PCIexpress
        TXDETECTRX0                 : in    std_ulogic;
        -- TX SATA
        TXCOMSTART0                 : in    std_ulogic;
        TXCOMTYPE0                  : in    std_ulogic;
        -- TX driver
        TXBUFDIFFCTRL0              : in    std_logic_vector( 2 downto  0);
        TXDIFFCTRL0                 : in    std_logic_vector( 2 downto  0);
        TXPREEMPHASIS0              : in    std_logic_vector( 3 downto  0);
        TXINHIBIT0                  : in    std_ulogic;
        -- TX serial ports
        TXP0                        : out   std_ulogic;
        TXN0                        : out   std_ulogic;
        ------------------------------------------------------------------------
        -- RX 1
        ------------------------------------------------------------------------
        -- RX resets
        RXRESET1                    : in    std_ulogic;
        -- RX power control
        RXPOWERDOWN1                : in    std_logic_vector( 1 downto  0);
        -- RX user clocks
        RXRECCLK1                   : out   std_ulogic;
        RXUSRCLK1                   : in    std_ulogic;
        RXUSRCLK21                  : in    std_ulogic;
        -- RX serial ports
        RXP1                        : in    std_ulogic;
        RXN1                        : in    std_ulogic;
        -- RX EQualizer (EQ)
        RXENEQB1                    : in    std_ulogic;
        RXEQMIX1                    : in    std_logic_vector( 1 downto  0);
        RXEQPOLE1                   : in    std_logic_vector( 3 downto  0);
        -- RX Decision Feedback Equalizer(DFE)
        DFECLKDLYADJ1               : in    std_logic_vector( 5 downto  0);
        DFECLKDLYADJMONITOR1        : out   std_logic_vector( 5 downto  0);
        DFEEYEDACMONITOR1           : out   std_logic_vector( 4 downto  0);
        DFESENSCAL1                 : out   std_logic_vector( 2 downto  0);
        DFETAP11                    : in    std_logic_vector( 4 downto  0);
        DFETAP1MONITOR1             : out   std_logic_vector( 4 downto  0);
        DFETAP21                    : in    std_logic_vector( 4 downto  0);
        DFETAP2MONITOR1             : out   std_logic_vector( 4 downto  0);
        DFETAP31                    : in    std_logic_vector( 3 downto  0);
        DFETAP3MONITOR1             : out   std_logic_vector( 3 downto  0);
        DFETAP41                    : in    std_logic_vector( 3 downto  0);
        DFETAP4MONITOR1             : out   std_logic_vector( 3 downto  0);
        -- RX Out Of Band (OOB)
        RXELECIDLE1                 : out   std_ulogic;
        RXVALID1                    : out   std_ulogic;
        PHYSTATUS1                  : out   std_ulogic;
        -- RX Clock Data Recovery (CDR)
        RXCDRRESET1                 : in    std_ulogic;
        -- RX oversampling
        RXENSAMPLEALIGN1            : in    std_ulogic;
        RXOVERSAMPLEERR1            : out   std_ulogic;
        -- RX polarity
        RXPOLARITY1                 : in    std_ulogic;
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBSCNTRESET1               : in    std_ulogic;
        RXENPRBSTST1                : in    std_logic_vector( 1 downto  0);
        RXPRBSERR1                  : out   std_ulogic;
        -- RX comma detection and alignment
        RXBYTEISALIGNED1            : out   std_ulogic;
        RXBYTEREALIGN1              : out   std_ulogic;
        RXCOMMADET1                 : out   std_ulogic;
        RXCOMMADETUSE1              : in    std_ulogic;
        RXENMCOMMAALIGN1            : in    std_ulogic;
        RXENPCOMMAALIGN1            : in    std_ulogic;
        RXSLIDE1                    : in    std_ulogic;
        -- RX loss of sync fsm
        RXLOSSOFSYNC1               : out   std_logic_vector( 1 downto  0);
        -- RX 8b10b decoder
        RXCHARISCOMMA1              : out   std_logic_vector( 3 downto  0);
        RXCHARISK1                  : out   std_logic_vector( 3 downto  0);
        RXDATAWIDTH1                : in    std_logic_vector( 1 downto  0);
        RXDEC8B10BUSE1              : in    std_ulogic;
        RXDISPERR1                  : out   std_logic_vector( 3 downto  0);
        RXNOTINTABLE1               : out   std_logic_vector( 3 downto  0);
        RXRUNDISP1                  : out   std_logic_vector( 3 downto  0);
        -- RX elastic buffer
        RXBUFRESET1                 : in    std_ulogic;
        RXBUFSTATUS1                : out   std_logic_vector( 2 downto  0);
        RXENPMAPHASEALIGN1          : in    std_ulogic;
        RXPMASETPHASE1              : in    std_ulogic;
        RXSTATUS1                   : out   std_logic_vector( 2 downto  0);
        -- RX clock correction
        RXCLKCORCNT1                : out   std_logic_vector( 2 downto  0);
        -- RX channel bonding
        RXCHANBONDSEQ1              : out   std_ulogic;
        RXCHANISALIGNED1            : out   std_ulogic;
        RXCHANREALIGN1              : out   std_ulogic;
        RXCHBONDI1                  : in    std_logic_vector( 3 downto  0);
        RXCHBONDO1                  : out   std_logic_vector( 3 downto  0);
        RXENCHANSYNC1               : in    std_ulogic;
        -- RX 64b66b and 64b67b gearbox
        RXDATAVALID1                : out   std_ulogic;
        RXGEARBOXSLIP1              : in    std_ulogic;
        RXHEADER1                   : out   std_logic_vector( 2 downto  0);
        RXHEADERVALID1              : out   std_ulogic;
        RXSTARTOFSEQ1               : out   std_ulogic;
        -- RX data ports
        RXDATA1                     : out   std_logic_vector(31 downto  0);
        ------------------------------------------------------------------------
        -- TX 1
        ------------------------------------------------------------------------
        -- TX resets
        TXRESET1                    : in    std_ulogic;
        -- TX power control
        TXPOWERDOWN1                : in    std_logic_vector( 1 downto  0);
        -- TX user clocks
        TXOUTCLK1                   : out   std_ulogic;
        TXUSRCLK1                   : in    std_ulogic;
        TXUSRCLK21                  : in    std_ulogic;
        -- TX data ports
        TXDATAWIDTH1                : in    std_logic_vector( 1 downto  0);
        TXDATA1                     : in    std_logic_vector(31 downto  0);
        -- TX 8b10b encoder
        TXBYPASS8B10B1              : in    std_logic_vector( 3 downto  0);
        TXCHARDISPMODE1             : in    std_logic_vector( 3 downto  0);
        TXCHARDISPVAL1              : in    std_logic_vector( 3 downto  0);
        TXCHARISK1                  : in    std_logic_vector( 3 downto  0);
        TXENC8B10BUSE1              : in    std_ulogic;
        TXKERR1                     : out   std_logic_vector( 3 downto  0);
        TXRUNDISP1                  : out   std_logic_vector( 3 downto  0);
        -- TX 64b66b and 64b67b gearbox
        TXGEARBOXREADY1             : out   std_ulogic;
        TXHEADER1                   : in    std_logic_vector( 2 downto  0);
        TXSEQUENCE1                 : in    std_logic_vector( 6 downto  0);
        TXSTARTSEQ1                 : in    std_ulogic;
        -- TX Pseudo Random Bit Sequences (PRBS)
        TXENPRBSTST1                : in    std_logic_vector( 1 downto  0);
        -- TX elastic buffer
        TXBUFSTATUS1                : out   std_logic_vector( 1 downto  0);
        -- TX phase alignment fifo
        TXENPMAPHASEALIGN1          : in    std_ulogic;
        TXPMASETPHASE1              : in    std_ulogic;
        -- TX polarity
        TXPOLARITY1                 : in    std_ulogic;
        -- TX Out Of Band (OOB) beaconing
        TXELECIDLE1                 : in    std_ulogic;
        -- TX PCIexpress
        TXDETECTRX1                 : in    std_ulogic;
        -- TX SATA
        TXCOMSTART1                 : in    std_ulogic;
        TXCOMTYPE1                  : in    std_ulogic;
        -- TX driver
        TXBUFDIFFCTRL1              : in    std_logic_vector( 2 downto  0);
        TXDIFFCTRL1                 : in    std_logic_vector( 2 downto  0);
        TXPREEMPHASIS1              : in    std_logic_vector( 3 downto  0);
        TXINHIBIT1                  : in    std_ulogic;
        -- TX serial ports
        TXP1                        : out   std_ulogic;
        TXN1                        : out   std_ulogic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Input buffer DS
    ---------------------------------------------------------------------------
    component IBUFDS
    port
    (
      I                           : in    std_logic;
      IB                          : in    std_logic;
      O                           : out   std_logic
    );
    end component;

    ---------------------------------------------------------------------------
    -- Loopback statistics
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- Bandwidth statistics
    ---------------------------------------------------------------------------
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

    ---------------------------------------------------------------------------
    -- VIO interface
    ---------------------------------------------------------------------------
    component ICON
    port
    (
        CONTROL0 : inout std_logic_vector(35 downto 0)
    );
    end component;

    component VIO
    port
    (
        CONTROL : inout std_logic_vector(35 downto 0);
        CLK : in std_logic;
        SYNC_IN : in std_logic_vector(255 downto 0);
        SYNC_OUT : out std_logic_vector(255 downto 0)
    );
    end component;

begin
    ---------------------------------------------------------------------------
    -- GTX instantiation
    ---------------------------------------------------------------------------
    gtx_dual_inst : GTX_DUAL
    generic map
    (
        ------------------------------------------------------------------------
        -- Simulation
        ------------------------------------------------------------------------
        SIM_RECEIVER_DETECT_PASS_0  => TRUE,
        SIM_RECEIVER_DETECT_PASS_1  => TRUE,
        SIM_MODE                    => "FAST",
        SIM_GTXRESET_SPEEDUP        => 0,
        SIM_PLL_PERDIV2             => X"0FA",
        ------------------------------------------------------------------------
        -- CTRL
        ------------------------------------------------------------------------
        -- PLL
        OVERSAMPLE_MODE             => FALSE,
        PLL_DIVSEL_FB               => 4,
        PLL_DIVSEL_REF              => 1,

        PLL_COM_CFG                 => X"21680A",                              -- Tile and PLL Attributes badly documented
        PLL_CP_CFG                  => X"00",                                  -- Tile and PLL Attributes badly documented
        PLL_FB_DCCEN                => FALSE,                                  -- Tile and PLL Attributes badly documented
        PLL_LKDET_CFG               => "101",                                  -- Tile and PLL Attributes badly documented
        PLL_TDCC_CFG                => "000",                                  -- Tile and PLL Attributes badly documented
        PMA_COM_CFG                 => X"000000000000000000",                  -- Tile and PLL Attributes badly documented

        PLL_SATA_0                  => FALSE,
        PLL_SATA_1                  => FALSE,
        -- Shared clocking
        CLK25_DIVIDER               => 5, 
        CLKINDC_B                   => TRUE,
        CLKRCV_TRST                 => TRUE,
        -- Termination
        TERMINATION_CTRL            => "10100",
        TERMINATION_OVRD            => FALSE,
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CAL_TIME                => "00110",
        -- RX Out Of Band (OOB)
        OOB_CLK_DIVIDER             => 4,
        -- RX Clock Data Recovery (CDR)
        CDR_PH_ADJ_TIME             => "01010",
        RX_EN_IDLE_RESET_FR         => TRUE,
        RX_EN_IDLE_HOLD_CDR         => FALSE,
        RX_EN_IDLE_RESET_PH         => TRUE,
        ------------------------------------------------------------------------
        -- RX 0
        ------------------------------------------------------------------------
        -- RX serial ports
        AC_CAP_DIS_0                => TRUE,
        CM_TRIM_0                   => "10",
        RCV_TERM_GND_0              => FALSE,
        RCV_TERM_VTTRX_0            => TRUE,
        TERMINATION_IMP_0           => 50,
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CFG_0                   => "1001111011",
        RX_EN_IDLE_HOLD_DFE_0       => TRUE,
        -- RX Out Of Band (OOB)
        OOBDETECT_THRESHOLD_0       => "111",
        RX_STATUS_FMT_0             => "PCIE",
        -- RX PCIexpress
        RX_IDLE_HI_CNT_0            => "1000",
        RX_IDLE_LO_CNT_0            => "0000",
        -- RX SATA
        SATA_BURST_VAL_0            => "100",
        SATA_IDLE_VAL_0             => "100",
        SATA_MAX_BURST_0            => 9,
        SATA_MAX_INIT_0             => 27,
        SATA_MAX_WAKE_0             => 9,
        SATA_MIN_BURST_0            => 5,
        SATA_MIN_INIT_0             => 15,
        SATA_MIN_WAKE_0             => 5,
        TRANS_TIME_FROM_P2_0        => X"003C",
        TRANS_TIME_NON_P2_0         => X"0019",
        TRANS_TIME_TO_P2_0          => X"0064",
        -- RX Clock Data Recovery (CDR)
        PMA_CDR_SCAN_0              => X"6404039",
        PMA_RX_CFG_0                => X"0F44088",
        -- RX serial line rate clocks
        PLL_RXDIVSEL_OUT_0          => 2,
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBS_ERR_THRESHOLD_0        => X"00000001",
        -- RX comma detection and alignment
        ALIGN_COMMA_WORD_0          => 2,
        COMMA_10B_ENABLE_0          => "1111111111",
        COMMA_DOUBLE_0              => FALSE,
        MCOMMA_10B_VALUE_0          => "1010000011",
        MCOMMA_DETECT_0             => TRUE,
        PCOMMA_10B_VALUE_0          => "0101111100",
        PCOMMA_DETECT_0             => TRUE,
        RX_SLIDE_MODE_0             => "PCS",
        -- RX loss of sync fsm
        RX_LOS_INVALID_INCR_0       => 4,
        RX_LOS_THRESHOLD_0          => 32,
        RX_LOSS_OF_SYNC_FSM_0       => TRUE,
        -- RX 8b10b decoder
        DEC_MCOMMA_DETECT_0         => TRUE,
        DEC_PCOMMA_DETECT_0         => TRUE,
        DEC_VALID_COMMA_ONLY_0      => FALSE,
        -- RX elastic buffer
        PMA_RXSYNC_CFG_0            => X"00",                                  -- RX Elastic Buffer and Phase alignment Attributes badly described
        RX_BUFFER_USE_0             => TRUE,
        RX_EN_IDLE_RESET_BUF_0      => TRUE,
        RX_XCLK_SEL_0               => "RXREC",
        -- RX clock correction
        CLK_CORRECT_USE_0           => TRUE,
        CLK_COR_ADJ_LEN_0           => 2,
        CLK_COR_DET_LEN_0           => 1,
        CLK_COR_INSERT_IDLE_FLAG_0  => FALSE,
        CLK_COR_KEEP_IDLE_0         => FALSE,
        CLK_COR_MAX_LAT_0           => 18,
        CLK_COR_MIN_LAT_0           => 16,
        CLK_COR_PRECEDENCE_0        => TRUE,
        CLK_COR_REPEAT_WAIT_0       => 0,
        CLK_COR_SEQ_1_1_0           => "0000000000",
        CLK_COR_SEQ_1_2_0           => "0000000000",
        CLK_COR_SEQ_1_3_0           => "0000000000",
        CLK_COR_SEQ_1_4_0           => "0000000000",
        CLK_COR_SEQ_1_ENABLE_0      => "0000",
        CLK_COR_SEQ_2_1_0           => "0000000000",
        CLK_COR_SEQ_2_2_0           => "0000000000",
        CLK_COR_SEQ_2_3_0           => "0000000000",
        CLK_COR_SEQ_2_4_0           => "0000000000",
        CLK_COR_SEQ_2_ENABLE_0      => "0000",
        CLK_COR_SEQ_2_USE_0         => FALSE,
        RX_DECODE_SEQ_MATCH_0       => TRUE,
        -- RX channel bonding
        CB2_INH_CC_PERIOD_0         => 8,
        CHAN_BOND_1_MAX_SKEW_0      => 1,
        CHAN_BOND_2_MAX_SKEW_0      => 1,
        CHAN_BOND_KEEP_ALIGN_0      => FALSE,
        CHAN_BOND_LEVEL_0           => 0,
        CHAN_BOND_MODE_0            => "OFF",
        CHAN_BOND_SEQ_1_1_0         => "0000000000",
        CHAN_BOND_SEQ_1_2_0         => "0000000000",
        CHAN_BOND_SEQ_1_3_0         => "0000000000",
        CHAN_BOND_SEQ_1_4_0         => "0000000000",
        CHAN_BOND_SEQ_1_ENABLE_0    => "0000",
        CHAN_BOND_SEQ_2_1_0         => "0000000000",
        CHAN_BOND_SEQ_2_2_0         => "0000000000",
        CHAN_BOND_SEQ_2_3_0         => "0000000000",
        CHAN_BOND_SEQ_2_4_0         => "0000000000",
        CHAN_BOND_SEQ_2_ENABLE_0    => "0000",
        CHAN_BOND_SEQ_2_USE_0       => FALSE,  
        CHAN_BOND_SEQ_LEN_0         => 1,
        PCI_EXPRESS_MODE_0          => FALSE,
        -- RX 64b66b and 64b67b gearbox
        RXGEARBOX_USE_0             => FALSE,
        ------------------------------------------------------------------------
        -- TX 0
        ------------------------------------------------------------------------
        -- TX 64b66b and 64b67b gearbox
        GEARBOX_ENDEC_0             => "000", 
        TXGEARBOX_USE_0             => FALSE,
        -- TX serial line rate clocks
        PLL_TXDIVSEL_OUT_0          => 2,
        -- TX elastic buffer
        TX_BUFFER_USE_0             => TRUE,
        TX_XCLK_SEL_0               => "TXOUT",
        TXRX_INVERT_0               => "011",
        -- TX Out Of Band (OOB) beaconing
        COM_BURST_VAL_0             => "1111",
        PMA_TX_CFG_0                => X"80082",
        TX_DETECT_RX_CFG_0          => X"1832",                                -- TX Driver and OOB signalling badly documented
        TX_IDLE_DELAY_0             => "010",                                  -- TX Driver and OOB signalling badly documented
        ------------------------------------------------------------------------
        -- RX 1
        ------------------------------------------------------------------------
        -- RX serial ports
        AC_CAP_DIS_1                => TRUE,
        CM_TRIM_1                   => "10",
        RCV_TERM_GND_1              => FALSE,
        RCV_TERM_VTTRX_1            => TRUE,
        TERMINATION_IMP_1           => 50,
        -- RX Decision Feedback Equalizer(DFE)
        DFE_CFG_1                   => "1001111011",
        RX_EN_IDLE_HOLD_DFE_1       => TRUE,
        -- RX Out Of Band (OOB)
        OOBDETECT_THRESHOLD_1       => "111",
        RX_STATUS_FMT_1             => "PCIE",
        -- RX PCIexpress
        RX_IDLE_HI_CNT_1            => "1000",
        RX_IDLE_LO_CNT_1            => "0000",
        -- RX SATA
        SATA_BURST_VAL_1            => "100",
        SATA_IDLE_VAL_1             => "100",
        SATA_MAX_BURST_1            => 9,
        SATA_MAX_INIT_1             => 27,
        SATA_MAX_WAKE_1             => 9,
        SATA_MIN_BURST_1            => 5,
        SATA_MIN_INIT_1             => 15,
        SATA_MIN_WAKE_1             => 5,
        TRANS_TIME_FROM_P2_1        => X"003C",
        TRANS_TIME_NON_P2_1         => X"0019",
        TRANS_TIME_TO_P2_1          => X"0064",
        -- RX Clock Data Recovery (CDR)
        PMA_CDR_SCAN_1              => X"6404039",
        PMA_RX_CFG_1                => X"0F44088",  
        -- RX serial line rate clocks
        PLL_RXDIVSEL_OUT_1          => 2,
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBS_ERR_THRESHOLD_1        => X"00000001",
        -- RX comma detection and alignment
        ALIGN_COMMA_WORD_1          => 2,
        COMMA_10B_ENABLE_1          => "1111111111",
        COMMA_DOUBLE_1              => FALSE,
        MCOMMA_10B_VALUE_1          => "1010000011",
        MCOMMA_DETECT_1             => TRUE,
        PCOMMA_10B_VALUE_1          => "0101111100",
        PCOMMA_DETECT_1             => TRUE,
        RX_SLIDE_MODE_1             => "PCS",
        -- RX loss of sync fsm
        RX_LOS_INVALID_INCR_1       => 4,
        RX_LOS_THRESHOLD_1          => 32,
        RX_LOSS_OF_SYNC_FSM_1       => TRUE,
        -- RX 8b10b decoder
        DEC_MCOMMA_DETECT_1         => TRUE,
        DEC_PCOMMA_DETECT_1         => TRUE,
        DEC_VALID_COMMA_ONLY_1      => FALSE,
        -- RX elastic buffer
        PMA_RXSYNC_CFG_1            => X"00",                                  -- RX Elastic Buffer and Phase alignment Attributes badly described
        RX_BUFFER_USE_1             => FALSE,
        RX_EN_IDLE_RESET_BUF_1      => TRUE,
        RX_XCLK_SEL_1               => "RXUSR",
        -- RX clock correction
        CLK_CORRECT_USE_1           => TRUE,
        CLK_COR_ADJ_LEN_1           => 2,
        CLK_COR_DET_LEN_1           => 1,
        CLK_COR_INSERT_IDLE_FLAG_1  => FALSE,
        CLK_COR_KEEP_IDLE_1         => FALSE,
        CLK_COR_MAX_LAT_1           => 18,
        CLK_COR_MIN_LAT_1           => 16,
        CLK_COR_PRECEDENCE_1        => TRUE,
        CLK_COR_REPEAT_WAIT_1       => 0,
        CLK_COR_SEQ_1_1_1           => "0000000000",
        CLK_COR_SEQ_1_2_1           => "0000000000",
        CLK_COR_SEQ_1_3_1           => "0000000000",
        CLK_COR_SEQ_1_4_1           => "0000000000",
        CLK_COR_SEQ_1_ENABLE_1      => "0000",
        CLK_COR_SEQ_2_1_1           => "0000000000",
        CLK_COR_SEQ_2_2_1           => "0000000000",
        CLK_COR_SEQ_2_3_1           => "0000000000",
        CLK_COR_SEQ_2_4_1           => "0000000000",
        CLK_COR_SEQ_2_ENABLE_1      => "0000",
        CLK_COR_SEQ_2_USE_1         => FALSE,
        RX_DECODE_SEQ_MATCH_1       => TRUE,
        -- RX channel bonding
        CB2_INH_CC_PERIOD_1         => 8,
        CHAN_BOND_1_MAX_SKEW_1      => 1,
        CHAN_BOND_2_MAX_SKEW_1      => 1,
        CHAN_BOND_KEEP_ALIGN_1      => FALSE,
        CHAN_BOND_LEVEL_1           => 0,
        CHAN_BOND_MODE_1            => "OFF",
        CHAN_BOND_SEQ_1_1_1         => "0000000000",
        CHAN_BOND_SEQ_1_2_1         => "0000000000",
        CHAN_BOND_SEQ_1_3_1         => "0000000000",
        CHAN_BOND_SEQ_1_4_1         => "0000000000",
        CHAN_BOND_SEQ_1_ENABLE_1    => "0000",
        CHAN_BOND_SEQ_2_1_1         => "0000000000",
        CHAN_BOND_SEQ_2_2_1         => "0000000000",
        CHAN_BOND_SEQ_2_3_1         => "0000000000",
        CHAN_BOND_SEQ_2_4_1         => "0000000000",
        CHAN_BOND_SEQ_2_ENABLE_1    => "0000",
        CHAN_BOND_SEQ_2_USE_1       => FALSE,  
        CHAN_BOND_SEQ_LEN_1         => 1,
        PCI_EXPRESS_MODE_1          => FALSE,
        -- RX 64b66b and 64b67b gearbox
        RXGEARBOX_USE_1             => FALSE,
        ------------------------------------------------------------------------
        -- TX 1
        ------------------------------------------------------------------------
        -- TX 64b66b and 64b67b gearbox
        GEARBOX_ENDEC_1             => "000", 
        TXGEARBOX_USE_1             => FALSE,
        -- TX serial line rate clocks
        PLL_TXDIVSEL_OUT_1          => 2,
        -- TX elastic buffer
        TX_BUFFER_USE_1             => TRUE,
        TX_XCLK_SEL_1               => "TXOUT",
        TXRX_INVERT_1               => "011",
        -- TX Out Of Band (OOB) beaconing
        COM_BURST_VAL_1             => "1111",
        PMA_TX_CFG_1                => X"80082",
        TX_DETECT_RX_CFG_1          => X"1832",                                -- TX Driver and OOB signalling badly documented
        TX_IDLE_DELAY_1             => "010"                                   -- TX Driver and OOB signalling badly documented
    )
    port map
    (
        ------------------------------------------------------------------------
        -- CTRL
        ------------------------------------------------------------------------
        -- Xilinx test ports
        GTXTEST                     => "10000000000000",
        -- Global ports
        GTXRESET                    => '0',
        RESETDONE0                  => s_RESETDONE0,
        RESETDONE1                  => s_RESETDONE1,
        INTDATAWIDTH                => '1',
        -- PLL
        CLKIN                       => refclk,
        REFCLKPWRDNB                => '1',                       -- Active Low
        REFCLKOUT                   => s_REFCLKOUT,
        PLLLKDET                    => s_PLLLKDET,
        PLLLKDETEN                  => '1',
        PLLPOWERDOWN                => '0',
        -- Loopback
        LOOPBACK0                   => s_LOOPBACK0,
        LOOPBACK1                   => s_LOOPBACK1,
        ------------------------------------------------------------------------
        -- DRP
        ------------------------------------------------------------------------
        -- Dynamic Reconfiguration Port (DRP)
        DCLK                        => '0',
        DEN                         => '0',
        DWE                         => '0',
        DADDR                       => "0000000",
        DI                          => X"0000",
        DO                          => open,
        DRDY                        => open,
        ------------------------------------------------------------------------
        -- RX 0
        ------------------------------------------------------------------------
        -- RX resets
        RXRESET0                    => '0',
        -- RX power control
        RXPOWERDOWN0                => "00",
        -- RX user clocks
        RXRECCLK0                   => open,
        RXUSRCLK0                   => s_REFCLKOUT,
        RXUSRCLK20                  => s_REFCLKOUT,
        -- RX serial ports
        RXP0                        => SFP1_RX_P,
        RXN0                        => SFP1_RX_N,
        -- RX EQualizer (EQ)          
        RXENEQB0                    => '0',
        RXEQMIX0                    => "00",
        RXEQPOLE0                   => "0000",
        -- RX Decision Feedback Equalizer(DFE)
        DFECLKDLYADJ0               => "000000",
        DFECLKDLYADJMONITOR0        => open,
        DFEEYEDACMONITOR0           => open,
        DFESENSCAL0                 => open,
        DFETAP10                    => "00000",
        DFETAP1MONITOR0             => open,
        DFETAP20                    => "00000",
        DFETAP2MONITOR0             => open,
        DFETAP30                    => "0000",
        DFETAP3MONITOR0             => open,
        DFETAP40                    => "0000",
        DFETAP4MONITOR0             => open,
        -- RX Out Of Band (OOB)
        RXELECIDLE0                 => open,
        RXVALID0                    => open,
        PHYSTATUS0                  => open,
        -- RX Clock Data Recovery (CDR)
        RXCDRRESET0                 => '0',
        -- RX oversampling
        RXENSAMPLEALIGN0            => '0',
        RXOVERSAMPLEERR0            => open,
        -- RX polarity
        RXPOLARITY0                 => '0',
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBSCNTRESET0               => '0',
        RXENPRBSTST0                => "00",
        RXPRBSERR0                  => open,
        -- RX comma detection and alignment
        RXBYTEISALIGNED0            => open,
        RXBYTEREALIGN0              => open,  
        RXCOMMADET0                 => open,
        RXCOMMADETUSE0              => '1',
        RXENMCOMMAALIGN0            => '1',
        RXENPCOMMAALIGN0            => '1',
        RXSLIDE0                    => '0',
        -- RX loss of sync fsm
        RXLOSSOFSYNC0               => s_RXLOSSOFSYNC0,
        -- RX 8b10b decoder
        RXCHARISCOMMA0              => s_RXCHARISCOMMA0,
        RXCHARISK0                  => s_RXCHARISK0,
        RXDATAWIDTH0                => "01",
        RXDEC8B10BUSE0              => '1',
        RXDISPERR0                  => open,
        RXNOTINTABLE0               => open,
        RXRUNDISP0                  => open,
        -- RX elastic buffer
        RXBUFRESET0                 => '0',
        RXBUFSTATUS0                => open,
        RXENPMAPHASEALIGN0          => '0',
        RXPMASETPHASE0              => '0',
        RXSTATUS0                   => open,
        -- RX clock correction
        RXCLKCORCNT0                => open,
        -- RX channel bonding
        RXCHANBONDSEQ0              => open,
        RXCHANISALIGNED0            => open,
        RXCHANREALIGN0              => open,
        RXCHBONDI0                  => "0000",
        RXCHBONDO0                  => open,
        RXENCHANSYNC0               => '0',
        -- RX 64b66b and 64b67b gearbox
        RXDATAVALID0                => open,
        RXGEARBOXSLIP0              => '0',
        RXHEADER0                   => open,
        RXHEADERVALID0              => open,
        RXSTARTOFSEQ0               => open,
        -- RX data ports
        RXDATA0                     => s_RXDATA0,
        ------------------------------------------------------------------------
        -- TX 0
        ------------------------------------------------------------------------
        -- TX resets
        TXRESET0                    => '0',
        -- TX power control
        TXPOWERDOWN0                => "00",
        -- TX user clocks
        TXOUTCLK0                   => open,
        TXUSRCLK0                   => s_REFCLKOUT,
        TXUSRCLK20                  => s_REFCLKOUT,
        -- TX data ports
        TXDATAWIDTH0                => "01",
        TXDATA0                     => s_TXDATA0,
        -- TX 8b10b encoder
        TXBYPASS8B10B0              => "0000",
        TXCHARDISPMODE0             => "0000",
        TXCHARDISPVAL0              => "0000",
        TXCHARISK0                  => s_TXCHARISK0,
        TXENC8B10BUSE0              => '1',
        TXKERR0                     => open,
        TXRUNDISP0                  => open,
        -- TX 64b66b and 64b67b gearbox
        TXGEARBOXREADY0             => open,
        TXHEADER0                   => "000",
        TXSEQUENCE0                 => "0000000",
        TXSTARTSEQ0                 => '0',
        -- TX Pseudo Random Bit Sequences (PRBS)
        TXENPRBSTST0                => "00",
        -- TX elastic buffer
        TXBUFSTATUS0                => open,
        -- TX phase alignment fifo
        TXENPMAPHASEALIGN0          => '0',
        TXPMASETPHASE0              => '0',
        -- TX polarity
        TXPOLARITY0                 => '0',
        -- TX Out Of Band (OOB) beaconing
        TXELECIDLE0                 => '0',
        -- TX PCIexpress
        TXDETECTRX0                 => '0',
        -- TX SATA
        TXCOMSTART0                 => '0',
        TXCOMTYPE0                  => '0',
        -- TX driver
        TXBUFDIFFCTRL0              => "101",
        TXDIFFCTRL0                 => "000",
        TXPREEMPHASIS0(3)           => '0',
        TXPREEMPHASIS0(2 downto 0)  => "000",
        TXINHIBIT0                  => '0',
        -- TX serial ports
        TXP0                        => SFP1_TX_P,
        TXN0                        => SFP1_TX_N,
        ------------------------------------------------------------------------
        -- RX 1
        ------------------------------------------------------------------------
        -- RX resets
        RXRESET1                    => '0',
        -- RX power control
        RXPOWERDOWN1                => "00",
        -- RX user clocks
        RXRECCLK1                   => open,
        RXUSRCLK1                   => s_REFCLKOUT,
        RXUSRCLK21                  => s_REFCLKOUT,
        -- RX serial ports
        RXP1                        => SFP2_RX_P,
        RXN1                        => SFP2_RX_N,
        -- RX EQualizer (EQ)          
        RXENEQB1                    => '0',
        RXEQMIX1                    => "00",
        RXEQPOLE1                   => "0000",
        -- RX Decision Feedback Equalizer(DFE)
        DFECLKDLYADJ1               => "000000",
        DFECLKDLYADJMONITOR1        => open,
        DFEEYEDACMONITOR1           => open,
        DFESENSCAL1                 => open,
        DFETAP11                    => "00000",
        DFETAP1MONITOR1             => open,
        DFETAP21                    => "00000",
        DFETAP2MONITOR1             => open,
        DFETAP31                    => "0000",
        DFETAP3MONITOR1             => open,
        DFETAP41                    => "0000",
        DFETAP4MONITOR1             => open,
        -- RX Out Of Band (OOB)
        RXELECIDLE1                 => open,
        RXVALID1                    => open,
        PHYSTATUS1                  => open,
        -- RX Clock Data Recovery (CDR)
        RXCDRRESET1                 => '0',
        -- RX oversampling
        RXENSAMPLEALIGN1            => '0',
        RXOVERSAMPLEERR1            => open,
        -- RX polarity
        RXPOLARITY1                 => '0',
        -- RX Pseudo Random Bit Sequences (PRBS)
        PRBSCNTRESET1               => '0',
        RXENPRBSTST1                => "00",
        RXPRBSERR1                  => open,
        -- RX comma detection and alignment
        RXBYTEISALIGNED1            => open,
        RXBYTEREALIGN1              => open,  
        RXCOMMADET1                 => open,     
        RXCOMMADETUSE1              => '1',
        RXENMCOMMAALIGN1            => '1',
        RXENPCOMMAALIGN1            => '1',
        RXSLIDE1                    => '0',
        -- RX loss of sync fsm
        RXLOSSOFSYNC1               => s_RXLOSSOFSYNC1,
        -- RX 8b10b decoder
        RXCHARISCOMMA1              => open,
        RXCHARISK1                  => open,
        RXDATAWIDTH1                => "01",
        RXDEC8B10BUSE1              => '1',
        RXDISPERR1                  => open,
        RXNOTINTABLE1               => open,
        RXRUNDISP1                  => open,
        -- RX elastic buffer
        RXBUFRESET1                 => '0',
        RXBUFSTATUS1                => open,
        RXENPMAPHASEALIGN1          => '0',
        RXPMASETPHASE1              => '0',
        RXSTATUS1                   => open,
        -- RX clock correction
        RXCLKCORCNT1                => open,
        -- RX channel bonding
        RXCHANBONDSEQ1              => open,
        RXCHANISALIGNED1            => open,
        RXCHANREALIGN1              => open,
        RXCHBONDI1                  => "0000",
        RXCHBONDO1                  => open,
        RXENCHANSYNC1               => '0',
        -- RX 64b66b and 64b67b gearbox
        RXDATAVALID1                => open,
        RXGEARBOXSLIP1              => '0',
        RXHEADER1                   => open,
        RXHEADERVALID1              => open,
        RXSTARTOFSEQ1               => open,
        -- RX data ports
        RXDATA1                     => s_RXDATA1,
        ------------------------------------------------------------------------
        -- TX 1
        ------------------------------------------------------------------------
        -- TX resets
        TXRESET1                    => '0',
        -- TX power control
        TXPOWERDOWN1                => "00",
        -- TX user clocks
        TXOUTCLK1                   => open,
        TXUSRCLK1                   => s_REFCLKOUT,
        TXUSRCLK21                  => s_REFCLKOUT,
        -- TX data ports
        TXDATAWIDTH1                => "01",
        TXDATA1                     => s_TXDATA1,
        -- TX 8b10b encoder
        TXBYPASS8B10B1              => "0000",
        TXCHARDISPMODE1             => "0000",
        TXCHARDISPVAL1              => "0000",
        TXCHARISK1                  => s_TXCHARISK1,
        TXENC8B10BUSE1              => '1',
        TXKERR1                     => open,
        TXRUNDISP1                  => open,
        -- TX 64b66b and 64b67b gearbox
        TXGEARBOXREADY1             => open,
        TXHEADER1                   => "000",
        TXSEQUENCE1                 => "0000000",
        TXSTARTSEQ1                 => '0',
        -- TX Pseudo Random Bit Sequences (PRBS)
        TXENPRBSTST1                => "00",
        -- TX elastic buffer
        TXBUFSTATUS1                => open,
        -- TX phase alignment fifo
        TXENPMAPHASEALIGN1          => '0',
        TXPMASETPHASE1              => '0',
        -- TX polarity
        TXPOLARITY1                 => '0',
        -- TX Out Of Band (OOB) beaconing
        TXELECIDLE1                 => '0',
        -- TX PCIexpress
        TXDETECTRX1                 => '0',
        -- TX SATA
        TXCOMSTART1                 => '0',
        TXCOMTYPE1                  => '0',
        -- TX driver
        TXBUFDIFFCTRL1              => "101",
        TXDIFFCTRL1                 => "000",
        TXPREEMPHASIS1(3)           => '0',
        TXPREEMPHASIS1(2 downto 0)  => "000",
        TXINHIBIT1                  => '0',
        -- TX serial ports
        TXP1                        => SFP2_TX_P,
        TXN1                        => SFP2_TX_N
    );

    ---------------------------------------------------------------------------
    -- GTX reference clock buffering(low jitter)
    ---------------------------------------------------------------------------
    refclk_ibufds_inst: IBUFDS
    port map
    (
      I     => CLK_MGT_P,
      IB    => CLK_MGT_N,
      O     => refclk
    );

    ---------------------------------------------------------------------------
    -- Loopback statistics
    ---------------------------------------------------------------------------
    loopback_statistics_inst: mgt_loopback_statistics
    port map
    (
        clk                         => s_REFCLKOUT,
        rst                         => rst,
        en_seqgen                   => not s_RXLOSSOFSYNC0(1),
        en_error_counter            => not s_RXLOSSOFSYNC0(1),    
        seq_rcv                     => s_RXDATA0(15 downto 0),
        seq_snd                     => s_seq_snd,
        error_count                 => s_error_count,
        lossofsync                  => s_RXLOSSOFSYNC0(1),
        lossofsync_count            => s_lossofsync_count,
        latency                     => s_latency
    );

    ---------------------------------------------------------------------------
    -- Bandwidth statistics
    ---------------------------------------------------------------------------
    bandwidth_statistics_RX0_inst: mgt_bandwidth_statistics
    port map
    (
        clk         => s_REFCLKOUT,
        rst         => rst,
        opmode      => "00",
        timeframe   => x"07735940",
        nbytes      => s_nbytes_RX0,
        trigger     => '0',
        bandwidth   => s_bandwidth_RX0
    );
    
    -- Only sum up number of bytes received to bandwidth statistics when the
    -- received data is not a K character. Since a 16-bit interface is beeing
    -- used, each received data counts for 2 bytes.
    s_nbytes_RX0 <= "10" when s_RXCHARISK0(1 downto 0) = "00" and
                              s_RXLOSSOFSYNC0(1) = '0' else
                    "00";                   

    ---------------------------------------------------------------------------
    -- Bandwidth statistics
    ---------------------------------------------------------------------------
    -- Control bandwidth of data sending TX0 of the GTX transceiver
    process(s_REFCLKOUT)
    begin
        if rising_edge(s_REFCLKOUT) then
            s_count <= s_count - 1;

            if s_count <= unsigned(s_datarate) then
                s_send_data <= '1' and (not s_RXLOSSOFSYNC0(1)) and (not s_RXLOSSOFSYNC0(1));
            else
                s_send_data <= '0';
            end if;
        end if;
    end process;

    -- Send K characters (0xBC) when no sync is detected or TX0 send is disabled
    s_TXDATA0    <= X"0000" & s_seq_snd when (s_RXLOSSOFSYNC0(1) = '0' or
                                             s_RXLOSSOFSYNC1(1) = '0') and
                                             s_send_data = '1'
                                        else X"000000BC";

    s_TXCHARISK0 <= X"0"                when (s_RXLOSSOFSYNC0(1) = '0' or
                                             s_RXLOSSOFSYNC1(1) = '0') and
                                             s_send_data = '1'
                                        else X"1";

    ---------------------------------------------------------------------------
    -- VIO interface 
    ---------------------------------------------------------------------------
    icon_inst: ICON
    port map
    (
        CONTROL0 => icon_control0
    );
    
    vio_inst: VIO
    port map
    (
        CONTROL => icon_control0,
        CLK => s_REFCLKOUT,
        SYNC_IN => vio_in,
        SYNC_OUT => vio_out
    );

    rst                     <= vio_out(  0);
    s_LOOPBACK0             <= vio_out(  3 downto   1);
    s_LOOPBACK1             <= vio_out(  6 downto   4);
    s_datarate              <= vio_out( 22 downto   7);

    vio_in(  0)             <= s_PLLLKDET;
    vio_in(  2 downto   1)  <= s_RXLOSSOFSYNC0;
    vio_in(  4 downto   3)  <= s_RXLOSSOFSYNC1;
    vio_in( 36 downto   5)  <= s_error_count;
    vio_in( 68 downto  37)  <= s_lossofsync_count;
    vio_in( 84 downto  69)  <= s_latency;
    vio_in(116 downto  85)  <= s_bandwidth_RX0;

    ------------------------------------------------------------------------
    -- Loopback of GTX (RX1-TX1) in FPGA fabric
    ------------------------------------------------------------------------
    s_TXDATA1       <= s_RXDATA1;
    s_TXCHARISK1    <= s_RXCHARISK1;

    ------------------------------------------------------------------------
    -- SFP control
    ------------------------------------------------------------------------
    SFP1_CTRL_TX_DISABLE <= '0';
    SFP2_CTRL_TX_DISABLE <= '0';
    SFP1_1MGT_SCL <= '0';
    SFP2_1MGT_SCL <= '0';

end structural;