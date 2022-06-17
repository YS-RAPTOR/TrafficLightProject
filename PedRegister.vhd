-- Set Reset Register for Pedestrian Buttons
-- This is used to register the pedestrian button presses and make sure they are registered.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity PedRegister is
    port
    (
        Clock    : in STD_LOGIC;
        Set      : in STD_LOGIC;
        Reset    : in STD_LOGIC;
        PedState : out STD_LOGIC);
end PedRegister;

architecture Behavioral of PedRegister is
    signal state, newState : STD_LOGIC;
begin
    SynchronousProcess : process (Clock)
    begin
        if rising_edge(Clock) then
            state <= newState;
        end if;
    end process; -- PedRegisteringProcess

    PedRegisteringProcess : process (state, Set, Reset)
    begin
        if Reset = '1' then 
            newState <= '0'; -- Synchronous Reset
        elsif Set = '1' then
            newState <= '1'; -- Synchronous Set
        else
            newState <= State; -- If no Set and Reset preserve state
        end if;
    end process; -- PedRegisteringProcess
    PedState <= state;

end Behavioral;