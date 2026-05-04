--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals

    component clock_divider is
        generic ( constant k_DIV : natural := 2 );
        port (  i_clk   : in  std_logic;
                i_reset : in  std_logic;
                o_clk   : out std_logic );
    end component clock_divider;
   
    component button_debounce is
        port (  clk    : in  std_logic;
                reset  : in  std_logic;
                button : in  std_logic;
                action : out std_logic );
    end component button_debounce;
  
    component controller_fsm is
        port (  i_clk   : in  std_logic;
                i_reset : in  std_logic;
                i_adv   : in  std_logic;
                o_cycle : out std_logic_vector(3 downto 0) );
    end component controller_fsm;
  
  
    component ALU is
        port (  i_A      : in  std_logic_vector(7 downto 0);
                i_B      : in  std_logic_vector(7 downto 0);
                i_op     : in  std_logic_vector(2 downto 0);
                o_result : out std_logic_vector(7 downto 0);
                o_flags  : out std_logic_vector(3 downto 0) );
    end component ALU;
    
    component twos_comp is
        port (  i_bin  : in  std_logic_vector(7 downto 0);
                o_sign : out std_logic;
                o_hund : out std_logic_vector(3 downto 0);
                o_tens : out std_logic_vector(3 downto 0);
                o_ones : out std_logic_vector(3 downto 0) );
    end component twos_comp;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural := 4 );
        port (  i_clk   : in  std_logic;
                i_reset : in  std_logic;
                i_D3    : in  std_logic_vector(3 downto 0);
                i_D2    : in  std_logic_vector(3 downto 0);
                i_D1    : in  std_logic_vector(3 downto 0);
                i_D0    : in  std_logic_vector(3 downto 0);
                o_data  : out std_logic_vector(3 downto 0);
                o_sel   : out std_logic_vector(3 downto 0) );
    end component TDM4;
    
    component sevenseg_decoder is
        port (  i_hex : in  std_logic_vector(3 downto 0);
                o_seg : out std_logic_vector(6 downto 0) );
    end component sevenseg_decoder;
    
    signal w_clk_slow   : std_logic;
    signal w_cycle      : std_logic_vector(3 downto 0);
    signal w_adv        : std_logic;
    signal f_regA       : std_logic_vector(7 downto 0) := (others => '0');
    signal f_regB       : std_logic_vector(7 downto 0) := (others => '0');
    signal w_alu_result : std_logic_vector(7 downto 0);
    signal w_alu_flags  : std_logic_vector(3 downto 0);
    signal w_display    : std_logic_vector(7 downto 0);
    signal w_sign       : std_logic;
    signal w_hund       : std_logic_vector(3 downto 0);
    signal w_tens       : std_logic_vector(3 downto 0);
    signal w_ones       : std_logic_vector(3 downto 0);
    signal w_tdm_data   : std_logic_vector(3 downto 0);
    signal w_tdm_sel    : std_logic_vector(3 downto 0);
    signal w_tdm_D3     : std_logic_vector(3 downto 0);
    signal w_seg_raw    : std_logic_vector(6 downto 0);
    constant k_MINUS_SEG : std_logic_vector(6 downto 0) := "0111111";
begin
	-- PORT MAPS ----------------------------------------
    clk_div : clock_divider
        generic map ( k_DIV => 500000 )
        port map (
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => w_clk_slow
        );
        debounce_inst : button_debounce
        port map (
            clk    => w_clk_slow,
            reset  => btnU,
            button => btnC,
            action => w_adv
        );
        fsm_inst : controller_fsm
            port map (
                i_clk   => w_clk_slow,
                i_reset => btnU,
                i_adv   => w_adv,
                o_cycle => w_cycle
            );
        alu_inst : ALU
        port map (
            i_A      => f_regA,
            i_B      => f_regB,
            i_op     => sw(2 downto 0),
            o_result => w_alu_result,
            o_flags  => w_alu_flags
        );
        tc_inst : twos_comp
        port map (
            i_bin  => w_display,
            o_sign => w_sign,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );
        tdm_inst : TDM4
        generic map ( k_WIDTH => 4 )
        port map (
            i_clk   => w_clk_slow,
            i_reset => btnU,
            i_D3    => w_tdm_D3,
            i_D2    => w_hund,
            i_D1    => w_tens,
            i_D0    => w_ones,
            o_data  => w_tdm_data,
            o_sel   => w_tdm_sel
        );
        seg_dec_inst : sevenseg_decoder
        port map (
            i_hex => w_tdm_data,
            o_seg => w_seg_raw
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
	reg_latch : process(w_clk_slow)
    begin
        if rising_edge(w_clk_slow) then
            if btnU = '1' then
                f_regA <= (others => '0');
                f_regB <= (others => '0');
            else
                if w_cycle(1) = '1' then
                    f_regA <= sw(7 downto 0);
                end if;
                if w_cycle(2) = '1' then
                    f_regB <= sw(7 downto 0);
                end if;
            end if;
        end if;
    end process reg_latch;
    w_display <= f_regA       when w_cycle(1) = '1' else
                 f_regB       when w_cycle(2) = '1' else
                 w_alu_result when w_cycle(3) = '1' else
                 (others => '0');
    w_tdm_D3 <= x"F" when w_sign = '1' else x"0";
    seg <= k_MINUS_SEG when (w_tdm_sel = "0111" and w_sign = '1')
           else w_seg_raw;          
	an <= "1111" when w_cycle(0) = '1' else w_tdm_sel;
	led(3 downto 0)   <= w_cycle;
    led(11 downto 4)  <= (others => '0');
    led(15 downto 12) <= w_alu_flags;
end top_basys3_arch;
