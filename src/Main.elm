port module Main exposing (main)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

-}

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Navbar as Navbar
import Bootstrap.Tab as Tab
import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict
import Editor.Editor as Editor
import Examples
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Html exposing (Html, div, text)
import Html.Attributes as HAttrs exposing (style)
import Html.Events as HEvents
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import PortGraph.PortGraph as PortGraph exposing (Functor, PortId)
import PortGraph.PortGraphExample as PortGraphExample
import PortGraph.VisGraph as VisGraph
import Task



-- Constants


initialGraph : PortGraph.Graph Int
initialGraph =
    PortGraphExample.listGraph



-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg



-- Types


type Msg
    = VisGraphMsg VisGraph.Msg
    | SendRun
    | RecvRun (Result Decode.Error Message)
    | TabMsg Tab.State
    | EditorMsg Editor.Msg
    | NavbarMsg Navbar.State
    | ShowVisSettingsMsg Bool
    | LoadCode String


type alias Model =
    { visGraph : VisGraph.Model
    , messages : List String
    , tabState : Tab.State
    , editor : Editor.Model
    , navbarState : Navbar.State
    , showVisSettings : Bool
    }



-- Initialize


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( visGraphModel, visGraphCmd ) =
            VisGraph.init <| VisGraph.initialiseGraph initialGraph

        ( editorModel, editorCmd ) =
            Editor.init ()

        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { messages = []
      , visGraph = visGraphModel
      , tabState = Tab.customInitialState "tabItem1"
      , editor = Editor.updateCode Examples.lltree3 editorModel
      , navbarState = navbarState
      , showVisSettings = False
      }
    , Cmd.batch
        [ Cmd.map EditorMsg editorCmd
        , navbarCmd
        , Cmd.map VisGraphMsg visGraphCmd
        ]
    )



-- Update


updateCode : String -> Model -> Model
updateCode code model =
    { model
        | editor = Editor.updateCode code model.editor
        , messages = "udpateCode" :: model.messages
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadCode code ->
            ( updateCode code model, Cmd.none )

        ShowVisSettingsMsg show ->
            ( { model | showVisSettings = show }, Cmd.none )

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )

        EditorMsg editorMsg ->
            let
                ( editorModel, editorCmd ) =
                    Editor.update editorMsg model.editor
            in
            ( { model | editor = editorModel }, Cmd.map EditorMsg editorCmd )

        VisGraphMsg visGraphMsg ->
            let
                ( visGraphModel, visGraphCmd ) =
                    VisGraph.update visGraphMsg model.visGraph
            in
            ( { model | visGraph = visGraphModel }, Cmd.map VisGraphMsg visGraphCmd )

        SendRun ->
            ( { model | messages = List.take 20 <| "Send" :: model.messages }
            , sendMessage "HOGEEEE"
            )

        RecvRun (Err err) ->
            ( { model | messages = List.take 20 <| Decode.errorToString err :: model.messages }
            , Cmd.none
            )

        RecvRun (Ok { graph, info }) ->
            let
                msgString =
                    info ++ ": " ++ PortGraph.toString String.fromInt graph
            in
            ( { model
                | messages = List.take 20 <| msgString :: model.messages
                , visGraph = VisGraph.updateGraph graph model.visGraph
              }
            , Cmd.none
            )

        TabMsg state ->
            ( { model | tabState = state }
            , Cmd.none
            )



-- View


viewIcon : Html Msg
viewIcon =
    Html.span [] [ text "λ", Html.sub [] [ Html.i [] [ text "GT" ] ] ]


viewSettingsButton : Model -> Html Msg
viewSettingsButton model =
    Button.checkboxButton model.showVisSettings
        [ Button.secondary
        , Button.onClick <| ShowVisSettingsMsg <| not model.showVisSettings
        , Button.disabled <| model.showVisSettings
        ]
        [ text "Settings" ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        -- |> Navbar.fixBottom
        |> Navbar.dark
        -- |> Navbar.attrs [ HAttrs.style "padding" "100px" ]
        |> Navbar.brand [ HAttrs.href "#" ] [ viewIcon ]
        |> Navbar.customItems
            [ Navbar.formItem [] [ viewSettingsButton model ] ]
        |> Navbar.items
            [ Navbar.itemLink
                [ HAttrs.style "padding-bottom" "0"
                , HAttrs.style "padding-top" "0"
                ]
                [ Button.button [ Button.primary, Button.onClick <| SendRun ] [ text "Run" ] ]
            , Navbar.dropdown
                { id = "exampleDropdown"
                , toggle = Navbar.dropdownToggle [] [ text "Examples" ]
                , items =
                    [ Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.lltree3 ]
                        [ text "Map a function to the leaves of a leaf-linked tree." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist ]
                        [ text "Pop the last element of a difference list (length 1)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist2 ]
                        [ text "Append two difference lists." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist3 ]
                        [ text "Rotate a difference list (push an element to front from back)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist4 ]
                        [ text "Pop the last element of a difference list (length 2)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.letrec1 ]
                        [ text "Pop all the elements from back of a difference list." ]
                    ]
                }
            , Navbar.itemLink
                [ HAttrs.href "https://github.com/sano-jin/lambda-gt-alpha" ]
                [ text "About" ]
            ]
        |> Navbar.view model.navbarState


view : Model -> Html Msg
view model =
    let
        divMessages =
            ListGroup.ul <| List.map (\msg -> ListGroup.li [] [ text msg ]) model.messages

        height100 =
            HAttrs.style "height" "100%"

        viewDetails =
            Tab.config TabMsg
                |> Tab.withAnimation
                -- remember to wire up subscriptions when using this option
                -- |> Tab.right
                |> Tab.items
                    [ Tab.item
                        { id = "tabItem1"
                        , link = Tab.link [] [ text "Visualiser Settings" ]
                        , pane =
                            Tab.pane []
                                [ Card.config [ Card.outlineLight ]
                                    |> Card.block []
                                        [ -- Block.titleH4 [] [ text "Block title" ]
                                          Block.text []
                                            [ text "Some block content" ]
                                        , Block.link [ HAttrs.href "#" ] [ text "MyLink" ]
                                        ]
                                    |> Card.view
                                , Html.map VisGraphMsg <| VisGraph.viewSettings model.visGraph
                                ]
                        }
                    , Tab.item
                        { id = "tabItem2"
                        , link = Tab.link [] [ text "Log" ]
                        , pane =
                            Tab.pane
                                [ height100
                                , HAttrs.style "height" "90vh"
                                , HAttrs.style "overflow-y" "scroll"
                                ]
                                [ Card.config [ Card.outlineLight ]
                                    |> Card.block []
                                        [ -- Block.titleH4 [] [ text "Block title" ]
                                          Block.text [] [ text "Some block content" ]
                                        , Block.link [ HAttrs.href "#" ] [ text "MyLink" ]
                                        ]
                                    |> Card.view
                                , divMessages
                                ]
                        }
                    ]
                |> Tab.view model.tabState

        paneMain =
            [ viewNavbar model
            , Grid.containerFluid [ HAttrs.style "flex-grow" "1", height100 ]
                [ Grid.row [ Row.attrs [ height100 ] ]
                    [ Grid.col [ Col.xs6, Col.attrs [ height100, HAttrs.style "padding" "0" ] ]
                        [ if model.showVisSettings then
                            viewDetails

                          else
                            Html.map EditorMsg <| Editor.view model.editor
                        ]
                    , Grid.col
                        [ Col.xs6
                        , Col.attrs [ HAttrs.style "padding" "0", HAttrs.style "flex-grow" "1" ]
                        ]
                        [ Html.map VisGraphMsg <| VisGraph.viewGraph model.visGraph ]
                    ]
                ]
            ]
    in
    div []
        [ CDN.stylesheet
        , div
            [ style "display" "flex"
            , HAttrs.style "display" "flex"
            , HAttrs.style "flex-flow" "column"
            , HAttrs.style "height" "100vh"
            ]
            paneMain
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map VisGraphMsg <| VisGraph.subscriptions model.visGraph
        , messageReceiver <| RecvRun << Decode.decodeString decodeMessage
        , Tab.subscriptions model.tabState TabMsg
        , Sub.map EditorMsg <| Editor.subscriptions model.editor
        , Navbar.subscriptions model.navbarState NavbarMsg
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
