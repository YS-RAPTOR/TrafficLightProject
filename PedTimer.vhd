-- Pedestrian Timer Used to know when the pedestrian has finished crossing.
-- Very similar to main timer and uses the same logic. 
-- This is used to control the amount of time the pedestrian light stays on once pressed.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.NUMERIC_STD.all;
entity PedTimer is
    generic
    (
        F    : INTEGER; -- Clock Frequency
        PedT : INTEGER  -- Time It Takes for the pedestrian to cross
    );
    port
    (
        Clear         : in STD_LOGIC; -- Synchronous Clear
        Clock         : in STD_LOGIC; -- Clock
        PedHasCrossed : out STD_LOGIC -- Outputs if the Pedestrian has crossed
    );
end PedTimer;

architecture Behavioral of PedTimer is
    type TimerStates is (Idle, Count, ReachPedC);

    signal state, newState : TimerStates;
    signal Ticks : INTEGER range 0 to (PedT * F);
begin

    SynchronousProcess : process (Clock)
    begin
        if rising_edge(Clock) then
            state <= newState;
            if (Clear = '1') then
                state <= Idle; -- Synchronous Reset
                Ticks <= 0;
            else
                Ticks <= Ticks + 1;
            end if;
        end if;
    end process; -- SynchronousProcess

    TimerProcess : process (state, Ticks, Clear)
    begin
        -- How The Next State is Determined
        case(state) is
            when Idle =>
            if Clear = '0' then
                newState <= Count; -- When Not Clearing the Next State Should be Counting State
            else
                newState <= Idle;
            end if;
            when Count =>
            if Ticks = (PedT * F) then -- When Pedestrian is given enough time to cross the next state should be ReachPedC
                newState <= ReachPedC;
            else
                newState <= Count;
            end if;
            when ReachPedC =>
            if Clear = '1' then
                newState <= Idle; -- In This State Do Nothing Until Clear Signal Comes in. When Clear Signal Comes in state will be set to Idle.
            else
                newState <= ReachPedC;
            end if;
        end case;

    end process; -- TimerProcess

    -- Output Logic
    PedHasCrossed <= '1' when state = ReachPedC else
        '0';
end Behavioral;