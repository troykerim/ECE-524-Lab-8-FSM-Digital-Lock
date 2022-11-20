--Top FSM 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity top_fsm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           led : out STD_LOGIC_VECTOR (3 downto 0));
end top_fsm;

architecture Behavioral of top_fsm is
    component debounce is 
    generic(
        counter_size: integer := 21);
    port(clk : in std_logic;
         rst : in std_logic;
         sig_i : in std_logic;
         sig_o : out std_logic
        );
    end component;
    type StateType is (LOCK, S1, S2, S3, UNLOCK, W1, W2, W3, ALARM, A1, R1, R2, R3, RESET);
    signal current_state: StateType := LOCK;
    signal east_btn : std_logic := '0';   
    signal south_btn : std_logic := '0';
    signal west_btn : std_logic := '0';
    signal north_btn : std_logic := '0';
    
--East, West, South, North is the Order

    --signal for synchronizer and edge detector
    signal east_reg: std_logic_vector(1 downto 0);
    signal east_pulse: std_logic;    
    signal south_reg: std_logic_vector(1 downto 0);
    signal south_pulse: std_logic;
    signal west_reg: std_logic_vector(1 downto 0);
    signal west_pulse: std_logic;
    signal north_reg: std_logic_vector(1 downto 0);
    signal north_pulse: std_logic;

    --LED patterns
    signal unlock_pattern: std_logic_vector(3 downto 0) := "1010";
    signal alarm_pattern: std_logic_vector(3 downto 0) := "1100";
    signal counter: integer := 0;
    
begin
    DBUNO: debounce port map(clk => clk, rst => rst, sig_i => btn(0), sig_o => east_btn);
    DBUN1: debounce port map(clk => clk, rst => rst, sig_i => btn(1), sig_o => south_btn);
    DBUN2: debounce port map(clk => clk, rst => rst, sig_i => btn(2), sig_o => west_btn);
    DBUN3: debounce port map(clk => clk, rst => rst, sig_i => btn(3), sig_o => north_btn);
    
    EDGE_DETECTOR: process(clk, rst)
    begin
        if rst = '1' then
            east_reg <= (others => '0');
            east_pulse <= '0';
            south_reg <= (others => '0');
            south_pulse <= '0';
            west_reg <= (others => '0');
            west_pulse <= '0';
            north_reg <= (others => '0');
            north_pulse <= '0';
        elsif rising_edge(clk) then
            east_reg(0) <= east_btn;
            east_reg(1) <= east_reg(0);
            east_pulse <= (NOT east_reg(1)) AND east_reg(0);

            south_reg(0) <= south_btn;
            south_reg(1) <= south_reg(0);
            south_pulse <= (NOT south_reg(1)) AND south_reg(0);
            

            west_reg(0) <= west_btn;
            west_reg(1) <= west_reg(0);
            west_pulse <= (NOT west_reg(1)) AND west_reg(0);

            north_reg(0) <= north_btn;
            north_reg(1) <= north_reg(0);
            north_pulse <= (NOT north_reg(1)) AND north_reg(0);
        end if;
    end process;
    
    --FSM process
    FSM: process(clk, rst)
    begin
        if rst = '1' then
            --
        elsif rising_edge(clk) then
            if current_state = LOCK then -- Lock State
                led <= "0000";
                if south_pulse = '1' then
                    current_state <= S1;
                elsif east_pulse = '1' then
                    current_state <= R1;
                elsif north_pulse = '1' or west_pulse = '1' then
                    current_state <= W1;
                else
                    current_state <= LOCK;
                end if;

            elsif current_state = S1 then --State 1
                led <= "0001";
                if west_pulse = '1' then
                    current_state <= S2;
                elsif east_pulse = '1' then
                    current_state <= R2;
                elsif north_pulse = '1' or south_pulse = '1' then
                    current_state <= W2;
                else
                    current_state <= S1;
                end if;

            elsif current_state = S2 then --State 2
                led <= "0011";
                if east_pulse = '1' then
                    current_state <= S3;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= W3;
                else
                    current_state <= S2;
                end if;
            
            elsif current_state = S3 then --State 3
                led <= "0111";
                if west_pulse = '1'then
                    current_state <= UNLOCK;
                elsif east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' then
                    current_state <= ALARM;
                else
                    current_state <= S3;
                end if;

            elsif current_state = UNLOCK then --Unlock state
                led <= unlock_pattern;
                if north_pulse = '1' or south_pulse = '1' or west_pulse = '1' or east_pulse = '1' then
                    current_state <= LOCK;
                else
                    current_state <= UNLOCK;
                end if;
            
            elsif current_state = W1 then-- Wrong 1
                led <= "0001";
                if east_pulse = '1' then
                    current_state <= R2;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= W2;
                else 
                    current_state <= W1;
                end if;
            elsif current_state = W2 then-- Wrong 2
                led <= "0011";
                if east_pulse = '1' then
                    current_state <= R3;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= W3;
                else 
                    current_state <= W2;
                end if;            

            elsif current_state = W3 then -- Wrong 3
                led <= "0111";
                if north_pulse = '1' or south_pulse = '1' or west_pulse = '1' or east_pulse = '1' then
                    current_state <= ALARM;
                else
                    current_state <= W3;
                end if;      
            
            elsif current_state = ALARM then --ALARM state
                led <= alarm_pattern;
                if east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' or east_pulse = '1' then
                    current_state <= ALARM;
                else
                    current_state <= ALARM;
                end if;
            elsif current_state = A1 then --A1 state
                led <= alarm_pattern;
                if east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= ALARM;
                else
                    current_state <= A1;
                end if;
            elsif current_state = R1 then --R1 state
                led <= "0001";
                if east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= W2;
                else
                    current_state <= R1;
                end if;
            elsif current_state = R2 then
                led <= "0011";
                if east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= W3;
                else 
                    current_state <= R2;
                end if;
            elsif current_state = R3 then
                led <= "0111";
                if east_pulse = '1' then
                    current_state <= RESET;
                elsif north_pulse = '1' or south_pulse = '1' or west_pulse = '1' then
                    current_state <= ALARM;
                else
                    current_state <= R3;
                end if;
            elsif current_state <= RESET then 
                led <= "0000";
                current_state <= LOCK;
            else
                current_state <= current_state;
                    
            end if;
        end if;
    end process;
    COUNTER_I: process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            alarm_pattern <= "1100";
            unlock_pattern <= "1010";
        elsif rising_edge(clk) then
            if counter <= 20_000_000 then
                counter <= counter + 1;
            else 
                counter <= 0;
                alarm_pattern <= not alarm_pattern;
                unlock_pattern <= not unlock_pattern;
            end if;
        end if;
    end process;

end Behavioral;
