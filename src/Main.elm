port module Main exposing (main)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

-}

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Tab as Tab
import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Html exposing (Html, div, text)
import Html.Attributes as HAttrs exposing (style)
import Html.Events as HEvents
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import PortGraph exposing (Functor, PortId)
import PortGraphExample
import Task
import VisGraph



-- Constants


elementId : String
elementId =
    "exercise-graph"



-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- Types


type Msg
    = VisGraphMsg VisGraph.Msg
    | Send
    | Recv (Result Decode.Error Message)
    | TabMsg Tab.State


type alias Model =
    { visGraph : VisGraph.Model
    , messages : List String
    , tabState : Tab.State
    }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        VisGraphMsg visGraphMsg ->
            let
                ( visGraphModel, visGraphCmd ) =
                    VisGraph.update visGraphMsg model.visGraph
            in
            ( { model | visGraph = visGraphModel }, Cmd.map VisGraphMsg visGraphCmd )

        Send ->
            ( { model | messages = List.take 3 <| "Send" :: model.messages }
            , sendMessage "HOGEEEE"
            )

        Recv (Err err) ->
            ( { model | messages = List.take 3 <| Decode.errorToString err :: model.messages }
            , Cmd.none
            )

        Recv (Ok { graph, info }) ->
            let
                msgString =
                    info ++ ": " ++ PortGraph.toString String.fromInt graph
            in
            ( { model
                | messages = List.take 3 <| msgString :: model.messages
                , visGraph = VisGraph.updateGraph graph model.visGraph
              }
            , Cmd.none
            )

        TabMsg state ->
            ( { model | tabState = state }
            , Cmd.none
            )



-- Initialize


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( visGraphModel, visGraphCmd ) =
            VisGraph.init <| VisGraph.initialiseGraph PortGraphExample.listGraph
    in
    ( { messages = []
      , visGraph = visGraphModel
      , tabState = Tab.customInitialState "tabItem1"
      }
    , Cmd.map VisGraphMsg visGraphCmd
    )



-- View


view : Model -> Html Msg
view model =
    let
        divSendButton =
            Button.button [ Button.primary, Button.onClick <| Send ] [ text "Primary" ]

        divMessages =
            Html.ul [] <| List.map (\msg -> Html.li [] [ text msg ]) model.messages
    in
    div []
        [ CDN.stylesheet
        , div []
            -- [ style "background-color" "rgba(190, 220, 225, 0.9)"
            -- , style "padding" "30px"
            -- , style "color" "#303050"
            -- ]
            [ Tab.config TabMsg
                |> Tab.withAnimation
                -- remember to wire up subscriptions when using this option
                -- |> Tab.right
                |> Tab.items
                    [ Tab.item
                        { id = "tabItem1"
                        , link = Tab.link [] [ text "Playground" ]
                        , pane =
                            Tab.pane []
                                [ Html.map VisGraphMsg <| VisGraph.view model.visGraph
                                , divSendButton
                                ]
                        }
                    , Tab.item
                        { id = "tabItem2"
                        , link = Tab.link [] [ text "Info" ]
                        , pane = Tab.pane [] [ text "Tab 2 Content" ]
                        }
                    ]
                |> Tab.view model.tabState
            , divMessages
            ]
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map VisGraphMsg <| VisGraph.subscriptions model.visGraph
        , messageReceiver <| Recv << Decode.decodeString decodeMessage
        , Tab.subscriptions model.tabState TabMsg
        ]



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Message to interop backend interpreter.


type alias Message =
    { graph : PortGraph.Graph Int
    , isEnded : Bool
    , info : String
    }


decodeMessage : Decoder Message
decodeMessage =
    Decode.succeed Message
        |> DP.required "graph" PortGraph.decodeGraph
        |> DP.required "isEnded" Decode.bool
        |> DP.required "info" Decode.string
