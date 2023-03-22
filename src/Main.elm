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
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Tab as Tab
import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict
import Editor.Editor as Editor
import Examples
import Html exposing (Html, div, text)
import Html.Attributes as HAttrs exposing (style)
import Html.Events as HEvents
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DX
import Json.Decode.Pipeline as DP
import PortGraph.PortGraph as PortGraph exposing (Functor, PortId)
import PortGraph.PortGraphExample as PortGraphExample
import PortGraph.ViewSettings as ViewSettings
import PortGraph.VisGraph as VisGraph
import Task



-- Constants


initialGraph : PortGraph.Graph Int
initialGraph =
    PortGraphExample.emptyGraph



-- PORTS


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg


port sendMessageProceed : String -> Cmd msg


port messageProceedReceiver : (String -> msg) -> Sub msg



-- Types


type Msg
    = VisGraphMsg VisGraph.Msg
    | SendRun
    | RecvRun (Result Decode.Error Message)
    | SendProceed
    | RecvProceed (Result Decode.Error Message)
    | TabMsg Tab.State
    | EditorMsg Editor.Msg
    | NavbarMsg Navbar.State
    | ShowVisSettingsMsg Bool
    | LoadCode String
    | ViewSettingsMsg ViewSettings.Msg
    | CloseAboutModal
    | ShowAboutModal


type alias Model =
    { visGraph : VisGraph.Model
    , messages : List String
    , tabState : Tab.State
    , editor : Editor.Model
    , navbarState : Navbar.State
    , showVisSettings : Bool
    , viewSettings : ViewSettings.Model {}
    , hasNext : Bool
    , graphTerm : String
    , aboutModal : Modal.Visibility
    }



-- Initialize


init : () -> ( Model, Cmd Msg )
init _ =
    let
        graph =
            PortGraph.initPortAngles PortGraph.initialPortAngles initialGraph

        ( visGraphModel, visGraphCmd ) =
            VisGraph.init <| VisGraph.initialiseGraph graph

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
      , viewSettings = ViewSettings.initializeModel graph
      , hasNext = False
      , graphTerm = ""
      , aboutModal = Modal.hidden
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
        ViewSettingsMsg viewSettingsMsg ->
            let
                ( viewSettingsModel, config ) =
                    ViewSettings.update viewSettingsMsg model.viewSettings
            in
            ( { model
                | viewSettings = viewSettingsModel
                , visGraph = VisGraph.configGraph config model.visGraph
              }
            , Cmd.none
            )

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
            ( { model | messages = "Send" :: model.messages }
            , sendMessage <| model.editor.code
            )

        RecvRun (Err err) ->
            ( { model | messages = Decode.errorToString err :: model.messages }
            , Cmd.none
            )

        RecvRun (Ok { graph, isEnded, info }) ->
            ( { model
                | messages = info :: PortGraph.toString String.fromInt graph :: model.messages
                , visGraph =
                    VisGraph.updateGraph { settings = model.viewSettings.settings, reheat = True }
                        (PortGraph.initPortAngles PortGraph.initialPortAngles graph)
                        model.visGraph
                , hasNext = not isEnded
                , graphTerm = info
              }
            , Cmd.none
            )

        SendProceed ->
            if model.hasNext then
                ( { model | messages = "Send" :: model.messages }
                , sendMessageProceed "Proceed"
                )

            else
                ( model, Cmd.none )

        RecvProceed (Err err) ->
            ( { model | messages = List.take 20 <| Decode.errorToString err :: model.messages }
            , Cmd.none
            )

        RecvProceed (Ok { graph, isEnded, info }) ->
            ( { model
                | messages = info :: PortGraph.toString String.fromInt graph :: model.messages
                , visGraph =
                    VisGraph.updateGraph { settings = model.viewSettings.settings, reheat = True }
                        (PortGraph.initPortAngles PortGraph.initialPortAngles graph)
                        model.visGraph
                , hasNext = not isEnded
                , graphTerm = info
              }
            , Cmd.none
            )

        TabMsg state ->
            ( { model | tabState = state }
            , Cmd.none
            )

        CloseAboutModal ->
            ( { model | aboutModal = Modal.hidden }
            , Cmd.none
            )

        ShowAboutModal ->
            ( { model | aboutModal = Modal.shown }
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


viewAboutModel : Model -> Html Msg
viewAboutModel model =
    Modal.config CloseAboutModal
        |> Modal.large
        |> Modal.h5 [] [ text "A Playground of the ", viewIcon, text " Language" ]
        |> Modal.scrollableBody True
        |> Modal.body []
            [ Html.p []
                [ text """
                This is a playground of the λGT language.
                """
                ]
            , Html.h6 [] [ text "About the language" ]
            , Html.p []
                [ text """
                λGT is a new purely functional language
                that handles graphs as immutable, first-class data structures 
                with pattern matching.
                """
                ]
            , Html.p []
                [ text """
                A graph is a generalized concept that encompasses more complex data structures than trees, 
                such as difference lists, doubly-linked lists, skip lists, and leaf-linked trees. 
                """
                ]
            , Html.p []
                [ text """
                Normally, these structures are handled with destructive assignments to heaps, 
                as opposed to a purely functional programming style.
                These low-level operations are tedious and error prone 
                and their verifications are not straightforward.
                """
                ]
            , Html.p []
                [ text """
                To overcome the situation, we are developping a new functional language, λGT.
                The key features of λGT are follows:
                """
                ]
            , Html.ul []
                [ Html.li []
                    [ text "Hypergraphs as first-class data." ]
                , Html.li []
                    [ text "Patterns matchings on hypergraphs." ]
                , Html.li []
                    [ text "Pure." ]
                , Html.li []
                    [ text "First-class functions." ]
                , Html.li []
                    [ text "Type system." ]
                ]
            , Html.h6 [] [ text "Syntax of the language" ]
            , Html.p []
                [ text """
                The concrete syntax of the language is follows:
                """
                , Html.img
                    [ HAttrs.style "max-width" "100%"
                    , HAttrs.src "syntax.png"
                    , HAttrs.alt "The syntax of the λGT language."
                    ]
                    []
                ]
            , Html.p []
                [ text """
                We have also enabled logging (breakpoints). 
                `{Log}` exp evaluates exp, prints the value, and returns the value; 
                i.e., an identity function.
                The visualiser displays the value on the right pane
                and stops at the breakpoint.
                """
                ]
            , Html.p []
                [ text """
                For the semantics, readers are referred to 
                """
                , Html.a [ HAttrs.href "https://doi.org/10.2197/ipsjjip.31.112" ]
                    [ text """
                      J.Sano et al, 
                      Type Checking Data Structures More Complex than Trees,
                      Journal of Information Processing, 2023.
                      """
                    ]
                ]
            , Html.h6 [] [ text "How to use the playground" ]
            , Html.p []
                [ text """
                Fill in the code of λGT in the left pane.
                Then press `Run` button.
                The backend interpreter runs the code and stops 
                at the point it cannot evaluate eny more or
                at the breakpoints (`{Log}`).
                The right pane of the visualiser displays the graph 
                returned by the interpreter.
                To proceed, run `Proceed` button.
                """
                ]
            , Html.h6 [] [ text "Source code and more description" ]
            , Html.p []
                [ text """
                The source code and the description of the PoC interpreter and this playground 
                are available on GitHub from:
                """
                ]
            , Html.ul []
                [ Html.li []
                    [ Html.a [ HAttrs.href "https://github.com/sano-jin/lambda-gt-alpha" ]
                        [ text "https://github.com/sano-jin/lambda-gt-alpha" ]
                    ]
                , Html.li []
                    [ Html.a [ HAttrs.href "https://github.com/sano-jin/lambda-gt-playground" ]
                        [ text "https://github.com/sano-jin/lambda-gt-playground" ]
                    ]
                ]
            , Html.p []
                [ text """
                respectively.
                """
                ]
            ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ HEvents.onClick CloseAboutModal ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view model.aboutModal


viewNavbar : Model -> Html Msg
viewNavbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.dark
        |> Navbar.brand [ HAttrs.href "#" ] [ viewIcon ]
        |> Navbar.customItems
            [ Navbar.formItem [] [ viewSettingsButton model ] ]
        |> Navbar.items
            [ Navbar.itemLink
                [ HAttrs.style "padding-bottom" "0"
                , HAttrs.style "padding-top" "0"
                ]
                [ Button.button [ Button.primary, Button.onClick <| SendRun ] [ text "Run" ] ]
            , Navbar.itemLink
                [ HAttrs.style "padding-bottom" "0"
                , HAttrs.style "padding-top" "0"
                ]
                [ Button.button
                    [ Button.info
                    , Button.disabled <| not model.hasNext
                    , Button.onClick <| SendProceed
                    ]
                    [ text "Proceed" ]
                ]
            , Navbar.dropdown
                { id = "exampleDropdown"
                , toggle = Navbar.dropdownToggle [] [ text "Examples" ]
                , items =
                    [ Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.lltree3 ]
                        [ text "Map a function to the leaves of a leaf-linked tree (2 leaves)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.lltree5 ]
                        [ text "Map a function to the leaves of a leaf-linked tree (4 leaves)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist ]
                        [ text "Pop the last element of a difference list (length 1)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist2 ]
                        [ text "Append two difference lists." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist3 ]
                        [ text "Rotate a difference list (push an element to front from back, length 2)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist3b ]
                        [ text "Rotate a difference list (push an element to front from back, length 1)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dlist4 ]
                        [ text "Pop the last element of a difference list (length 2)." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.letrec1 ]
                        [ text "Pop all the elements from back of a difference list." ]
                    , Navbar.dropdownItem [ HEvents.onClick <| LoadCode Examples.dataflow2 ]
                        [ text "Embedding a dataflow language." ]
                    ]
                }
            , Navbar.itemLink
                [ HAttrs.style "padding-bottom" "0"
                , HAttrs.style "padding-top" "0"
                ]
                [ Button.button
                    [ Button.secondary, Button.attrs [ HEvents.onClick ShowAboutModal ] ]
                    [ text "About" ]
                ]
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

                                        -- , Block.link [ HAttrs.href "#" ] [ text "MyLink" ]
                                        ]
                                    |> Card.view

                                -- , Html.map VisGraphMsg <| VisGraph.viewSettings model.visGraph
                                , Html.map ViewSettingsMsg <| ViewSettings.view model.viewSettings
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
                        , Col.attrs
                            [ HAttrs.style "padding" "0"
                            , HAttrs.style "position" "relative"
                            , HAttrs.style "flex-grow" "1"
                            ]
                        ]
                        [ Html.map VisGraphMsg <| VisGraph.view model.visGraph
                        , div
                            [ style "position" "fixed"
                            , style "bottom" "50px"
                            , style "right" "20px"
                            , style "width" "45vw"
                            , style "color" "#689"
                            , HAttrs.class "my-toast"
                            ]
                            [ text <| model.graphTerm ]
                        ]
                    ]
                , viewAboutModel model
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
        , messageProceedReceiver <| RecvProceed << Decode.decodeString decodeMessage
        , Tab.subscriptions model.tabState TabMsg
        , Sub.map EditorMsg <| Editor.subscriptions model.editor
        , Navbar.subscriptions model.navbarState NavbarMsg
        , Sub.map ViewSettingsMsg <| ViewSettings.subscriptions model.viewSettings
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
