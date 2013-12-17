--
-- Sampling constants package
--

library ieee;
use ieee.std_logic_1164.all;


package sampling_constants is

    type sample_memory_type is array(8191 downto 0) of std_logic_vector(1 downto 0);

end package;
    
