#Unit


??? Question "UnitType"
    | Enum | Value |
    | - | - |
    | NONE | 0 |
    | VILLAGER | 1 |
    | FARMER | 2 |
    | LUMBERJACK | 3 |
    | MINER | 4 |
    | APPRENTICE | 5 |
    | SOLDIER | 6 |

??? Question "UnitState"
    | Enum | Value |
    | - | - |
    | IDLE | 0 |
    | DEAD | 1 |
    | MOVING | 2 |
    | WORKING | 3 |
    | RESTING | 4 |
    | STORING | 5 |
    | COMBAT | 6 |
    | LOST | 7 |

??? Info "UnitType Type"
    The current type of the unit (ie villager, soldier etc).

??? Info "Int Id"
    The unique Id associated with this unit. It is used as a primary key.

??? Info "Int OwnderId"
    The Id of the player who owns this unit.

??? Info "Int Posx"
    The current x coordinate of this unit.

??? Info "Int Posy"
    The current y coordinate of this unit.

??? Info "Int Health"
    The current health of this unit.

??? Info "Int Fatigue"
    How fatigued this unit is. A unit gets fatigued as it does work and must rest when it gets too fatigued.

??? Info "Int Training"
    How much training this unit has gone through.

??? Info "UnitState State"
    The current state of this unit (ie Moving, Working etc).

??? Info "PosString Home"
    The home of this unit.

??? Info "PosString Work"
    The work of this unit.

??? Info "PosString Target"
    Where this unit is currently trying to walk to.

??? Info "PosString Attack"
    Where this unit is currently trying to attack.

??? Info "Resource HeldResource"
    The resources currently held by this unit.

??? Info "Resource ProducePerRound"
    The resources this unit produces per round on average.

??? Info "Int TripLength"
    How long this unit's trip is when travelling from home to work to storage and back home.