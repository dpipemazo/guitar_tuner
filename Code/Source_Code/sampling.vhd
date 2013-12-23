--
-- sampling.vhd 
--
-- The unit responsible for the sampling 
--  of the audio data and storing it the 
--  SPARTAN 6's BRAM resources. There are supposedly
--  2.1 Mbits of this BRAM, so yeah, bring it on. 
--
--
--  Each BRAM can store 18Kbits of data. Our Spartan 6
--  has 116 of these blocks. We're going to initially store
--  the sample in the BRAM, and then take out the sample and 
--  compute the autocorrelation value and then put the 
--  autocorrelation value back into the RAM. So the 
--  amount of samples which we can fit in the RAM is
--  totally dependent on how large our autocorrelation values 
--  are and not the sample size (which is 2 bits)
--
-- If we sample at 100KHz, we need to take 5k samples
--  in order to recognize 20Hz as a minimum frequency. 
-- So, we will use 5 BRAM blocks, configured at 16bitsx1024. 
--  We will fill the 5 BRAMs with samples @ 100KHz and then 
-- process the autocorrelation values in batches of 128
--  in order to save space. 
--
-- The autocorrelation will be performed in the following manner
--  1. 128 samples will be loaded into the autocorrelation unit. 
--  2. The entire sample set will be shifted through each of the 
--      128 units in parallel, allowing for the full autocorrelation
--      values for these 128 samples to be computed. 
--  3. The maximum of the 128 autocorrelation values will be kept, 
--      and the next 128 samples will be loaded in. 
--  4. The process will continue until all 5K samples have been
--      processed, and the maximum value will be deemed to be the 
--      detected frequency.
--
-- We will be inferring the BRAM units for now. Hopefully this works.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.autocorrelation;

-- Entity declaration
entity SAMPLING is

    generic(
        -- The number of samples to take
        num_samples     : integer := 5120;
        -- How many samples to process at a time in the autocorrelation
        auto_block_size : integer := 128
    ); 
    
    port(
        -- system clock
        clk         : in std_logic;

        -- sample clock
        sample_clock : in std_logic;

        -- signals to start/stop sampling
        start : in std_logic;
        done  : out std_logic;

        -- Comparator results
        sig_pos : in std_logic;
        sig_neg : in std_logic;

        -- Frequency Results
        detected_freq : out std_logic_vector(31 downto 0);

        -- Gain control signals
        gain_start          : out std_logic;
        gain_inc_dec        : out std_logic;
        gain_reset          : out std_logic;
        gain_done           : in std_logic;
        gain_diff           : out std_logic_vector(12 downto 0) 

    );

end SAMPLING;

architecture behavioral of sampling is
    
    -- divider
    component sampling_div
        port (
            clk: in std_logic;
            nd: in std_logic;
            rdy: out std_logic;
            rfd: out std_logic;
            dividend: in std_logic_vector(31 downto 0);
            divisor: in std_logic_vector(12 downto 0);
            quotient: out std_logic_vector(31 downto 0);
            fractional: out std_logic_vector(3 downto 0)
        );
    end component;

    -- States for internal control mechanism
    type sample_states is(
        IDLE, 
        SAMPLE, 
        AUTO_INIT, 
        AUTO_LOAD_SAMPLES, 
        AUTO_RUN, 
        AUTO_GET_MAX,
        FREQUENCY, 
        CHECK_CLIPPING, 
        INC_GAIN, 
        DEC_GAIN, 
        GAIN_CHANGE_WAIT
    );

    signal curr_state : sample_states;

    type sampling_states is(
        SAMPLE_IDLE, 
        SAMPLE_INIT,
        SAMPLE_GET, 
        SAMPLE_THRESHOLDS
    );
    signal sample_state : sampling_states;

     -- "GO" signals for the state machine
    signal do_sample : std_logic;
    -- "DONE" signals for the state machine
    signal sample_done : std_logic;
    signal auto_done : std_logic;
    signal freq_done : std_logic;

    --
    -- SAMPLE_MEMORY. Make it 8192K even though we're only using 5K for now
    --  in order to make the compiler happy for indexing purporses which I GUESS
    --  make some sense.
    --
    type sample_memory_type is array(8191 downto 0) of std_logic_vector(1 downto 0);
    signal sample_memory : sample_memory_type;

    -- get the compiler to infer BRAM.
    attribute ram_style : string;
    attribute ram_style of sample_memory : signal is "block";

    -- For the sampling process
    signal sample_count : std_logic_vector(12 downto 0);

    -- For the autocorrelation computations
    signal cycle_count : std_logic_vector(5 downto 0);

    -- which overall sample we are on (range 0 to num_samples - 1)
    signal curr_sample : std_logic_vector(12 downto 0);
    -- which bram block we're in ( range 0 to num_samples/auto_block_size -1 ) 
    signal auto_block : std_logic_vector(5 downto 0);
    -- which sample in the bram block we're in (range 0 to auto_block_size -1 )
    signal auto_block_sample : std_logic_vector(6 downto 0);
    -- the maximum autocorrelation sample we've seen yet
    signal max_auto_result : std_logic_vector(15 downto 0);
    -- the sample number of the maximum autocorrelation
    signal max_auto_sample : std_logic_vector(12 downto 0);
    -- For the division. Use 28 bits before the decimal place and 4 bits below the decimal place. This will 
    --  allow for 1/16th precision. The constant is equal to 1.5625 MHZ (shifted left by 4 bits
    --  as mentioned previously)
    constant sampling_freq : std_logic_vector(31 downto 0) := "10010101000000101111100100000000";

    --
    -- Clipping Level Checking Signals
    --
    signal pos_one_count : std_logic_vector(12 downto 0);
    signal neg_one_count : std_logic_vector(12 downto 0);

    -- Want between ~10% and ~15% of the data clipped. Adjust these if clipping is turning out 
    --  to be pesky. Clipping levels can be raised if needed.
    constant low_clipping_threshold : std_logic_vector(9 downto 0)  := "0111110100"; -- 500
    constant high_clipping_threshold : std_logic_vector(9 downto 0) := "1100100000"; -- 800

    --
    -- AUTOCORRELATION ARRAY SIGNALS
    --
    -- Global sample broadcast line
    signal sample_interconnect : std_logic_vector(1 downto 0);
    signal load_sigs  : std_logic_vector((auto_block_size - 1) downto 0);
    -- Autocorrelation signal
    signal auto_sig : std_logic;
    signal auto_reset : std_logic;
    -- Result vectors
    type result_array is array((auto_block_size - 1) downto 0) of std_logic_vector(15 downto 0);
    signal auto_results : result_array;

    -- Divider Constants
    signal quotient : std_logic_vector(31 downto 0);
    signal fractional : std_logic_vector(3 downto 0);
    signal div_new_data : std_logic;
    signal div_rdy : std_logic;

    -- Current sample
    signal sample_data : std_logic_vector(1 downto 0);

    -- gain stuff
    signal increase_gain : std_logic;
    signal decrease_gain : std_logic;

begin

    --
    -- Now create the mini control-machine for the sampling. We do the sampling
    --  in a different part since it's running in a different clock domain. 
    --
    process(clk)
    begin
        if (rising_edge(clk)) then
            -- Go based off of our current state
            case curr_state is

                when IDLE =>
                    done <= '0';
                    auto_reset <= '1';
                    do_sample <= '0';

                    if (start = '1') then
                        gain_reset <= '0';
                        curr_state <= SAMPLE;
                    else
                        gain_reset <= '1';
                        curr_state <= IDLE;
                    end if;


                when SAMPLE =>
                    if (sample_done = '1') then
                        do_sample <= '0';
                        curr_state <= CHECK_CLIPPING;
                    else
                        curr_state <= SAMPLE;
                        do_sample <= '1';
                    end if;

                --
                -- Make sure that we have decent clipping data. Use the tallies 
                -- generated in the sampling process and 
                when CHECK_CLIPPING =>

                    -- If we don't have to change the clipping, then we can just
                    --  go straing to autocorrelation initialization
                    if ((increase_gain or decrease_gain) = '0') then
                        curr_state <= AUTO_INIT;
                    else
                        if (increase_gain = '1') then
                            curr_state <= INC_GAIN;
                        else
                            curr_state <= DEC_GAIN;
                        end if;
                    end if;

                --
                -- Tell the gain unit to increase the gain. Always increase the clipping
                --  to the limit allowed by the high gain threshold, since this will reduce
                --  the amount of times which the gain will need to be adjusted.
                --
                when INC_GAIN =>
                    -- Increase the gain by at least the difference between the high threshold and the
                    --  number of positive/negative ones (they should be more or less the same, so 
                    --  just pick one of them to use)

                    -- 1 = increase gain
                    gain_inc_dec <= '1';
                    gain_start <= '1';
                    curr_state <= GAIN_CHANGE_WAIT;

                --
                -- Tell the gain unit to decrease the gain
                --
                when DEC_GAIN =>
                    -- Decrease the gain by at least the difference between the low threshold and the
                    --  number of positive/negative ones (they should be more or less the same, so 
                    --  just pick one of them to use)

                    -- 0 = decrease gain
                    gain_inc_dec <= '0';
                    gain_start <= '1';
                    curr_state <= GAIN_CHANGE_WAIT;

                --
                -- Wait for the gain unit to be done adjusting the gain, 
                --  and then take new samples which hopefully will work
                --
                when GAIN_CHANGE_WAIT =>
                    if (gain_done = '1') then
                        curr_state <= SAMPLE;
                        do_sample <= '1';
                    else
                        curr_state <= GAIN_CHANGE_WAIT;
                    end if;

                -- Set up all of our autocorrelation
                when AUTO_INIT =>
                    curr_sample <= (others => '0');
                    auto_block <= (others => '0');
                    auto_block_sample <= (others => '0');
                    max_auto_result <= (others => '0');
                    max_auto_sample <= (others => '0');
                    load_sigs <= (others => '0');
                    auto_reset <= '0';

                    curr_state <= AUTO_LOAD_SAMPLES;

                --
                -- Load the autocorrelation array with samples
                --
                when AUTO_LOAD_SAMPLES =>

                    -- Put the value sampled on the input
                    sample_interconnect <= sample_memory(conv_integer(auto_block & auto_block_sample));
                    -- Send the correct load signal high
                    load_sigs(conv_integer(auto_block_sample)) <= '1';

                    -- If we're not at the beginning of the array, then send the
                    --  previous load signal low
                    if (OR_REDUCE(auto_block_sample) = '1') then
                        load_sigs((conv_integer(auto_block_sample) - 1)) <= '0';
                    end if;

                    -- Need to do this until we've put in auto_block_size samples
                    if (conv_integer(auto_block_sample) = (auto_block_size - 1)) then
                        auto_block_sample <= (others => '0');
                        curr_state <= AUTO_RUN;
                    else
                        auto_block_sample <= auto_block_sample + 1;
                        curr_state <= AUTO_LOAD_SAMPLES;
                    end if;

                --
                -- Autocorrelate each sample with the entire data set
                --
                when AUTO_RUN =>

                    -- Need to put the sample from memory onto the global bus and tell everyone to 
                    --  autocorrelate
                    sample_interconnect <= sample_memory(conv_integer(curr_sample));

                    -- Tell them to auto-correlate;
                    auto_sig <= '1';

                    --
                    -- Figure out what to do at the end of the state
                    --

                    -- If we have run through all of the samples, the move onto 
                    --  finding the max from the autocorrelation values
                    if (conv_integer(curr_sample) = (num_samples - 1)) then
                        curr_state <= AUTO_GET_MAX;
                        curr_sample <= (others => '0');
                    -- Keep autocorrelating
                    else
                        curr_state <= AUTO_RUN;
                        curr_sample <= curr_sample + 1;
                    end if;

                --
                -- Update the maximum autocorrelation value
                --
                when AUTO_GET_MAX =>

                    -- Do the comparison and get the new max if necessary
                    if (conv_integer(auto_results(conv_integer(auto_block_sample))) > conv_integer(max_auto_result)) then
                        max_auto_result <= auto_results(conv_integer(auto_block_sample));
                        max_auto_sample <= auto_block & auto_block_sample;
                    end if;

                    -- Figure out the next state
                    if (conv_integer(auto_block_sample) = (auto_block_size - 1)) then
                        -- If we have done all of the auto blocks, then move onto 
                        --  detecting frequency
                        if (conv_integer(auto_block & auto_block_sample) = (num_samples - 1)) then
                            div_new_data <= '1';
                            curr_state <= FREQUENCY;
                        -- Otherwise, increment the auto block and go back to loading
                        else
                            auto_block_sample <= (others => '0');
                            auto_block <= auto_block + 1;
                            curr_state <= AUTO_LOAD_SAMPLES;
                        end if;
                    -- Loop in this state until we've gone through all of the auto
                    --  correlation samples.
                    else
                        auto_block_sample <= auto_block_sample + 1;
                        curr_state <= AUTO_GET_MAX;
                    end if;

                --
                -- Convert the detected sample to frequency
                --
                when FREQUENCY =>

                    div_new_data <= '0';
                    if (div_rdy = '1') then
                        done <= '1';
                        detected_freq <= quotient(27 downto 0) & fractional;
                        curr_state <= IDLE;
                    else
                        curr_state <= FREQUENCY;
                    end if;

                when others =>
                    curr_state <= IDLE;

            end case;

        end if;

    end process;



    --
    -- Map the input signals to data we care about
    --
    sample_data <= sig_neg & (sig_neg or sig_pos);

    -- Do the sampling. Run this loop at the sampling frequency
    process(sample_clock)
    begin
        if (rising_edge(sample_clock)) then

            case sample_state is 

                when SAMPLE_IDLE =>

                    sample_done <= '0';

                    if (do_sample = '1') then
                        sample_state <= SAMPLE_INIT;
                    else
                        sample_state <= SAMPLE_IDLE;
                    end if;

                when SAMPLE_INIT =>
                    -- Reset Variables
                    sample_count <= (others => '0');
                    pos_one_count <= (others => '0');
                    neg_one_count <= (others => '0');
                    increase_gain <= '0';
                    decrease_gain <= '0';

                    -- And move onto sampling
                    sample_state <= SAMPLE_GET;

                when SAMPLE_GET =>
                    
                    -- Put the sample into the BRAM
                    sample_memory(conv_integer(sample_count)) <= sample_data;

                    -- Update the sample counts
                    if (sample_data = "01") then
                        pos_one_count <= pos_one_count + 1;
                    end if;

                    if (sample_data = "11") then
                        neg_one_count <= neg_one_count + 1;
                    end if;

                    -- Figure out what to do next
                    if (conv_integer(sample_count) = (num_samples - 1)) then
                        sample_state <= SAMPLE_THRESHOLDS;
                    else
                        sample_count <= sample_count + 1;
                        sample_state <= SAMPLE_GET;
                    end if;

                when SAMPLE_THRESHOLDS =>
                    if ((pos_one_count < low_clipping_threshold) or (neg_one_count < low_clipping_threshold)) then
                        increase_gain <= '1';
                        gain_diff <= high_clipping_threshold - pos_one_count;
                    end if;

                    if ((pos_one_count > high_clipping_threshold) or (neg_one_count > high_clipping_threshold)) then
                        decrease_gain <= '1';
                        gain_diff <= pos_one_count - high_clipping_threshold;
                    end if;

                    sample_done <= '1';
                    sample_state <= SAMPLE_IDLE;

                when others =>
                    sample_state <= SAMPLE_IDLE;

            end case;

        end if;

    end process;

    --
    -- String the autocorrelation array together in a big for-generate loop
    --
    genautos: for i in 0 to (auto_block_size - 1) generate
    begin

        autox: entity autocorrelation(behavioral)
            port map(
                clk => clk,
                do_auto => auto_sig,
                do_load => load_sigs(i),
                sample_in => sample_interconnect,
                result => auto_results(i),
                reset => auto_reset
            );

    end generate genautos;

    --
    -- Hook up the sampling divider
    --
    sampl_div : sampling_div
        port map (
            clk => clk,
            nd => div_new_data,
            rdy => div_rdy,
            dividend => sampling_freq,
            divisor => max_auto_sample,
            quotient => quotient,
            fractional => fractional
        );

end architecture;




            
















