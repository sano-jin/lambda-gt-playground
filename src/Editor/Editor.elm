module Editor.Editor exposing (..)

{-| This example demonstrates a force directed graph with zoom and drag
functionality.

@delay 5
@category Advanced

-}

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Textarea as Textarea
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
import Task



-- Constants


initialContent : String
initialContent =
    ""



-- Types


type Msg
    = TextareaMsg String


type alias Model =
    { code : String
    , messages : List String
    }



-- Initialize


init : () -> ( Model, Cmd Msg )
init _ =
    ( { code = initialContent
      , messages = []
      }
    , Cmd.none
    )



-- Update


updateCode : String -> Model -> Model
updateCode code model =
    { model | code = code, messages = "edited" :: model.messages }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextareaMsg code ->
            ( updateCode code model, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    Textarea.textarea
        [ Textarea.id "myarea"
        , Textarea.attrs
            [ HAttrs.class "codeEditor"

            -- , HAttrs.style "background" "#292930"
            -- , HAttrs.style "color" "#cce"
            -- , HAttrs.style "background" "#f0f9ff"
            , HAttrs.style "color" "#689"
            , HAttrs.style "border" "none"
            , HAttrs.style "outline" "none"
            , HAttrs.style "padding" "20px"
            , HAttrs.style "height" "100%"

            -- , HAttrs.style "height" "calc(100% - 40px)"
            -- , HAttrs.style "padding-left" "20px"
            -- , HAttrs.style "padding-right" "20px"
            -- , HAttrs.style "margin-top" "20px"
            -- , HAttrs.style "margin-bottom" "20px"
            , HAttrs.style "resize" "none"
            ]
        , Textarea.rows 30

        -- , Textarea.attrs [ HAttrs.style "font-family" "monospace" ]
        , Textarea.value model.code
        , Textarea.onInput TextareaMsg
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
