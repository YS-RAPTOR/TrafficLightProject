-- Contains all the entity instantiation for the traffic controller.
library IEEE;
use IEEE.STD_LOGIC_1164.all;
entity TopLevel is
    port
    (
        Reset : in STD_LOGIC;
        Clock : in STD_LOGIC;

        -- for debug
        debugLED : out STD_LOGIC;
        LEDs     : out STD_LOGIC_VECTOR(2 downto 0);

        -- Car and pedestrian buttons
        CarEW : in STD_LOGIC; -- Car on EW road
        CarNS : in STD_LOGIC; -- Car on NS road
        PedEW : in STD_LOGIC; -- Pedestrian moving EW (crossing NS road)
        PedNS : in STD_LOGIC; -- Pedestrian moving NS (crossing EW road)

        -- Light control
        LightsEW : out STD_LOGIC_VECTOR (1 downto 0); -- controls EW lights
        LightsNS : out STD_LOGIC_VECTOR (1 downto 0)  -- controls NS lights
    );
end TopLevel;

architecture Behavioral of TopLevel is
    -- Timing Constants
    constant F : INTEGER := 100;
    constant ColourChangeTime : INTEGER := 3;
    constant PedestrianCrossingTime : INTEGER := 5;
    constant MinimumLightTime : INTEGER := 10;

    -- Main Timer Signals
    signal TimerClear : STD_LOGIC;
    signal ColorChangeTimeReached : STD_LOGIC;
    signal PedHasTimeToCross : STD_LOGIC;
    signal MinimumLightTimeReached : STD_LOGIC;

    -- Ped Timer Signals
    signal PedTimerClear : STD_LOGIC;
    signal PedestrianHasCrossed : STD_LOGIC;

    -- Pedestrian Status
    signal PedEWReset, PedNSReset : STD_LOGIC; -- Button To Reset Pedestrian Status
    signal EWPS, NSPS : STD_LOGIC; -- If button has been clicked this status is set to true | S - Status
begin

    -- Entity Initializations
    Controller : entity work.Traffic(Behavioral)
        generic map
        (
            F                      => F,
            ColourChangeTime       => ColourChangeTime,
            PedestrianCrossingTime => PedestrianCrossingTime,
            MinimumLightTime       => MinimumLightTime
        )
        port map
        (
            Reset                   => Reset,
            Clock                   => Clock,
            CarEW                   => CarEW,
            CarNS                   => CarNS,
            LightsEW                => LightsEW,
            LightsNS                => LightsNS,
            TimerClear              => TimerClear,
            ColorChangeTimeReached  => ColorChangeTimeReached,
            PedHasTimeToCross       => PedHasTimeToCross,
            MinimumLightTimeReached => MinimumLightTimeReached,
            PedTimerClear           => PedTimerClear,
            PedestrianHasCrossed    => PedestrianHasCrossed,
            PedEWReset              => PedEWReset,
            PedNSReset              => PedNSReset,
            EWPS                    => EWPS,
            NSPS                    => NSPS
        );
    MainTimer : entity work.MainTimer(Behavioral)
        generic map
        (
            F    => F,
            CCT  => ColourChangeTime,
            PedT => PedestrianCrossingTime,
            MinT => MinimumLightTime
        )
        port map
        (
            Clear             => TimerClear,
            Clock             => Clock,
            ColorChangeTime   => ColorChangeTimeReached,
            PedHasTimeToCross => PedHasTimeToCross,
            MinLightTime      => MinimumLightTimeReached
        );
    PedTimer : entity work.PedTimer(Behavioral)
        generic map
        (
            F    => F,
            PedT => PedestrianCrossingTime
        )
        port map
        (
            Clear         => PedTimerClear,
            Clock         => Clock,
            PedHasCrossed => PedestrianHasCrossed
        );

    PedEWRegister : entity work.PedRegister(Behavioral)
        port map
        (
            Clock    => Clock,
            Set      => PedEW,
            Reset    => PedEWReset,
            PedState => EWPS
        );

    PedNSRegister : entity work.PedRegister(Behavioral)
        port map
        (
            Clock    => Clock,
            Set      => PedNS,
            Reset    => PedNSReset,
            PedState => NSPS
        );

    -- Debug Outputs 
    debugLED <= TimerClear;
    LEDs <= ColorChangeTimeReached & PedHasTimeToCross & MinimumLightTimeReached;
end Behavioral;