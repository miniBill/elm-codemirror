module Main exposing (main)

import Browser
import Html exposing (Html, div, node)
import Html.Attributes exposing (id, style)
import Html.Events
import Json.Decode
import Markdown.Block exposing (Block)
import Markdown.Parser
import Markdown.Renderer
import Regex exposing (Regex)
import String.Extra


type alias Model =
    String


type alias Msg =
    String


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


init : Model
init =
    ""


view : Model -> Html Msg
view doc =
    div
        [ style "display" "flex"
        , style "align-items" "fill"
        , style "padding" "8px"
        , style "gap" "8px"
        ]
        [ node "code-mirror"
            [ Html.Attributes.attribute "doc-source" doc
            , Html.Events.on "doc-changed"
                (Json.Decode.at [ "detail" ] Json.Decode.string)
            , style "flex" "1"
            ]
            []
        , let
            blocks : List Block
            blocks =
                case Markdown.Parser.parse (toMarkdown doc) of
                    Ok parsed ->
                        parsed

                    Err e ->
                        [ Markdown.Block.Paragraph
                            [ Markdown.Block.Text ("Invalid parse " ++ Debug.toString e)
                            ]
                        ]
          in
          Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer blocks
            |> Result.withDefault []
            |> div
                [ id "markdown"
                , style "flex" "1"
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


update : Msg -> Model -> Model
update msg _ =
    msg
