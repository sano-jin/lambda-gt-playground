module PortGraph.PortGraph exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced


# Description:

グラフのノードは以下の 2 種類ある．

  - アトム: Port を持つ頂点
      - それぞれの port からは hyper でない edge が出て，
        port または unnamed hyperlink に接続される．
  - Hyperlink: Port を持たない頂点．普通のグラフ理論の頂点．
      - 任意本の edge が出て，
        port または hyperlink に接続される．

同じポートや hyperlink から多重辺が出ることは想定していない．
あくまでポートや hyperlink から出る辺は一本で，他のポートに直接繋がるか，
ハイパーリンクに接続されるかのどちらか．

TODO:

  - angle をなくして，任意の field を取れるように拡張する．
  - 命名の整理（Atom, Hyperlink, node, edge, link?）．
  - Documentation.
  - データ構造の整理．
      - 動的な更新ができるようにする．
      - port angle をできるだけ保ちたい．
      - まずはあまり差分を小さくすることについて考えなくても良いかも知れない．
  - portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．
  - Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．
  - port-graph-visualisation を playground から分離する．

-}

-- import Dict exposing (Dict)

import Dict exposing (Dict)
import Either exposing (Either(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import List.Extra as ListX
import Maybe.Extra as MaybeX
import PortGraph.Util as Util


{-| An angle of a port.
-}
type alias PortAngle =
    Float


{-| The type used for identifying nodes (atoms and hyperlinks), an integer.
-}
type alias NodeId comparable =
    comparable


{-| The type used for identifying ports, an integer.
-}
type alias PortId =
    Int


{-| ポートがどこに接続されているか．
Atom の Port またはハイパーリンク．
-}
type ConnectedTo comparable
    = Port ( NodeId comparable, PortId )
    | HL (NodeId comparable)


isPort : ConnectedTo comparable -> Bool
isPort connectedTo =
    case connectedTo of
        Port _ ->
            True

        HL _ ->
            False


{-| Extracrt `NodeId` from `ConnectedTo`
-}
extractNodeId : ConnectedTo comparable -> NodeId comparable
extractNodeId connectedTo =
    case connectedTo of
        Port ( nodeId, _ ) ->
            nodeId

        HL nodeId ->
            nodeId


{-| NodeId -> PortId -> PortAngle.
-}
type alias PortDict comparable =
    Dict comparable (Dict Int (Port_ comparable))


{-| NodeId -> PortId -> PortAngle.
-}
type alias PortLabels comparable =
    Dict comparable (Dict Int String)


{-| TODO: This is an unused function.
`PortDict` を削除して，`Graph` でおきかえたら，`getPort` をこれで置き換えることになる．
-}
getPortOfGraph : Graph comparable -> NodeId comparable -> PortId -> Maybe (Port_ comparable)
getPortOfGraph graph nodeId portId =
    Dict.get nodeId graph.atoms
        |> Maybe.andThen (.ports >> Dict.get portId)


getPort : PortDict comparable -> NodeId comparable -> PortId -> Maybe (Port_ comparable)
getPort portLabels nodeId portId =
    Dict.get nodeId portLabels
        |> Maybe.andThen (Dict.get portId)


getPortLabel : PortDict comparable -> ConnectedTo comparable -> String
getPortLabel portDict connectedTo =
    case connectedTo of
        HL _ ->
            ""

        Port ( nodeId, portId ) ->
            getPort portDict nodeId portId
                |> Maybe.map .label
                |> Maybe.withDefault ""


{-| ポートの情報．
-}
type alias Port_ comparable =
    { id : PortId
    , angle : PortAngle -- ポートの情報，とりあえずは角度．
    , label : String -- ポートのラベル．
    , to : ConnectedTo comparable -- 接続先
    }


{-| アトムの情報．

  - アトム: Port を持つ頂点
  - それぞれの port からは hyper でない edge が出て，
    port または unnamed hyperlink に接続される．

-}
type alias AtomContext comparable =
    { id : NodeId comparable
    , label : String
    , ports : Dict Int (Port_ comparable) -- ポート id -> ポートの情報
    }


type alias Atoms comparable =
    Dict comparable (AtomContext comparable)


{-| `functorOfAtom atom` returns the functor of `atom`.
If the name of the atom is a number, then replace it with `$int`.
-}
functorOfAtom : AtomContext comparable -> Functor
functorOfAtom atom =
    let
        label =
            if MaybeX.isJust (String.toInt atom.label) && Dict.size atom.ports == 1 then
                "$int"

            else
                atom.label
    in
    ( label, Dict.size atom.ports )



--


updatePortOfAtoms : (Port_ comparable -> Port_ comparable) -> ( NodeId comparable, PortId ) -> Atoms comparable -> Atoms comparable
updatePortOfAtoms f ( nodeId, portId ) atoms =
    Dict.update nodeId (Maybe.map (\atom -> { atom | ports = Dict.update portId (Maybe.map f) atom.ports })) atoms


updatePortAngleOfGraph : Float -> ( NodeId comparable, PortId ) -> Graph comparable -> Graph comparable
updatePortAngleOfGraph portAngle nodePortId graph =
    { graph | atoms = updatePortOfAtoms (\p -> { p | angle = portAngle }) nodePortId graph.atoms }



--


{-| `updatePortAngleOfAtom portAngle portId atom` updates the angle of the ports with `portId` in `atom` to `portAngle`.
-}
updatePortAngleOfAtom : Float -> PortId -> AtomContext comparable -> AtomContext comparable
updatePortAngleOfAtom portAngle portId atom =
    { atom | ports = Dict.update portId (Maybe.map (\port_ -> { port_ | angle = portAngle })) atom.ports }


{-| `mapAtomsWithFunctor functor atoms` applies the atoms with a specific functor, `functor`, in `atoms` to `f`
and return the newly obtained dictionaly.
-}
mapAtomsWithFunctor : (AtomContext comparable -> AtomContext comparable) -> Functor -> Atoms comparable -> Atoms comparable
mapAtomsWithFunctor f functor atoms =
    Util.dictMapIf f ((==) functor << functorOfAtom) atoms


{-| `updatePortAngles portAngle functor atoms` updates the angles of the ports of `atoms` to `portAngle`.
-}
updatePortAnglesWithFunctor : Float -> Functor -> PortId -> Atoms comparable -> Atoms comparable
updatePortAnglesWithFunctor portAngle functor portId =
    mapAtomsWithFunctor (updatePortAngleOfAtom portAngle portId) functor


{-| Hyperlink の情報．

  - Hyperlink: Port を持たない頂点．普通のグラフ理論の頂点．
  - 任意本の edge が出て，
    port または hyperlink に接続される．

-}
type alias HLink comparable =
    { id : NodeId comparable
    , label : String
    , to : Dict Int (ConnectedTo comparable) -- 接続先のリスト
    }


type alias HLs comparable =
    Dict comparable (HLink comparable)


{-| Edge.
Port or Hyperlink から Port or Hyperlink に接続される．
-}
type alias Edge comparable =
    { from : ConnectedTo comparable -- 接続先
    , to : ConnectedTo comparable -- 接続先
    }


{-| Graph is represented by a set of nodes (atoms and hyperlinks).
-}
type alias Graph comparable =
    { atoms : Atoms comparable
    , hlinks : HLs comparable
    }


getAtom : Graph comparable -> NodeId comparable -> Maybe (AtomContext comparable)
getAtom { atoms } nodeId =
    Dict.get nodeId atoms


type alias Functor =
    ( String, Int )


functorToString : Functor -> String
functorToString ( atomName, arity ) =
    atomName ++ "/" ++ String.fromInt arity


groupAtomsWithFunctor : Graph comparable -> List ( AtomContext comparable, List (AtomContext comparable) )
groupAtomsWithFunctor { atoms } =
    List.sortBy (\( a, _ ) -> functorOfAtom a) <|
        ListX.gatherEqualsBy functorOfAtom <|
            Dict.values atoms


getNode : Graph comparable -> NodeId comparable -> Maybe (Either (AtomContext comparable) (HLink comparable))
getNode { atoms, hlinks } nodeId =
    case Dict.get nodeId atoms of
        Just atom ->
            Just (Left atom)

        Nothing ->
            case Dict.get nodeId hlinks of
                Just hlink ->
                    Just (Right hlink)

                Nothing ->
                    Nothing


{-| An empty graph
-}
empty =
    { atoms = Dict.empty
    , hlinks = Dict.empty
    }


{-| `toAtoms graph` returns a list of all `AtomContext`s in `graph`.
-}
toAtoms : Graph comparable -> List (AtomContext comparable)
toAtoms graph =
    Dict.values graph.atoms


{-| `toHLinks graph` returns a list of all `HLink`s in `graph`.
-}
toHLinks : Graph comparable -> List (HLink comparable)
toHLinks graph =
    Dict.values graph.hlinks


{-| `toEdges graph` returns a list of all edges in `graph`.
-}
toEdges : Graph comparable -> List (Edge comparable)
toEdges graph =
    let
        edgeOfPort atomId port_ =
            { from = Port ( atomId, port_.id )
            , to = port_.to
            }

        edgesOfAtom atom =
            List.map (edgeOfPort atom.id) <| Dict.values atom.ports

        edgeOfHL hlinkId connectedTo =
            { from = HL hlinkId
            , to = connectedTo
            }

        edgesOfHL hlink =
            List.map (edgeOfHL hlink.id) <| Dict.values hlink.to
    in
    List.concatMap edgesOfAtom (Dict.values graph.atoms)
        ++ List.concatMap edgesOfHL (Dict.values graph.hlinks)


{-| `toEdgesAndAngles graph` returns a list of all edges and the angles of the ports in `graph`.
-}
toPortDict : Graph comparable -> PortDict comparable
toPortDict graph =
    Dict.map (\_ -> .ports) graph.atoms



-- toString


connectedToToString : (comparable -> String) -> ConnectedTo comparable -> String
connectedToToString f connectedTo =
    case connectedTo of
        Port ( nodeId, portId ) ->
            f nodeId ++ "/" ++ String.fromInt portId

        HL nodeId ->
            f nodeId


atomToString : (comparable -> String) -> AtomContext comparable -> String
atomToString f atom =
    f atom.id
        ++ ": "
        ++ atom.label
        ++ "("
        ++ String.join ", " (List.map (connectedToToString f << .to) <| Dict.values atom.ports)
        ++ ")"


hlinkToString : (comparable -> String) -> HLink comparable -> String
hlinkToString f hlink =
    f hlink.id
        ++ ": "
        ++ hlink.label
        ++ "("
        ++ String.join ", " (List.map (connectedToToString f) <| Dict.values hlink.to)
        ++ ")"


{-| `toString graph` returns a string representing the `graph`.
-}
toString : (comparable -> String) -> Graph comparable -> String
toString f graph =
    String.join ", " <|
        List.map (atomToString f) (Dict.values graph.atoms)
            ++ List.map (hlinkToString f) (Dict.values graph.hlinks)



-- Decoders
-- These decoders assumes that the `NodeId` is `Int`.


decodeConnectedTo : Decoder (ConnectedTo Int)
decodeConnectedTo =
    let
        helper nodeId maybePortId =
            case maybePortId of
                Just portId ->
                    Port ( nodeId, portId )

                Nothing ->
                    HL nodeId
    in
    Decode.succeed helper
        |> DP.required "nodeId" Decode.int
        |> DP.optional "portId" (Decode.map Just Decode.int) Nothing


decodePort : Decoder (Port_ Int)
decodePort =
    Decode.succeed Port_
        |> DP.required "id" Decode.int
        |> DP.hardcoded 0
        |> DP.required "label" Decode.string
        |> DP.required "to" decodeConnectedTo


decodeDict : Decoder { v | id : comparable } -> Decoder (Dict comparable { v | id : comparable })
decodeDict =
    Decode.map (Dict.fromList << List.map (\e -> ( e.id, e ))) << Decode.list


decodeAtom : Decoder (AtomContext Int)
decodeAtom =
    Decode.succeed AtomContext
        |> DP.required "id" Decode.int
        |> DP.required "label" Decode.string
        |> DP.required "ports" (decodeDict decodePort)


decodeHL : Decoder (HLink Int)
decodeHL =
    Decode.succeed HLink
        |> DP.required "id" Decode.int
        |> DP.required "label" Decode.string
        |> DP.required "to"
            (Decode.map (Dict.fromList << List.indexedMap (\i e -> ( i, e ))) <|
                Decode.list <|
                    decodeConnectedTo
            )


decodeGraph : Decoder (Graph Int)
decodeGraph =
    Decode.succeed Graph
        |> DP.required "atoms" (decodeDict decodeAtom)
        |> DP.required "hlinks" (decodeDict decodeHL)



-- Presets of the port angles for each functors


{-| The initial port angles for the ports of each functors.
-}
type alias InitialPortAngles =
    Dict ( Functor, Int ) Float


{-| The initial port angles for the ports of each functors.
-}
initialPortAngles : InitialPortAngles
initialPortAngles =
    Dict.fromList
        [ ( ( ( "Cons", 3 ), 0 ), 90 )
        , ( ( ( "Cons", 3 ), 1 ), 0 )
        , ( ( ( "Cons", 3 ), 2 ), 180 )
        , ( ( ( "$int", 1 ), 0 ), 270 )
        , ( ( ( "Nil", 1 ), 0 ), 180 )
        , ( ( ( "Node", 3 ), 0 ), 60 )
        , ( ( ( "Node", 3 ), 1 ), 120 )
        , ( ( ( "Node", 3 ), 2 ), 270 )
        ]


{-| `initPortAngles portAngles graph` initializes the port angles of `graph` according to the `portAngles`.
-}
initPortAngles : InitialPortAngles -> Graph Int -> Graph Int
initPortAngles portAngles graph =
    { graph
        | atoms =
            Dict.foldl
                (\( functor, portId ) portAngle -> updatePortAnglesWithFunctor portAngle functor portId)
                graph.atoms
                portAngles
    }
