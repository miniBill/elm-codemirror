module Main exposing (Flags, Model, Msg, main)

import Array exposing (Array)
import Browser
import Browser.Dom
import Html exposing (Attribute, Html, button, div, node, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import Markdown.Block as Block exposing (Block)
import Markdown.Parser
import Markdown.Renderer
import Parser.Advanced.Extra
import Regex exposing (Regex)
import String.Extra
import Task


type alias Model =
    { doc : String
    , changes : Array Json.Encode.Value
    , vimMode : Bool
    }


type Msg
    = Changes Json.Encode.Value String
    | VimMode Bool
    | Noop


type alias Flags =
    {}


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : flags -> ( Model, Cmd msg )
init _ =
    let
        model : Model
        model =
            { doc = ""
            , changes = Array.empty
            , vimMode = False
            }
    in
    ( model, Cmd.none )


row : List (Attribute msg) -> List (Html msg) -> Html msg
row attrs children =
    div
        (style "display" "flex"
            :: style "gap" "8px"
            :: attrs
        )
        children


column : List (Attribute msg) -> List (Html msg) -> Html msg
column attrs children =
    row (style "flex-direction" "column" :: attrs) children


ids : { editor : String }
ids =
    { editor = "editor" }


view : Model -> Html Msg
view model =
    column
        [ style "align-items" "fill"
        , style "padding" "8px"
        ]
        [ row []
            [ button [ onClick (VimMode True) ] [ node "tt" [] [ text "vim" ], text " mode" ]
            , button [ onClick (VimMode False) ] [ text "Heretical mode" ]
            ]
        , row [ style "align-items" "fill" ]
            [ node "code-mirror"
                [ id ids.editor
                , Html.Attributes.property "changes" (Json.Encode.array identity model.changes)
                , Html.Attributes.property "vimMode" (Json.Encode.bool model.vimMode)
                , Html.Events.on "doc-changed"
                    (Json.Decode.at [ "detail" ]
                        (Json.Decode.map2 Changes
                            (Json.Decode.field "changes" Json.Decode.value)
                            (Json.Decode.field "doc" Json.Decode.string)
                        )
                    )
                , style "flex" "1"
                ]
                []
            , let
                source : String
                source =
                    toMarkdown model.doc

                blocks : List Block
                blocks =
                    case Markdown.Parser.parse source of
                        Ok parsed ->
                            parsed

                        Err e ->
                            [ Block.Paragraph
                                (Block.Text "Invalid parse "
                                    :: Parser.Advanced.Extra.errorToMarkdown source e
                                )
                            ]
              in
              case Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer blocks of
                Ok children ->
                    div
                        [ id "markdown"
                        , style "flex" "1"
                        ]
                        children

                Err e ->
                    div [ id "markdown", style "flex" "1" ]
                        [ text ("Error in rendering : " ++ e)
                        ]
            ]
        ]


linkRegex : Regex
linkRegex =
    Regex.fromString "\\[\\[[^\\]]+\\]\\]"
        |> Maybe.withDefault Regex.never


toMarkdown : String -> String
toMarkdown input =
    input
        |> Regex.replace linkRegex
            (\match ->
                let
                    target : String
                    target =
                        String.slice 2 -2 match.match
                in
                "[" ++ target ++ "](/" ++ String.Extra.dasherize target ++ ")"
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Changes changes doc ->
            ( { model
                | changes = Array.push changes model.changes
                , doc = doc
              }
            , Cmd.none
            )

        VimMode mode ->
            ( { model | vimMode = mode }
              -- , Browser.Dom.focus ids.editor
              -- |> Task.attempt (\_ -> Noop)
            , Cmd.none
            )

        Noop ->
            ( model, Cmd.none )


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none
