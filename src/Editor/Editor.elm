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
import PortGraph.PortGraph as PortGraph exposing (Functor, PortId)
import PortGraph.PortGraphExample as PortGraphExample
import PortGraph.VisGraph as VisGraph
import Task



-- Constants


initialContent : String
initialContent =
    """% lltree3.lgt
% Map a function to the leaves of a leaf-linked tree.

let succ[_X] x[_X] = {x[_X]} + {1(_X)} in

let map[_X] f[_X] x[_L, _R, _X] = 
  let rec helper[_X] x2[_L, _R, _X] =
    case {Log} {x2[_L, _R, _X]} of 
      {nu _L2 _R2 _X2 _X3. (
        y [_L, _R, _X, _L2, _R2, _X2], 
        Leaf (_X3, _L2, _R2, _X2), 
        z [_X3],
        M (_L2)
      )} -> 
        let z2[_X] = {f[_X]} {z[_X]} in
        {helper[_X]}
        {nu _L2 _R2 _X2 _X3 _X4. (
          y [_L, _R, _X, _L2, _R2, _X2], 
          Leaf (_X3, _L2, _R2, _X2), 
          z2 [_X3],
          M (_R2)
        )}
    | otherwise -> case {x2[_L, _R, _X]} of
      { y[_L, _R, _X], M (_R) } -> { y[_L, _R, _X] }
    | otherwise -> {Error, x2[_L, _R, _X]}
  in {helper [_X]} {x[_L, _R, _X], M (_L)}
in

{map[_X]} 
{succ[_X]}
{nu _X1 _X2 _X3 _X4 _X5. (
  Node (_X1, _X2, _X), 
  Leaf (_X4 ,_L, _X3, _X1),
  1 (_X4),
  Leaf (_X5, _X3, _R, _X2),
  2 (_X5)
)}

    

% --->
% > {nu _L0 _L1 _L2 _L3 _L4. (M (_L), Node (_L0, _L1, _X), Leaf (_L2, _L, _L3, _L0), Zero (_L2), Leaf (_L4, _L3, _R, _L1), Zero (_L4))}
% > {nu _L0 _L1 _L2 _L3 _L4 _L5. (Leaf (_L0, _L, _L1, _L2), M (_L1), Zero (_L3), Node (_L2, _L4, _X), Leaf (_L3, _L1, _R, _L4), Succ (_L5, _L0), Zero (_L5))}
% > {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6. (Leaf (_L0, _L1, _R, _L2), M (_R), Zero (_L3), Succ (_L3, _L4), Leaf (_L4, _L, _L1, _L5), Node (_L5, _L2, _X), Succ (_L6, _L0), Zero (_L6))}
% {nu _L0 _L1 _L2 _L3 _L4 _L5 _L6. (Zero (_L0), Zero (_L1), Succ (_L0, _L2), Succ (_L1, _L3), Leaf (_L3, _L4, _R, _L5), Leaf (_L2, _L, _L4, _L6), Node (_L6, _L5, _X))}"""



-- Types


type Msg
    = TextareaMsg String


type alias Model =
    { code : String
    , messages : List String
    }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextareaMsg code ->
            ( { model | code = code, messages = "edited" :: model.messages }, Cmd.none )



-- Initialize


init : () -> ( Model, Cmd Msg )
init _ =
    ( { code = initialContent
      , messages = []
      }
    , Cmd.none
    )



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
