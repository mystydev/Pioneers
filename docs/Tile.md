#Tile

??? Question "TileType"
    | Enum | Value |
    | - | - |
    | DESTROYED | -1 |
    | GRASS | 0 |
    | KEEP | 1 |
    | PATH | 2 |
    | HOUSE | 3 |
    | FARM | 4 |
    | MINE | 5 |
    | FORESTRY | 6 |
    | STORAGE | 7 |
    | BARRACKS | 8 |
    | WALL | 9 |
    | GATE | 10 |

??? Question "TileConstructionCosts"
    How much each tile costs to create.

    | Tile | Stone | Wood |
    | - | - | - |
    | Keep | 0 | 0 |
    | Path | 20 | 0 |
    | House | 100 | 100 |
    | Farm | 75 | 75 |
    | Mine | 0 | 150 |
    | Forestry | 150 | 0 |
    | Storage | 500 | 500 |
    | Barracks | 500 | 300 |
    | Wall | 1000 | 1000 |
    | Gate | 1000 | 1500 |

??? Question "TileMaintenanceCosts"
    How much each tile costs each round.

    | Tile | Stone | Wood |
    | - | - | - |
    | Keep | 0 | 0 |
    | Path | 0 | 0 |
    | House | 0 | 0 |
    | Farm | 0 | 0 |
    | Mine | 0 | 0 |
    | Forestry | 0 | 0 |
    | Storage | 1 | 1 |
    | Barracks | 2 | 2 |
    | Wall | 3 | 3 |
    | Gate | 3 | 3 |