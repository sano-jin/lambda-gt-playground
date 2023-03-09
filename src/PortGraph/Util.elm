module PortGraph.Util exposing (..)

-- import Dict exposing (Dict)

import Dict exposing (Dict)
import Either exposing (Either(..))
import List.Extra as ListX


{-| `mapIf f pred list` applies the elements of the `list` to `f` if they satisfy the `pred`
and return the newly obtained list.
-}
mapIf : (a -> a) -> (a -> Bool) -> List a -> List a
mapIf f pred list =
    let
        helper x =
            if pred x then
                f x

            else
                x
    in
    List.map helper list


{-| `mapIf f pred list` applies the elements of the `list` to `f` if they satisfy the `pred`
and return the newly obtained list.
-}
dictMapIf : (a -> a) -> (a -> Bool) -> Dict comparable a -> Dict comparable a
dictMapIf f pred list =
    let
        helper _ x =
            if pred x then
                f x

            else
                x
    in
    Dict.map helper list


mergeDicts : List (Dict comparable v) -> Dict comparable v
mergeDicts dicts =
    List.foldl Dict.union Dict.empty dicts
