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
import Dict.Extra as DictX
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
import PortGraph.Util as Util
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



-- Types


type alias PortAngle =
    Float


type alias NodePortId =
    ( PortGraph.NodeId Int, PortId )


type alias FunctorPortId =
    ( PortGraph.Functor, PortId )


{-| TODO: Description.
-}
type Msg
    = SlideDistance Float
    | SlidePortDistance Float
    | SlidePortCtrlPDistance Float
    | SlideStrength Float
    | SlidePortAngle NodePortId PortAngle
    | SlidePortAngleFunctor FunctorPortId PortAngle
    | AccordionSettingsMsg Accordion.State


type alias PortExtra p =
    { p | angle : PortAngle, label : String }


{-| NodeId -> PortId -> PortAngle.
-}
type alias PortAngles p =
    Dict NodePortId (PortExtra p)


type alias FunctorPortAngles p =
    Dict Functor (Dict PortId (PortExtra p))


type alias NodeFunctors =
    Dict NodeId Functor


{-| Model and (custom) command.
A direction given to Force.
reheat の有無．

  - Link Distance, Port Angles などを更新した際には，reheat が必要になる．
  - portCtrlPDistance を更新した場合は（現在はこれだけ），reheat は不要．

-}
type alias Config p =
    { reheat : Bool
    , settings : Settings p
    }


{-| The state of the settings.

portAngles に関して．

  - FunctorPortAngles: The dictionary to hold the angles of the ports for each functors.
      - Functor -> PortId -> Angle
  - NodePortAngles: The dictionary to hold the angles of the ports for each atoms.
      - NodeId (id of the atoms) -> PortId -> Angle
  - NodeFunctors: Node -> Functor

-}
type alias Settings p =
    { atomSize : Float
    , distance : Float
    , portDistance : Float
    , portCtrlPDistance : Float
    , strength : Float
    , portAngles : PortAngles p
    }


{-| Model of the view.

portAngles に関して．

  - FunctorPortAngles: The dictionary to hold the angles of the ports for each functors.
      - Functor -> PortId -> Angle
  - NodePortAngles: The dictionary to hold the angles of the ports for each atoms.
      - NodeId (id of the atoms) -> PortId -> Angle
  - functorPortAngles: Functor -> Maybe Angle
  - nodeFunctors : NodeId -> Functor

-}
type alias Model p =
    { settings : Settings p
    , accordionSettings : Accordion.State
    , functorPortAngles : FunctorPortAngles p
    , nodeFunctors : NodeFunctors
    }



-- Init


{-| The initial state of the settings.
-}
initialSettings : Settings p
initialSettings =
    { atomSize = 20.0
    , distance = 5.0
    , portDistance = 50.0
    , portCtrlPDistance = 40.0
    , strength = 1.2
    , portAngles = Dict.empty
    }


{-| TODO: `functorPortAngles` に登録されていない functor がくると empty を返してしまう．
-}
initSettings : NodeFunctors -> FunctorPortAngles p -> Settings p
initSettings nodeFunctors functorPortAngles =
    let
        helper : ( NodeId, Functor ) -> PortAngles p
        helper ( nodeId, functor ) =
            DictX.mapKeys (\pid -> ( nodeId, pid )) <|
                Maybe.withDefault Dict.empty <|
                    Dict.get functor functorPortAngles
    in
    { initialSettings | portAngles = Util.mergeDicts <| List.map helper <| Dict.toList nodeFunctors }


initModel : NodeFunctors -> FunctorPortAngles p -> Model p
initModel nodeFunctors functorPortAngles =
    { settings = initSettings nodeFunctors functorPortAngles
    , accordionSettings = Accordion.initialStateCardOpen "card1"
    , functorPortAngles = functorPortAngles
    , nodeFunctors = nodeFunctors
    }


initialConfig =
    { settings = initialSettings, reheat = False }



-- Subscriptions


{-| We have three groups of subscriptions:
-}
subscriptions : Model p -> Sub Msg
subscriptions model =
    Accordion.subscriptions model.accordionSettings AccordionSettingsMsg



-- Update


config : Bool -> Model p -> ( Model p, Config p )
config reheat model =
    ( model, { settings = model.settings, reheat = reheat } )


update : Msg -> Model p -> ( Model p, Config p )
update msg model =
    let
        settings =
            model.settings
    in
    case msg of
        AccordionSettingsMsg accordionSettings ->
            config False { model | accordionSettings = accordionSettings }

        SlideDistance distance ->
            config False { model | settings = { settings | distance = distance } }

        SlidePortDistance portDistance ->
            config False { model | settings = { settings | portDistance = portDistance } }

        SlidePortCtrlPDistance portCtrlPDistance ->
            config False { model | settings = { settings | portCtrlPDistance = portCtrlPDistance } }

        SlideStrength strength ->
            config False { model | settings = { settings | strength = strength } }

        SlidePortAngle nodePortId portAngle ->
            config False
                { model
                    | settings =
                        { settings
                            | portAngles =
                                Dict.update nodePortId (Maybe.map (\p -> { p | angle = portAngle })) model.settings.portAngles
                        }
                }

        SlidePortAngleFunctor ( functor, portId ) portAngle ->
            let
                helper ( nodeId, pid ) p =
                    if Dict.get nodeId model.nodeFunctors == Just functor && pid == portId then
                        { p | angle = portAngle }

                    else
                        p

                portAngles =
                    Dict.map helper model.settings.portAngles

                functorPortAngles =
                    Dict.update functor
                        (Maybe.map
                            (\ps ->
                                Dict.update portId (Maybe.map (\p -> { p | angle = portAngle })) ps
                            )
                        )
                        model.functorPortAngles
            in
            config False { model | functorPortAngles = functorPortAngles, settings = { settings | portAngles = portAngles } }



-- View


{-| `viewSlider msg f` creates a new html element with f that emmit msg on input.
-}
viewSlider : String -> Float -> (Float -> Msg) -> Float -> Html Msg
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
viewPortAngleFunctorSlider : String -> Functor -> Int -> Float -> Html Msg
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
                , HEvents.onInput (SlidePortAngleFunctor ( functor, portId ) << Maybe.withDefault 0 << String.toFloat)
                ]
                []
            ]
        , Grid.col [ Col.xs4 ] [ text <| String.fromFloat portAngle ]
        ]


viewPortAngleFunctorSliders : FunctorPortAngles p -> Html Msg
viewPortAngleFunctorSliders functorPortAngles =
    let
        helper ( functor, portAngles ) =
            Grid.row [ Row.betweenXl ]
                [ Grid.col [ Col.xs3 ] [ text <| PortGraph.functorToString functor ]
                , Grid.col [ Col.xs9 ] <|
                    List.map (\( pid, p ) -> viewPortAngleFunctorSlider p.label functor pid p.angle) <|
                        Dict.toList portAngles
                ]
    in
    Grid.container [] <|
        List.map helper <|
            Dict.toList functorPortAngles



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


getAtomName : NodeFunctors -> NodeId -> String
getAtomName nodeFunctors nodeId =
    Dict.get nodeId nodeFunctors
        |> Maybe.map (\funct -> PortGraph.functorToString funct)
        |> Maybe.withDefault ""


viewPortAngleSliders : NodeFunctors -> PortAngles p -> Html Msg
viewPortAngleSliders nodeFunctors portAngles =
    let
        helper ( ( nodeId, portId ) as nodePortId, portAngle ) =
            Grid.row [ Row.betweenXl ]
                [ Grid.col [ Col.xs1 ] [ text <| String.fromInt nodeId ]
                , Grid.col [ Col.xs2 ] [ text <| getAtomName nodeFunctors nodeId ]
                , Grid.col [ Col.xs9 ] <|
                    List.map (\p -> viewPortAngleSlider p.label nodePortId p.angle) <|
                        Dict.values portAngles
                ]
    in
    Grid.container [] <|
        List.map helper <|
            Dict.toList portAngles


{-| Main View
-}
viewSettings : Model p -> Html Msg
viewSettings model =
    let
        viewSpringSettings =
            Grid.container []
                [ viewSlider "Link Distance" initialSettings.distance SlideDistance model.settings.distance
                , viewSlider "Port Distance" initialSettings.portDistance SlidePortDistance model.settings.portDistance
                , viewSlider "Strength" initialSettings.strength SlideStrength model.settings.strength
                , viewSlider "portCtrlPDistance" initialSettings.portCtrlPDistance SlidePortCtrlPDistance model.settings.portCtrlPDistance
                ]
    in
    Accordion.config AccordionSettingsMsg
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
                        [ Block.text [] [ viewPortAngleFunctorSliders model.functorPortAngles ] ]
                    ]
                }
            , Accordion.card
                { id = "card3"
                , options = []
                , header =
                    Accordion.header [] <| Accordion.toggle [] [ text "Port Angles (Separately)" ]
                , blocks =
                    [ Accordion.block []
                        [ Block.text [] [ viewPortAngleSliders model.nodeFunctors model.settings.portAngles ] ]
                    ]
                }
            ]
        |> Accordion.view model.accordionSettings
