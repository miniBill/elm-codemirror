module Main exposing (main)

import Array exposing (Array)
import Browser
import Html exposing (Html, div, node)
import Html.Attributes exposing (id, style)
import Html.Events
import Json.Decode
import Json.Encode
import Markdown.Block as Block exposing (Block)
import Markdown.Parser
import Markdown.Renderer
import Parser.Advanced.Extra
import Regex exposing (Regex)
import String.Extra


type alias Model =
    { doc : String
    , changes : Array Json.Encode.Value
    }


type Msg
    = Changes Json.Encode.Value String


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


init : Model
init =
    { doc = ""
    , changes = Array.empty
    }


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "align-items" "fill"
        , style "padding" "8px"
        , style "gap" "8px"
        ]
        [ node "code-mirror"
            [ Html.Attributes.property "changes" (Json.Encode.array identity model.changes)
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
update msg model =
    case msg of
        Changes changes doc ->
            { model
                | changes = Array.push changes model.changes
                , doc = doc
            }
