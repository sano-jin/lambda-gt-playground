module PortGraph.VisGraph exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

TODO:

  - Documentation.
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

import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Html exposing (Html, div)
import Html.Attributes as HAttrs exposing (style)
import Html.Events as HEvents
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import PortGraph.ForceExtra as Force
import PortGraph.PortGraph as PortGraph exposing (Functor, PortId)
import PortGraph.Util as Util
import PortGraph.ViewSettings as ViewSettings
import Process
import Task
import Time
import Tuple as T2
import Tuple3 as T3
import TypedSvg exposing (circle, defs, g, line, marker, polygon, rect, svg, text_, title)
import TypedSvg.Attributes as Attrs exposing (class, cursor, fill, fontSize, id, markerEnd, markerHeight, markerWidth, orient, pointerEvents, points, refX, refY, stroke, transform)
import TypedSvg.Attributes.InPx exposing (cx, cy, dx, dy, height, r, strokeWidth, width, x1, x2, y1, y2)
import TypedSvg.Core exposing (Attribute, Svg, text)
import TypedSvg.Types exposing (AlignmentBaseline(..), AnchorAlignment(..), Cursor(..), Length(..), Opacity(..), Paint(..), Transform(..))
import Zoom exposing (OnZoom, Zoom)



-- Constants


elementId : String
elementId =
    "exercise-graph"


edgeColor : Paint
edgeColor =
    Paint <| Color.rgb255 160 190 250



-- Types


type alias NodePortId =
    ( PortGraph.NodeId Int, PortId )


type Msg
    = DragAt ( Float, Float )
    | DragEnd ( Float, Float )
    | DragStart NodeId ( Float, Float )
    | ReceiveElementPosition (Result Dom.Error Dom.Element)
    | Resize Int Int
    | Tick Time.Posix
    | ZoomMsg OnZoom



--     | ViewSettingsMsg ViewSettings.Msg


type alias GraphEdges =
    ( Graph Entity (), List (PortGraph.Edge Int), PortGraph.Graph Int )


{-| In order to correctly calculate the node positions, we need to know the
coordinates of the svg element. The simulation is started when we
receive them.
-}
type Model
    = Init GraphEdges
    | Ready ReadyState


stateOfModel : Model -> Maybe ReadyState
stateOfModel model =
    case model of
        Init g ->
            Nothing

        Ready state ->
            Just state


stateTo : a -> (ReadyState -> a) -> Model -> a
stateTo default f model =
    Maybe.withDefault default <| Maybe.map f <| stateOfModel model


type alias ReadyState =
    { drag : Maybe Drag
    , graph : GraphEdges
    , simulation : Force.State NodeId
    , zoom : Zoom

    -- The position and dimensions of the svg element.
    , element : Element

    -- If you immediately show the graph when moving from `Init` to `Ready`,
    -- you will briefly see the nodes in the upper left corner before the first
    -- simulation tick positions them in the center. To avoid this sudden jump,
    -- `showGraph` is initialized with `False` and set to `True` with the first
    -- `Tick`.
    , showGraph : Bool
    , distance : Float
    , portDistance : Float
    , portCtrlPDistance : Float
    , strength : Float
    , size : ( Float, Float )
    }


type alias Drag =
    { current : ( Float, Float )
    , index : NodeId
    , start : ( Float, Float )
    }


type alias Element =
    { height : Float
    , width : Float
    , x : Float
    , y : Float
    }


type alias Entity =
    Force.Entity NodeId { value : String }



-- Init


{-| `initialiseGraph inputGraph` converts `inputGraph` to the graph we use in the visualisation process.
-}
initialiseGraph : PortGraph.Graph Int -> GraphEdges
initialiseGraph portGraph =
    let
        graph : Graph Entity ()
        graph =
            Graph.mapContexts initNode <| graphData portGraph
    in
    ( graph, PortGraph.toEdges portGraph, portGraph )


{-| We initialize the graph here, but we don't start the simulation yet, because
we first need the position and dimensions of the svg element to calculate the
correct node positions and the center force.

We get the element after 100ms sleep.
This is because that the browser need a second for positioning the element
especially we use flex containers.

-}
init : GraphEdges -> ( Model, Cmd Msg )
init graphEdges =
    ( Init graphEdges
    , Task.attempt ReceiveElementPosition
        (Process.sleep 100 |> Task.andThen (\_ -> Dom.getElement elementId))
    )


{-| The graph data we defined at the end of the module has the type
`Graph String ()`. We have to convert it into a `Graph Entity ()`.
`Force.Entity` is an extensible record which includes the coordinates for the
node.
-}
initNode : NodeContext String () -> NodeContext Entity ()
initNode ctx =
    { node =
        { label = Force.entity ctx.node.id ctx.node.label
        , id = ctx.node.id
        }
    , incoming = ctx.incoming
    , outgoing = ctx.outgoing
    }


{-| Initializes the simulation by setting the forces for the graph.
-}
initSimulation : Float -> Float -> Float -> GraphEdges -> ( Float, Float ) -> Force.State NodeId
initSimulation d portDistance strength ( graph, edges, portDict ) ( width, height ) =
    let
        link : { c | from : a, to : b } -> ( a, b )
        link { from, to } =
            ( from, to )
    in
    Force.simulation
        [ -- Defines the force that pulls connected nodes together. You can use
          -- `Force.customLinks` if you need to adjust the distance and
          -- strength.
          Force.links d portDistance (Just strength) (PortGraph.toPortDict portDict) <| List.map link <| edges

        -- Defines the force that pushes the nodes apart. The default strength
        -- is `-30`, but since we are drawing fairly large circles for each
        -- node, we need to increase the repulsion by decreasing the strength to
        -- `-150`.
        , Force.manyBodyStrength -150 <| List.map .id <| Graph.nodes graph
        , Force.collision 41 <| List.map .id <| Graph.nodes graph

        -- Defines the force that pulls nodes to a center. We set the center
        -- coordinates to the center of the svg viewport.
        , Force.center (width / 2) (height / 2)
        ]
        |> Force.iterations 400


{-| Initializes the zoom and sets a minimum and maximum zoom level.

You can also use `Zoom.translateExtent` to restrict the area in which the user
may drag, but since the graph is larger than the viewport and the exact
dimensions depend on the data and the final layout, you would either need to use
some kind of heuristic for the final dimensions here, or you would have to let
the simulation play out (or use `Force.computeSimulate` to calculate it at
once), find the min and max x and y positions of the graph nodes and use those
values to set the translate extent.

-}
initZoom : Element -> Zoom
initZoom element =
    Zoom.init { width = element.width, height = element.height }
        |> Zoom.scaleExtent 0.1 2


initialAtomSize =
    20.0


initialDistance =
    5.0


initialPortDistance =
    50.0


initialPortCtrlPDistance =
    40.0


initialStrength =
    1.2



-- Subscriptions


{-| We have three groups of subscriptions:

1.  Mouse events, to handle mouse interaction with the nodes.
2.  A subscription on the animation frame, to trigger simulation ticks.
3.  Browser resizes, to update the zoom state and the position of the nodes
    when the size and position of the svg viewport change.

We want to make sure that we only subscribe to mouse events while there is
a mouse interaction in progress, and that we only subscribe to
`Browser.Events.onAnimationFrame` while the simulation is in progress.

-}
subscriptions : Model -> Sub Msg
subscriptions model =
    let
        dragSubscriptions : Sub Msg
        dragSubscriptions =
            Sub.batch
                [ Events.onMouseMove
                    (Decode.map (.clientPos >> DragAt) Mouse.eventDecoder)
                , Events.onMouseUp
                    (Decode.map (.clientPos >> DragEnd) Mouse.eventDecoder)
                , Events.onAnimationFrame Tick
                ]

        readySubscriptions : ReadyState -> Sub Msg
        readySubscriptions { drag, simulation, zoom } =
            Sub.batch
                [ Zoom.subscriptions zoom ZoomMsg
                , case drag of
                    Nothing ->
                        if Force.isCompleted simulation then
                            Sub.none

                        else
                            Events.onAnimationFrame Tick

                    Just _ ->
                        dragSubscriptions
                ]
    in
    Sub.batch
        [ case model of
            Init _ ->
                Sub.none

            Ready state ->
                readySubscriptions state
        , Events.onResize Resize

        -- , messageReceiver <| Recv << Decode.decodeString decodeMessage
        ]



-- Update


configGraph : ViewSettings.Config p -> Model -> Model
configGraph { reheat, settings } model =
    case model of
        Init graph ->
            model

        Ready state ->
            let
                graph =
                    Dict.foldl
                        (\nodePortId p g -> PortGraph.updatePortAngleOfGraph p.angle nodePortId g)
                        (T3.third state.graph)
                        settings.portAngles

                portDict =
                    PortGraph.toPortDict graph

                simulation =
                    Force.updatePortDistance settings.portDistance <|
                        Force.updatePortDict portDict <|
                            Force.updateDistanceStrengthsInState settings.distance settings.strength state.simulation

                simulationReheated =
                    if reheat then
                        Force.reheat simulation

                    else
                        simulation
            in
            Ready
                { state
                    | graph = initialiseGraph graph
                    , simulation = simulationReheated
                    , portCtrlPDistance = settings.portCtrlPDistance
                }


updateGraph : ViewSettings.Config p -> PortGraph.Graph Int -> Model -> Model
updateGraph config portGraph model =
    let
        ge : Graph Entity ()
        ge =
            Graph.mapContexts initNode <| graphData portGraph

        graph =
            ( ge, PortGraph.toEdges portGraph, portGraph )
    in
    case model of
        Init g ->
            Init graph

        Ready state ->
            configGraph config <|
                Ready
                    { state
                        | graph = graph
                        , simulation =
                            initSimulation
                                initialDistance
                                initialPortDistance
                                initialStrength
                                graph
                                state.size
                    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Tick _, Ready state ) ->
            handleTick state

        ( Tick _, Init _ ) ->
            ( model, Cmd.none )

        ( DragAt xy, Ready state ) ->
            handleDragAt xy state

        ( DragAt _, Init _ ) ->
            ( model, Cmd.none )

        ( DragEnd xy, Ready state ) ->
            case state.drag of
                Just { index } ->
                    ( Ready
                        { state
                            | drag = Nothing
                            , graph = updateNodePosition index xy state
                        }
                    , Cmd.none
                    )

                Nothing ->
                    ( Ready state, Cmd.none )

        ( DragEnd _, Init _ ) ->
            ( model, Cmd.none )

        ( DragStart index xy, Ready state ) ->
            ( Ready
                { state
                    | drag =
                        Just
                            { start = xy
                            , current = xy
                            , index = index
                            }
                }
            , Cmd.none
            )

        ( DragStart _ _, Init _ ) ->
            ( model, Cmd.none )

        ( ReceiveElementPosition (Ok { element }), Init graph ) ->
            -- When we get the svg element position and dimensions, we are
            -- ready to initialize the simulation and the zoom, but we cannot
            -- show the graph yet. If we did, we would see a noticable jump.
            ( Ready
                { drag = Nothing
                , element = element
                , graph = graph
                , showGraph = False
                , simulation =
                    initSimulation
                        initialDistance
                        initialPortDistance
                        initialStrength
                        graph
                        ( element.width, element.height )
                , zoom = initZoom element
                , distance = initialDistance
                , portDistance = initialPortDistance
                , portCtrlPDistance = initialPortCtrlPDistance
                , strength = initialStrength
                , size = ( element.width, element.height )
                }
            , Cmd.none
            )

        ( ReceiveElementPosition (Ok { element }), Ready state ) ->
            ( Ready
                { drag = state.drag
                , element = element
                , graph = state.graph
                , showGraph = True
                , simulation =
                    initSimulation
                        state.distance
                        state.portDistance
                        state.strength
                        state.graph
                        ( element.width, element.height )
                , zoom = initZoom element
                , distance = state.distance
                , portDistance = state.portDistance
                , portCtrlPDistance = state.portCtrlPDistance
                , strength = state.strength
                , size = ( element.width, element.height )
                }
            , Cmd.none
            )

        ( ReceiveElementPosition (Err _), _ ) ->
            ( model, Cmd.none )

        ( Resize _ _, _ ) ->
            ( model, getElementPosition )

        ( ZoomMsg zoomMsg, Ready state ) ->
            ( Ready { state | zoom = Zoom.update zoomMsg state.zoom }
            , Cmd.none
            )

        ( ZoomMsg _, Init _ ) ->
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
                        T3.first state.graph
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
                        T3.mapFirst
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
    T3.mapFirst
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


{-| The mouse events for drag start, drag at and drag end read the client
position of the cursor, which is relative to the browser viewport. However,
the node positions are relative to the svg viewport. This function adjusts the
coordinates accordingly. It also takes the current zoom level and position
into consideration.
-}
shiftPosition : Zoom -> ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
shiftPosition zoom ( elementX, elementY ) ( clientX, clientY ) =
    let
        zoomRecord =
            Zoom.asRecord zoom
    in
    ( (clientX - zoomRecord.translate.x - elementX) / zoomRecord.scale
    , (clientY - zoomRecord.translate.y - elementY) / zoomRecord.scale
    )



-- view


view : Model -> Html Msg
view model =
    let
        zoomEvents : List (Attribute Msg)
        zoomEvents =
            case model of
                Init _ ->
                    []

                Ready { zoom } ->
                    Zoom.events zoom ZoomMsg

        zoomTransformAttr : Attribute Msg
        zoomTransformAttr =
            case model of
                Init _ ->
                    class []

                Ready { zoom } ->
                    Zoom.transform zoom
    in
    div
        [ style "width" "100%"
        , style "height" "100%"
        , style "margin" "0 auto"
        , style "background-color" "rgba(240, 250, 255, 0.9)"

        -- , style "border" "1px solid rgba(170, 190, 200, 0.3)"
        -- , style "background-color" "rgba(245, 255, 255, 1)"
        ]
        [ svg
            [ id elementId
            , Attrs.width <| Percent 100
            , Attrs.height <| Percent 100
            ]
            [ defs [] [ arrowhead ]
            , -- This transparent rectangle is placed in the background as a
              -- target for the zoom events. Note that the zoom transformation
              -- are not applied to this rectangle, but to group that contains
              -- the actual graph.
              rect
                ([ Attrs.width <| Percent 100
                 , Attrs.height <| Percent 100
                 , fill <| Paint <| Color.rgba 0 0 0 0
                 , cursor CursorMove
                 ]
                    ++ zoomEvents
                )
                []
            , g
                [ zoomTransformAttr ]
                [ renderGraph model ]
            ]
        ]


renderGraph : Model -> Svg Msg
renderGraph model =
    case model of
        Init _ ->
            text ""

        Ready { graph, showGraph, portDistance, portCtrlPDistance } ->
            if showGraph then
                g []
                    [ T3.second
                        graph
                        |> List.map (portLinkElement portCtrlPDistance (T3.third graph) <| T3.first graph)
                        |> g [ class [ "ports" ] ]
                    , Graph.nodes (T3.first graph)
                        |> List.map (nodeElement (T3.third graph) portDistance)
                        |> g [ class [ "nodes" ] ]
                    ]

            else
                text ""


{-| Draws a single vertex (node).
-}
nodeElement : PortGraph.Graph Int -> Float -> Node Entity -> Svg Msg
nodeElement graph portDistance node =
    let
        portCircle =
            circle
                [ r portDistance
                , strokeWidth 0
                , fill (Paint <| Color.rgba 0 0 0 0)
                , stroke <| Paint <| Color.rgb255 230 230 250
                , cursor CursorPointer
                , cx node.label.x
                , cy node.label.y
                , onMouseDown node.id
                ]
                [ title [] [ text node.label.value ] ]

        nodeCircle =
            case PortGraph.getAtom graph node.id of
                Just atom ->
                    circle
                        [ r initialAtomSize
                        , strokeWidth 0
                        , fill (Paint <| Color.rgb255 200 210 230)
                        , stroke (Paint <| Color.rgb255 100 150 190)
                        , cursor CursorPointer
                        , cx node.label.x
                        , cy node.label.y
                        , onMouseDown node.id
                        ]
                        [ title [] [ text node.label.value ] ]

                Nothing ->
                    circle
                        [ r (initialAtomSize * 0.8)
                        , strokeWidth 0
                        , fill (Paint <| Color.rgb255 240 240 250)
                        , cursor CursorPointer
                        , cx node.label.x
                        , cy node.label.y
                        , onMouseDown node.id
                        ]
                        [ title [] [ text node.label.value ] ]

        label =
            text_
                [ -- Align text label at the center of the circle.
                  dx <| node.label.x
                , dy <| node.label.y
                , Attrs.alignmentBaseline AlignmentMiddle
                , Attrs.textAnchor AnchorMiddle
                , fontSize <| Px 14
                , fill (Paint <| Color.rgb255 100 150 190)

                -- Setting pointer events to none allows the user to click on the
                -- element behind the text, so in this case the circle. If you
                -- position the text label outside of the circle, you also should
                -- do this, so that drag and zoom operations are not interrupted
                -- when the cursor is above the text.
                , pointerEvents "none"
                ]
                [ text node.label.value ]
    in
    g [ class [ "node" ] ]
        [ portCircle
        , nodeCircle
        , label
        ]


{-| This function draws the lines between the vertices.
-- getPortCoordinate 0 : Float -> PortDict comparable -> ConnectedTo comparable -> ( Float, Float ) -> ( Float, Float )
-}
portLinkElement : Float -> PortGraph.Graph Int -> Graph Entity () -> PortGraph.Edge Int -> Svg msg
portLinkElement portCtrlPDistance portGraph graph edge =
    let
        portDict =
            PortGraph.toPortDict portGraph

        source =
            Maybe.withDefault (Force.entity 0 "") <|
                Maybe.map (.node >> .label) <|
                    Graph.get (PortGraph.extractNodeId edge.from) graph

        target =
            Maybe.withDefault (Force.entity 0 "") <|
                Maybe.map (.node >> .label) <|
                    Graph.get (PortGraph.extractNodeId edge.to) graph

        ( sx, sy ) =
            Force.getPortCoordinate 0 initialAtomSize portDict edge.from ( source.x, source.y )

        ( tx, ty ) =
            Force.getPortCoordinate 0 initialAtomSize portDict edge.to ( target.x, target.y )

        ( sx2, sy2 ) =
            Force.getPortCoordinate 0 portCtrlPDistance portDict edge.from ( source.x, source.y )

        ( tx2, ty2 ) =
            Force.getPortCoordinate 0 portCtrlPDistance portDict edge.to ( target.x, target.y )

        ( label_x, label_y ) =
            Force.getPortCoordinate 20 (initialAtomSize + 12) portDict edge.from ( source.x, source.y )

        helper ( x, y ) =
            " " ++ String.fromFloat x ++ " " ++ String.fromFloat y ++ " "
    in
    g [ class [ "node" ] ]
        [ TypedSvg.path
            [ Attrs.d <| "M" ++ helper ( sx, sy ) ++ "C" ++ helper ( sx2, sy2 ) ++ helper ( tx2, ty2 ) ++ helper ( tx, ty )
            , strokeWidth 2
            , stroke <| edgeColor
            , Attrs.fillOpacity <| Opacity 0
            ]
            []
        , text_
            [ dx <| label_x
            , dy <| label_y
            , Attrs.alignmentBaseline AlignmentMiddle
            , Attrs.textAnchor AnchorMiddle
            , fontSize <| Px 14
            , fill (Paint <| Color.rgb255 100 150 190)
            , pointerEvents "none"
            ]
            [ text <| PortGraph.getPortLabel portDict edge.from ]
        ]



-- Definitions


{-| This is the definition of the arrow head that is displayed at the end of
the edges.

It is a child of the svg `defs` element and can be referenced by its id with
`url(#arrowhead)`.

-}
arrowhead : Svg msg
arrowhead =
    marker
        [ id "arrowhead"
        , orient "auto"
        , markerWidth <| Px 8.0
        , markerHeight <| Px 6.0
        , refX "29"
        , refY "3"
        ]
        [ polygon
            [ points [ ( 0, 0 ), ( 8, 3 ), ( 0, 6 ) ]
            , fill edgeColor
            ]
            []
        ]



-- Events and tasks


{-| This is the event handler that handles clicks on the vertices (nodes).

The event catches the `clientPos`, which is a tuple with the
`MouseEvent.clientX` and `MouseEvent.clientY` values. These coordinates are
relative to the client area (browser viewport).

If the graph is positioned anywhere else than at the coordinates `(0, 0)`, the
svg element position must be subtracted when setting the node position. This is
handled in the update function by calling the `shiftPosition` function.

-}
onMouseDown : NodeId -> Attribute Msg
onMouseDown index =
    Mouse.onDown (.clientPos >> DragStart index)


{-| This function returns a command to retrieve the position of the svg element.
-}
getElementPosition : Cmd Msg
getElementPosition =
    Task.attempt ReceiveElementPosition (Dom.getElement elementId)



-- Data


{-| This is the dataset for the graph.
-}
graphData : PortGraph.Graph Int -> Graph String ()
graphData portGraph =
    Graph.fromNodesAndEdges
        ((List.map (\atom -> Graph.Node atom.id atom.label) <| PortGraph.toAtoms portGraph)
            ++ (List.map (\hlink -> Graph.Node hlink.id hlink.label) <| PortGraph.toHLinks portGraph)
        )
    <|
        List.map (\edge -> Graph.Edge (PortGraph.extractNodeId edge.from) (PortGraph.extractNodeId edge.to) ()) <|
            PortGraph.toEdges portGraph
