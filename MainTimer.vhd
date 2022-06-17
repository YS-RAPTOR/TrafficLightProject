-- Main Time Used to control logic within the Traffic System.
-- This module outputs information to the traffic controller about specific times that have passed.
-- The main variable used to count is an Integer.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.NUMERIC_STD.all;

entity MainTimer is
    generic
    (
        F    : INTEGER; -- Clock Frequency
        CCT  : INTEGER; -- Time It Takes for the Colour to Change
        PedT : INTEGER; -- Time It Takes for the pedestrian to cross
        MinT : INTEGER  -- The Minimum time that has to have passed for the lane to cycle
    );
    port
    (
        Clear             : in STD_LOGIC;  -- Synchronous Clear
        Clock             : in STD_LOGIC;  -- Clock
        ColorChangeTime   : out STD_LOGIC; -- Outputs when Enough Time has passed for colour change
        PedHasTimeToCross : out STD_LOGIC; -- Outputs when There is not enough time for pedestrian to cross
        MinLightTime      : out STD_LOGIC  -- Outputs when the Traffic can Cycle
    );
end MainTimer;

architecture Behavioral of MainTimer is
    type TimerStates is (Idle, Count, ReachCCT, ReachPedT, ReachMinT);
    signal state, newState : TimerStates; -- States for Timer
    signal Ticks : INTEGER range 0 to (MinT * F); -- Counting Variable

begin

    SynchronousProcess : process (Clock)
    begin
        if rising_edge(Clock) then
            state <= newState;
            if (Clear = '1') then -- Synchronous Clear
                state <= Idle;
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
            if Ticks = (CCT * F) then -- When Reached Colour Change Time the nex state should be ReachCCT
                newState <= ReachCCT;
            else
                newState <= Count;
            end if;
            when ReachCCT =>
            if Ticks = (PedT * F) then -- When Reached Time it Takes for a Pedestrian to cross the nex state should be ReachPedT
                newState <= ReachPedT;
            else
                newState <= ReachCCT;
            end if;
            when ReachPedT =>
            if Ticks = (MinT * F) then -- When Reached Minimum Time before Cycling Next State Should be 
                newState <= ReachMinT;
            else
                newState <= ReachPedT;
            end if;
            when ReachMinT =>
            if Clear = '1' then
                newState <= Idle; -- In This State Do Nothing Until Clear Signal Comes in. When Clear Signal Comes in state will be set to Idle.
            else
                newState <= ReachMinT;
            end if;
        end case;

    end process; -- TimerProcess

    -- Output Logic
    ColorChangeTime <= '1' when state = ReachCCT else
        '0';
    with state select PedHasTimeToCross <=
        '0' when ReachPedT,
        '0' when ReachMint,
        '1' when others;
    MinLightTime <= '1' when state = ReachMinT else
        '0';

end Behavioral;