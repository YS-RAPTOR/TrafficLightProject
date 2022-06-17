----------------------------------------------------------------------------------
--  Traffic.vhd
--
-- Traffic light system to control an intersection
--
-- Accepts inputs from two car sensors and two pedestrian registers
-- Controls two sets of lights consisting of Red, Amber and Green traffic lights and
-- a pedestrian walk light.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Traffic is
    generic
    (
        F                      : INTEGER; -- Clock Frequency
        ColourChangeTime       : INTEGER; -- Time It Takes for the Colour to Change
        PedestrianCrossingTime : INTEGER; -- Time It Takes for the pedestrian to cross
        MinimumLightTime       : INTEGER  -- The Minimum time that has to have passed for the lane to cycle
    );
    port
    (
        Reset : in STD_LOGIC;
        Clock : in STD_LOGIC;

        -- Car and pedestrian buttons
        CarEW : in STD_LOGIC; -- Car on EW road
        CarNS : in STD_LOGIC; -- Car on NS road

        -- Light control
        LightsEW : out STD_LOGIC_VECTOR (1 downto 0); -- controls EW lights
        LightsNS : out STD_LOGIC_VECTOR (1 downto 0); -- controls NS lights

        -- Main Timer Signals
        TimerClear              : out STD_LOGIC;
        ColorChangeTimeReached  : in STD_LOGIC;
        PedHasTimeToCross       : in STD_LOGIC;
        MinimumLightTimeReached : in STD_LOGIC;

        -- Ped Timer Signals
        PedTimerClear        : out STD_LOGIC;
        PedestrianHasCrossed : in STD_LOGIC;

        -- Pedestrian Status
        PedEWReset, PedNSReset : out STD_LOGIC; -- Button To Reset Pedestrian Status
        EWPS, NSPS             : in STD_LOGIC   -- If button has been clicked this status is set to true | S - Status
    );
end Traffic;

architecture Behavioral of Traffic is

    -- Encoding for lights
    constant RED : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant AMBER : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant GREEN : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant WALK : STD_LOGIC_VECTOR(1 downto 0) := "11";

    -- States
    type TrafficStates is (EWL, EWP, REW, NSL, NSP, RNS); -- EW - East West | NS - North South | L - Light | P - Pedestrian Light | R - Ready
    signal state, newState : TrafficStates;
begin

    -- Synchronous Process
    SynchronousProcess : process (Clock, Reset)
    begin
        if (Reset = '1') then
            state <= EWL; -- Async Reset
        elsif rising_edge(Clock) then
            state <= newState;
        end if;

    end process; -- SynchronousProcess

    TrafficProcess : process (state, Reset, MinimumLightTimeReached, PedHasTimeToCross, EWPS, CarNS, NSPS, PedestrianHasCrossed, ColorChangeTimeReached, CarEW)
    begin
        -- Defaults
        TimerClear <= '0';
        PedTimerClear <= '0';
        PedNSReset <= '0';
        PedEWReset <= '0';
        -- Reset Timers When Resetted
        if (Reset = '1') then
            TimerClear <= '1';
            PedTimerClear <= '1';
            PedNSReset <= '1';
            PedEWReset <= '1';
            newState <= EWL;
        end if;
        -- Next State Logic
        case(state) is
            when EWL =>
            newState <= EWL; -- Default if no Change
            -- Logic For Cycling
            if MinimumLightTimeReached = '0' then -- If Minimum Light Time hasn't been reached start timer and turn off ped timer.
                PedTimerClear <= '1';
            elsif MinimumLightTimeReached = '1' then
                -- not enough time for the pedestrian to cross and button clicked or there is a car or pedestrian at north south: Cycle
                if (PedHasTimeToCross = '0' and EWPS = '1') or CarNS = '1' or NSPS = '1' then
                    newState <= RNS;
                    TimerClear <= '1';
                    PedTimerClear <= '1';
                end if;
            end if;
            -- Logic For going into Pedestrian Mode
            if PedHasTimeToCross = '1' and EWPS = '1' then
                newState <= EWP;
                PedTimerClear <= '1';
            end if;

            when EWP =>
            newState <= EWP; -- Default if no Change
            -- Logic for Leaving the State
            if PedestrianHasCrossed = '1' then
                PedTimerClear <= '0';
                PedEWReset <= '1';
                newState <= EWL;
            end if;

            when RNS =>
            newState <= RNS; -- Default if no Change
            PedTimerClear <= '1';
            -- Checking if a cenrtain amount of time has passed
            if ColorChangeTimeReached = '1' then
                TimerClear <= '0';
                newState <= NSL;
            end if;

            when NSL =>
            newState <= NSL; -- Default if no Change
            -- Logic For Cycling
            if MinimumLightTimeReached = '0' then -- If Minimum Light Time hasn't been reached start timer and turn off ped timer.
                PedTimerClear <= '1';
            elsif MinimumLightTimeReached = '1' then
                -- not enough time for the pedestrian to cross and button clicked or there is a car or pedestrian at east west: Cycle
                if (PedHasTimeToCross = '0' and NSPS = '1') or CarEW = '1' or EWPS = '1' then
                    newState <= REW;
                    TimerClear <= '1';
                    PedTimerClear <= '1';
                end if;
            end if;
            -- Logic For going into Pedestrian Mode
            if PedHasTimeToCross = '1' and NSPS = '1' then
                newState <= NSP;
                PedTimerClear <= '1';
            end if;

            when NSP =>
            newState <= NSP; -- Default if no Change
            -- Logic for Leaving the State
            if PedestrianHasCrossed = '1' then
                PedTimerClear <= '0';
                PedNSReset <= '1';
                newState <= NSL;
            end if;

            when REW =>
            newState <= REW; -- Default if no Change
            PedTimerClear <= '1';
            -- Checking if a cenrtain amount of time has passed
            if ColorChangeTimeReached = '1' then
                TimerClear <= '1';
                newState <= EWL;
            end if;

        end case;
    end process; -- TrafficProcess

    -- Convert State to Output
    with state select LightsEW <=
        WALK when EWP,
        GREEN when EWL,
        AMBER when RNS,
        RED when others;

    with state select LightsNS <=
        WALK when NSP,
        GREEN when NSL,
        AMBER when REW,
        RED when others;
end;