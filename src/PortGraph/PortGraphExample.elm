module PortGraph.PortGraphExample exposing (..)

{-| The example of the `PortGraph`.

@delay 5
@category Advanced

-}

import Dict
import PortGraph.PortGraph exposing (..)



-- 0: Cons(1/0, 2/2, 7), 1: 18(0/0), 2: Cons(3/0, 4/2, 0/1), 3: 19(2/0), 4: Cons(5/0, 6/0, 2/1), 5: 20(4/0), 6: Nil(4/1), 7: X(0/2)
--
-- [ "X" -- 0
-- , "Cons1" -- 1
-- , "1" -- 2
-- , "Cons2" -- 3
-- , "2" -- 4
-- , "Cons3" -- 5
-- , "3" -- 6
-- , "Nil" -- 7
-- ]


cons1 : AtomContext Int
cons1 =
    { id = 0
    , label = "Cons"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 1, 0 ) } )
            , ( 1, { id = 1, angle = 0, label = "2", to = Port ( 2, 2 ) } )
            , ( 2, { id = 2, angle = 0, label = "3", to = HL 7 } )
            ]
    }


val1 : AtomContext Int
val1 =
    { id = 1
    , label = "1"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 0, 0 ) } )
            ]
    }


cons2 : AtomContext Int
cons2 =
    { id = 2
    , label = "Cons"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 3, 0 ) } )
            , ( 1, { id = 1, angle = 0, label = "2", to = Port ( 4, 2 ) } )
            , ( 2, { id = 2, angle = 0, label = "3", to = Port ( 0, 1 ) } )
            ]
    }


val2 : AtomContext Int
val2 =
    { id = 3
    , label = "2"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 2, 0 ) } )
            ]
    }


cons3 : AtomContext Int
cons3 =
    { id = 4
    , label = "Cons"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 5, 0 ) } )
            , ( 1, { id = 1, angle = 0, label = "2", to = Port ( 6, 0 ) } )
            , ( 2, { id = 2, angle = 0, label = "3", to = Port ( 2, 1 ) } )
            ]
    }


val3 : AtomContext Int
val3 =
    { id = 5
    , label = "3"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 4, 0 ) } )
            ]
    }


nil : AtomContext Int
nil =
    { id = 6
    , label = "Nil"
    , ports =
        Dict.fromList
            [ ( 0, { id = 0, angle = 0, label = "1", to = Port ( 4, 1 ) } )
            ]
    }


front_x : HLink Int
front_x =
    { id = 0
    , label = "X"
    , to =
        Dict.fromList [ ( 7, Port ( 0, 2 ) ) ]
    }


listGraph : Graph Int
listGraph =
    { atoms = Dict.fromList [ ( 0, cons1 ), ( 1, val1 ), ( 2, cons2 ), ( 3, val2 ), ( 4, cons3 ), ( 5, val3 ), ( 6, nil ) ]
    , hlinks = Dict.fromList [ ( 7, front_x ) ]
    }
