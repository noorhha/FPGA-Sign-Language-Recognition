library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity test is
    port (
        CLOCK_50  : in  STD_LOGIC;
        flex      : in  STD_LOGIC_VECTOR(4 downto 0);
        KEY       : in  STD_LOGIC_VECTOR(1 downto 0);
 
        LEDR      : out STD_LOGIC_VECTOR(4 downto 0);
 
        LCD_DATA  : out STD_LOGIC_VECTOR(7 downto 0);
        LCD_EN    : out STD_LOGIC;
        LCD_RS    : out STD_LOGIC;
        LCD_RW    : out STD_LOGIC;
        LCD_ON    : out STD_LOGIC;
        LCD_BLON  : out STD_LOGIC
    );
end test;
 
architecture Behavioral of test is
 
    type state_type is (POWER_WAIT, LOAD_STEP, EN_HIGH, EN_LOW, WAIT_STEP, NEXT_STEP);
    signal state : state_type := POWER_WAIT;
 
    type word_array is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    signal saved_word : word_array := (others => x"20");
 
    signal word_index : integer range 0 to 15 := 0;
 
    signal delay_count : integer := 0;
    signal step        : integer range 0 to 37 := 0;
 
    signal lcd_data_reg : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal lcd_rs_reg   : STD_LOGIC := '0';
    signal lcd_en_reg   : STD_LOGIC := '0';
 
    signal key0_prev : STD_LOGIC := '1';
    signal key1_prev : STD_LOGIC := '1';
 
    signal key_delay : integer range 0 to 5000000 := 0;
 
    constant POWER_DELAY : integer := 2500000;
    constant STEP_DELAY  : integer := 100000;
    constant EN_DELAY    : integer := 50000;
 
    function bit_char(b : STD_LOGIC) return STD_LOGIC_VECTOR is
    begin
        if b = '1' then
            return x"31";
        else
            return x"30";
        end if;
    end function;
 
    function letter_char(f : STD_LOGIC_VECTOR(4 downto 0)) return STD_LOGIC_VECTOR is
    begin
        case f is
            when "00000" => return x"41";
            when "00001" => return x"42";
            when "00010" => return x"43";
            when "00011" => return x"44";
            when "00100" => return x"45";
            when "00101" => return x"46";
            when "00110" => return x"47";
            when "00111" => return x"48";
            when "01000" => return x"49";
            when "01001" => return x"4A";
            when "01010" => return x"4B";
            when "01011" => return x"4C";
            when "01100" => return x"4D";
            when "01101" => return x"4E";
            when "01110" => return x"4F";
            when "01111" => return x"50";
            when "10000" => return x"51";
            when "10001" => return x"52";
            when "10010" => return x"53";
            when "10011" => return x"54";
            when "10100" => return x"55";
            when "10101" => return x"56";
            when "10110" => return x"57";
            when "10111" => return x"58";
            when "11000" => return x"59";
            when "11001" => return x"5A";
            when others  => return x"3F";
        end case;
    end function;
 
    function get_rs(s : integer) return STD_LOGIC is
    begin
        if (s = 0) or (s = 17) then
            return '0';
        else
            return '1';
        end if;
    end function;
 
    function word_output(pos : integer; w : word_array) return STD_LOGIC_VECTOR is
    begin
        case pos is
            when 0  => return w(0);
            when 1  => return w(1);
            when 2  => return w(2);
            when 3  => return w(3);
            when 4  => return w(4);
            when 5  => return w(5);
            when 6  => return w(6);
            when 7  => return w(7);
            when 8  => return w(8);
            when 9  => return w(9);
            when 10 => return w(10);
            when 11 => return w(11);
            when 12 => return w(12);
            when 13 => return w(13);
            when 14 => return w(14);
            when 15 => return w(15);
            when others => return x"20";
        end case;
    end function;
 
    function get_data(s : integer; f : STD_LOGIC_VECTOR(4 downto 0); w : word_array) return STD_LOGIC_VECTOR is
    begin
        case s is
            when 0  => return x"80";
 
            when 1  => return x"43";
            when 2  => return x"55";
            when 3  => return x"52";
            when 4  => return x"3A";
            when 5  => return x"20";
            when 6  => return letter_char(f);
            when 7  => return x"20";
            when 8  => return bit_char(f(4));
            when 9  => return bit_char(f(3));
            when 10 => return bit_char(f(2));
            when 11 => return bit_char(f(1));
            when 12 => return bit_char(f(0));
            when 13 => return x"20";
            when 14 => return x"20";
            when 15 => return x"20";
            when 16 => return x"20";
 
            when 17 => return x"C0";
 
            when 18 => return word_output(0, w);
            when 19 => return word_output(1, w);
            when 20 => return word_output(2, w);
            when 21 => return word_output(3, w);
            when 22 => return word_output(4, w);
            when 23 => return word_output(5, w);
            when 24 => return word_output(6, w);
            when 25 => return word_output(7, w);
            when 26 => return word_output(8, w);
            when 27 => return word_output(9, w);
            when 28 => return word_output(10, w);
            when 29 => return word_output(11, w);
            when 30 => return word_output(12, w);
            when 31 => return word_output(13, w);
            when 32 => return word_output(14, w);
            when 33 => return word_output(15, w);
 
            when others => return x"20";
        end case;
    end function;
 
begin
 
    LEDR <= flex;
 
    LCD_DATA <= lcd_data_reg;
    LCD_RS   <= lcd_rs_reg;
    LCD_EN   <= lcd_en_reg;
    LCD_RW   <= '0';
    LCD_ON   <= '1';
    LCD_BLON <= '1';
 
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
 
            if key_delay > 0 then
                key_delay <= key_delay - 1;
            end if;
 
            if key_delay = 0 then
                if key0_prev = '1' and KEY(0) = '0' then
                    saved_word(word_index) <= letter_char(flex);
                    if word_index < 15 then
                        word_index <= word_index + 1;
                    end if;
                    key_delay <= 5000000;
                end if;
 
                if key1_prev = '1' and KEY(1) = '0' then
                    saved_word <= (others => x"20");
                    word_index <= 0;
                    key_delay <= 5000000;
                end if;
            end if;
 
            key0_prev <= KEY(0);
            key1_prev <= KEY(1);
 
            case state is
 
                when POWER_WAIT =>
                    lcd_en_reg <= '0';
                    lcd_rs_reg <= '0';
                    lcd_data_reg <= x"38";
 
                    if delay_count < POWER_DELAY then
                        delay_count <= delay_count + 1;
                    else
                        delay_count <= 0;
                        step <= 0;
                        state <= LOAD_STEP;
                    end if;
 
                when LOAD_STEP =>
                    if step = 0 then
                        lcd_data_reg <= x"38";
                        lcd_rs_reg <= '0';
 
                    elsif step = 1 then
                        lcd_data_reg <= x"0C";
                        lcd_rs_reg <= '0';
 
                    elsif step = 2 then
                        lcd_data_reg <= x"01";
                        lcd_rs_reg <= '0';
 
                    elsif step = 3 then
                        lcd_data_reg <= x"06";
                        lcd_rs_reg <= '0';
 
                    else
                        lcd_data_reg <= get_data(step - 4, flex, saved_word);
                        lcd_rs_reg <= get_rs(step - 4);
                    end if;
 
                    lcd_en_reg <= '0';
                    delay_count <= 0;
                    state <= EN_HIGH;
 
                when EN_HIGH =>
                    lcd_en_reg <= '1';
 
                    if delay_count < EN_DELAY then
                        delay_count <= delay_count + 1;
                    else
                        delay_count <= 0;
                        state <= EN_LOW;
                    end if;
 
                when EN_LOW =>
                    lcd_en_reg <= '0';
 
                    if delay_count < EN_DELAY then
                        delay_count <= delay_count + 1;
                    else
                        delay_count <= 0;
                        state <= WAIT_STEP;
                    end if;
 
                when WAIT_STEP =>
                    if delay_count < STEP_DELAY then
                        delay_count <= delay_count + 1;
                    else
                        delay_count <= 0;
                        state <= NEXT_STEP;
                    end if;
 
                when NEXT_STEP =>
                    if step < 37 then
                        step <= step + 1;
                    else
                        step <= 4;
                    end if;
 
                    state <= LOAD_STEP;
 
            end case;
 
        end if;
    end process;
 
end Behavioral;