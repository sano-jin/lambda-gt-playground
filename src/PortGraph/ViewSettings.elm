module PortGraph.ViewSettings exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

Memo:

reheat の有無．

  - Link Distance, Port Angles などを更新した際には，reheat が必要になる．
  - portCtrlPDistance を更新した場合は（現在はこれだけ），reheat は不要．

update は `{ settings = SettingsModel, reheat = Bool }` を返すことにする？

TODO:

  - Documentation.
  - Eliminate Bootstrap code.
    The bootstrap code is for the frontend view and is not for rendering graphs.
  - グラフを更新した際に，
    visualisation のためのパラメータが初期化されてしまっているので，
    うまく引き継げるようにする．
      - Port Angles は，ファンクタごとの preset を更新して持っておく．
          - JSON で入出力できるようにする．
          - 個別の port angles を引き継ぐのは難しそうなので，後回し．
      - Spring settings はうまく引き継ぎたい．
  - データ構造の整理．
      - 動的な更新ができるようにする．
      - port angle をできるだけ保ちたい．
      - まずはあまり差分を小さくすることについて考えなくても良いかも知れない．
  - portCtrlPDistance は頂点間の距離に合わせて拡大させても良いかも知れない．
  - Scroll していると，アトムの選択がうまくいかない（ズレる）ので，補正する必要がある．
  - port-graph-visualisation を playground から分離する．

-}

import Bootstrap.Accordion as Accordion
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict exposing (Dict)
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Html exposing (Html, div)
import Html.Attributes as HAttrs exposing (style)
import Html.Events as HEvents
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import PortGraph.ForceExtra as Force
import PortGraph.PortGraph as PortGraph exposing (Functor, PortId, Port_)
import PortGraph.VisGraph as VisGraph
import Process
import Task
import Time
import Tuple as T2
import Tuple3 as T
import TypedSvg exposing (circle, defs, g, line, marker, polygon, rect, svg, text_, title)
import TypedSvg.Attributes as Attrs exposing (class, cursor, fill, fontSize, id, markerEnd, markerHeight, markerWidth, orient, pointerEvents, points, refX, refY, stroke, transform)
import TypedSvg.Attributes.InPx exposing (cx, cy, dx, dy, height, r, strokeWidth, width, x1, x2, y1, y2)
import TypedSvg.Core exposing (Attribute, Svg, text)
import TypedSvg.Types exposing (AlignmentBaseline(..), AnchorAlignment(..), Cursor(..), Length(..), Opacity(..), Paint(..), Transform(..))
import Zoom exposing (OnZoom, Zoom)



-- Types


type alias NodePortId =
    ( PortGraph.NodeId Int, PortId )


{-| TODO: Description.
-}
type Msg
    = SlideDistance Float
    | SlidePortDistance Float
    | SlidePortCtrlPDistance Float
    | SlideStrength Float
    | SlidePortAngle NodePortId Float
    | SlidePortAngleFunctor Functor PortId Float
    | AccordionSettingsMsg Accordion.State


{-| NodeId -> PortId -> PortAngle.
-}
type alias PortAngles comparable =
    Dict comparable (Dict Int Float)


{-| Model and (custom) command.
reheat の有無．

  - Link Distance, Port Angles などを更新した際には，reheat が必要になる．
  - portCtrlPDistance を更新した場合は（現在はこれだけ），reheat は不要．

-}
type alias Config =
    { reheat : Bool
    , settings : Settings
    }


{-| Model of the view.

portAngles に関して．

  - FuncterPortAngles: The dictionary to hold the angles of the ports for each functors.
      - Functor -> PortId -> Angle
  - NodePortAngles: The dictionary to hold the angles of the ports for each atoms.
      - NodeId (id of the atoms) -> PortId -> Angle
  - NodeFunctors: Node -> Functor

-}
type alias Model =
    { settings : Settings
    , accordionSettings : Accordion.State
    , functorPortAngles : PortGraph.InitialPortAngles
    }


{-| The state of the settings.

portAngles に関して．

  - FuncterPortAngles: The dictionary to hold the angles of the ports for each functors.
      - Functor -> PortId -> Angle
  - NodePortAngles: The dictionary to hold the angles of the ports for each atoms.
      - NodeId (id of the atoms) -> PortId -> Angle
  - NodeFunctors: Node -> Functor

-}
type alias Settings =
    { atomSize : Float
    , distance : Float
    , portDistance : Float
    , portCtrlPDistance : Float
    , strength : Float
    , accordionSettings : Accordion.State
    , portAngles : PortAngles Int
    }



-- Init


{-| The initial state of the settings.
-}
initialSettings : Settings
initialSettings =
    { atomSize = 20.0
    , distance = 5.0
    , portDistance = 50.0
    , portCtrlPDistance = 40.0
    , strength = 1.2
    , accordionSettings = Accordion.initialStateCardOpen "card1"
    }



-- initialConfig =
--     { settings = initialSettings, reheat = False}
-- Subscriptions


{-| We have three groups of subscriptions:
-}
subscriptions : Config -> Sub Msg
subscriptions model =
    Accordion.subscriptions model.settings.accordionSettings AccordionSettingsMsg



-- Update


update : Msg -> Settings -> Config
update msg model =
    case msg of
        AccordionSettingsMsg show ->
            Config False { model | accordionSettings = show }

        SlidePortAngleFunctor functor portId portAngle ->
            let
                graph =
                    T.mapThird (\g -> { g | atoms = PortGraph.updatePortAnglesWithFunctor portAngle functor portId g.atoms }) state.graph

                portDict =
                    PortGraph.toPortDict <| T.third graph
            in
            ( Ready
                { state
                    | graph = graph
                    , simulation = Force.reheat <| Force.updatePortDict portDict state.simulation
                }
            , Cmd.none
            )

        ( SlidePortAngleFunctor _ _ _, _ ) ->
            ( model, Cmd.none )

        ( SlidePortAngle nodePortId portAngle, Ready state ) ->
            let
                graph =
                    T.mapThird (PortGraph.updatePortAngleOfGraph portAngle nodePortId) state.graph

                portDict =
                    PortGraph.toPortDict <| T.third graph
            in
            ( Ready
                { state
                    | graph = graph
                    , simulation = Force.reheat <| Force.updatePortDict portDict state.simulation
                }
            , Cmd.none
            )

        ( SlidePortAngle _ _, _ ) ->
            ( model, Cmd.none )

        ( SlidePortCtrlPDistance f, Ready state ) ->
            ( Ready
                { state
                    | portCtrlPDistance = f
                }
            , Cmd.none
            )

        ( SlidePortCtrlPDistance f, _ ) ->
            ( model, Cmd.none )

        ( SlidePortDistance f, Ready state ) ->
            ( Ready
                { state
                    | portDistance = f
                    , simulation = Force.reheat <| Force.updatePortDistance f state.simulation
                }
            , Cmd.none
            )

        ( SlidePortDistance f, _ ) ->
            ( model, Cmd.none )

        ( SlideDistance f, Ready state ) ->
            ( Ready
                { state
                    | distance = f
                    , simulation = Force.reheat <| Force.updateDistanceStrengthsInState f state.strength state.simulation
                }
            , Cmd.none
            )

        ( SlideDistance f, _ ) ->
            ( model, Cmd.none )

        ( SlideStrength f, Ready state ) ->
            ( Ready
                { state
                    | strength = f
                    , simulation = Force.reheat <| Force.updateDistanceStrengthsInState state.strength f state.simulation
                }
            , Cmd.none
            )

        ( SlideStrength f, _ ) ->
            ( model, Cmd.none )


handleDragAt : ( Float, Float ) -> ReadyState -> ( Model, Cmd Msg )
handleDragAt xy ({ drag, simulation } as state) =
    case drag of
        Just { start, index } ->
            ( Ready
                { state
                    | drag =
                        Just
                            { start = start
                            , current = xy
                            , index = index
                            }
                    , graph = updateNodePosition index xy state
                    , simulation = Force.reheat simulation
                }
            , Cmd.none
            )

        Nothing ->
            ( Ready state, Cmd.none )


handleTick : ReadyState -> ( Model, Cmd Msg )
handleTick state =
    let
        ( newSimulation, list ) =
            Force.tick state.simulation <|
                List.map .label <|
                    Graph.nodes <|
                        T.first state.graph
    in
    case state.drag of
        Nothing ->
            ( Ready
                { state
                    | graph = updateGraphWithList state.graph list
                    , showGraph = True
                    , simulation = newSimulation
                }
            , Cmd.none
            )

        Just { current, index } ->
            ( Ready
                { state
                    | graph =
                        T.mapFirst
                            (Graph.update index
                                (Maybe.map
                                    (updateNode
                                        (shiftPosition state.zoom ( state.element.x, state.element.y ) current)
                                    )
                                )
                            )
                            (updateGraphWithList state.graph list)
                    , showGraph = True
                    , simulation = newSimulation
                }
            , Cmd.none
            )


updateNode :
    ( Float, Float )
    -> NodeContext Entity ()
    -> NodeContext Entity ()
updateNode ( x, y ) nodeCtx =
    let
        nodeValue =
            nodeCtx.node.label
    in
    updateContextWithValue nodeCtx { nodeValue | x = x, y = y }


updateNodePosition : NodeId -> ( Float, Float ) -> ReadyState -> GraphEdges
updateNodePosition index xy state =
    T.mapFirst
        (Graph.update
            index
            (Maybe.map
                (updateNode
                    (shiftPosition
                        state.zoom
                        ( state.element.x, state.element.y )
                        xy
                    )
                )
            )
        )
        state.graph


updateContextWithValue :
    NodeContext Entity ()
    -> Entity
    -> NodeContext Entity ()
updateContextWithValue nodeCtx value =
    let
        node =
            nodeCtx.node
    in
    { nodeCtx | node = { node | label = value } }


updateGraphWithList : GraphEdges -> List Entity -> GraphEdges
updateGraphWithList ( graph, edges, portDict ) list =
    let
        graphUpdater value =
            Maybe.map (\ctx -> updateContextWithValue ctx value)
    in
    ( List.foldr (\node g -> Graph.update node.id (graphUpdater node) g) graph list, edges, portDict )



-- View


viewSettings : VisGraph.Model -> Html VisGraph.Msg
viewSettings model =
    let
        graph =
            case model of
                VisGraph.Init g ->
                    g

                VisGraph.Ready state ->
                    state.graph

        viewSpringSettings =
            case model of
                VisGraph.Ready state ->
                    Grid.container []
                        [ viewSlider "Link Distance" initialDistance SlideDistance state.distance
                        , viewSlider "Port Distance" initialPortDistance SlidePortDistance state.portDistance
                        , viewSlider "Strength" initialStrength SlideStrength state.strength
                        , viewSlider "portCtrlPDistance" initialPortCtrlPDistance SlidePortCtrlPDistance state.portCtrlPDistance
                        ]

                _ ->
                    div [] []
    in
    Accordion.config VisGraph.AccordionSettingsMsg
        |> Accordion.withAnimation
        |> Accordion.cards
            [ Accordion.card
                { id = "card1"
                , options = []
                , header =
                    Accordion.header [] <| Accordion.toggle [] [ text "Spring Settings" ]
                , blocks =
                    [ Accordion.block []
                        [ Block.text [] [ viewSpringSettings ] ]
                    ]
                }
            , Accordion.card
                { id = "card2"
                , options = []
                , header =
                    Accordion.header [] <| Accordion.toggle [] [ text "Port Angles" ]
                , blocks =
                    [ Accordion.block []
                        [ Block.text [] [ viewPortAngleFunctorSliders <| T.third graph ] ]
                    ]
                }
            , Accordion.card
                { id = "card3"
                , options = []
                , header =
                    Accordion.header [] <| Accordion.toggle [] [ text "Port Angles (Separately)" ]
                , blocks =
                    [ Accordion.block []
                        [ Block.text [] [ viewPortAngleSliders <| T.third graph ] ]
                    ]
                }
            ]
        |> Accordion.view (stateTo (Accordion.initialStateCardOpen "card1") .accordionSettings model)


{-| `viewSlider msg f` creates a new html element with f that emmit msg on input.
-}
viewSlider : String -> Float -> (Float -> VisGraph.Msg) -> Float -> Html VisGraph.Msg
viewSlider label initialValue msg parameter =
    Grid.row [ Row.betweenMd ]
        [ Grid.col [ Col.xs4 ] [ text label ]
        , Grid.col [ Col.xs4 ]
            [ Html.input
                [ HAttrs.type_ "range"
                , HAttrs.class "input-range"
                , HAttrs.style "width" "100%"
                , Attrs.min <| String.fromFloat <| initialValue / 100
                , Attrs.max <| String.fromFloat <| initialValue * 4
                , HAttrs.step <| String.fromFloat <| initialValue / 10
                , HAttrs.value <| String.fromFloat parameter
                , HEvents.onInput (msg << Maybe.withDefault 0 << String.toFloat)
                ]
                []
            ]
        , Grid.col [ Col.xs4 ] [ text <| String.fromFloat parameter ]
        ]



-- viewPortAngleFunctorSliders


{-| `viewSlider msg f` creates a new html element with f that emmit msg on input.
-}
viewPortAngleFunctorSlider : String -> Functor -> Int -> Float -> Html VisGraph.Msg
viewPortAngleFunctorSlider portLabel functor portId portAngle =
    Grid.row [ Row.betweenMd ]
        [ Grid.col [ Col.xs2 ] [ text portLabel ]
        , Grid.col [ Col.xs6 ]
            [ Html.input
                [ HAttrs.type_ "range"
                , HAttrs.class "input-range"
                , HAttrs.class "input-range-port-angle"
                , HAttrs.style "width" "100%"
                , Attrs.min "0"
                , Attrs.max "360"
                , HAttrs.step "30"
                , HAttrs.value <| String.fromFloat portAngle
                , HEvents.onInput (VisGraph.SlidePortAngleFunctor functor portId << Maybe.withDefault 0 << String.toFloat)
                ]
                []
            ]
        , Grid.col [ Col.xs4 ] [ text <| String.fromFloat portAngle ]
        ]


viewPortAngleFunctorSliders : PortGraph.Graph Int -> Html Msg
viewPortAngleFunctorSliders graph =
    let
        functors =
            List.map T2.first <|
                PortGraph.groupAtomsWithFunctor graph

        helper atom =
            Grid.row [ Row.betweenXl ]
                [ Grid.col [ Col.xs3 ] [ text <| PortGraph.functorToString <| PortGraph.functorOfAtom atom ]
                , Grid.col [ Col.xs9 ] <|
                    List.map (\p -> viewPortAngleFunctorSlider p.label (PortGraph.functorOfAtom atom) p.id p.angle) <|
                        Dict.values atom.ports
                ]
    in
    Grid.container [] <|
        List.map helper <|
            List.map T2.first <|
                PortGraph.groupAtomsWithFunctor graph



-- viewPortAngleSliders


{-| `viewSlider msg f` creates a new html element with f that emmit msg on input.
-}
viewPortAngleSlider : String -> NodePortId -> Float -> Html Msg
viewPortAngleSlider portLabel nodePortId portAngle =
    Grid.row [ Row.betweenMd ]
        [ Grid.col [ Col.xs2 ] [ text portLabel ]
        , Grid.col [ Col.xs6 ]
            [ Html.input
                [ HAttrs.type_ "range"
                , HAttrs.class "input-range"
                , HAttrs.class "input-range-port-angle"
                , HAttrs.style "width" "100%"
                , Attrs.min "0"
                , Attrs.max "360"
                , HAttrs.step "30"
                , HAttrs.value <| String.fromFloat portAngle
                , HEvents.onInput (SlidePortAngle nodePortId << Maybe.withDefault 0 << String.toFloat)
                ]
                []
            ]
        , Grid.col [ Col.xs4 ] [ text <| String.fromFloat portAngle ]
        ]


viewPortAngleSliders : PortGraph.Graph Int -> Html Msg
viewPortAngleSliders { atoms } =
    let
        helper atom =
            Grid.row [ Row.betweenXl ]
                [ Grid.col [ Col.xs1 ] [ text <| String.fromInt atom.id ]
                , Grid.col [ Col.xs2 ] [ text <| atom.label ]
                , Grid.col [ Col.xs9 ] <|
                    List.map (\p -> viewPortAngleSlider p.label ( atom.id, p.id ) p.angle) <|
                        Dict.values atom.ports
                ]
    in
    Grid.container [] <|
        List.map helper <|
            Dict.values atoms
