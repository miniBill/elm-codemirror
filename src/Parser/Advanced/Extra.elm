module Parser.Advanced.Extra exposing (Config, errorToHtml, errorToMarkdown, errorToString, renderError)

import Ansi.Color
import Html exposing (Html)
import Html.Attributes
import Json.Encode
import List.Extra
import Markdown.Block as Block exposing (Inline)
import Parser exposing (Problem(..))
import Parser.Advanced exposing (DeadEnd)


type alias Config a =
    { text : String -> a
    , colorCaret : a -> a
    , newline : a
    , colorContext : a -> a
    }


type Line a
    = Line (List a)


errorToString : String -> List (DeadEnd String Problem) -> String
errorToString src deadEnds =
    renderError
        { text = identity
        , colorContext = Ansi.Color.fontColor Ansi.Color.cyan
        , colorCaret = Ansi.Color.fontColor Ansi.Color.red
        , newline = "\n"
        }
        src
        deadEnds
        |> String.concat


errorToHtml : String -> List (DeadEnd String Problem) -> List (Html msg)
errorToHtml src deadEnds =
    let
        color : String -> Html msg -> Html msg
        color value child =
            Html.span [ Html.Attributes.style "color" value ] [ child ]
    in
    renderError
        { text = Html.text
        , colorContext = color "cyan"
        , colorCaret = color "red"
        , newline = Html.br [] []
        }
        src
        deadEnds


errorToMarkdown : String -> List (DeadEnd String Problem) -> List Inline
errorToMarkdown src deadEnds =
    let
        color : String -> Inline -> Inline
        color value child =
            Block.HtmlInline
                (Block.HtmlElement "span"
                    [ { name = "style", value = "color:" ++ value } ]
                    [ Block.Paragraph [ child ] ]
                )
    in
    renderError
        { text = Block.Text
        , colorContext = color "cyan"
        , colorCaret = color "red"
        , newline = Block.HardLineBreak
        }
        src
        deadEnds


renderError : Config a -> String -> List (DeadEnd String Problem) -> List a
renderError cfg src deadEnds =
    let
        lines : List ( Int, String )
        lines =
            src
                |> String.split "\n"
                |> List.indexedMap (\i l -> ( i + 1, l ))
    in
    deadEnds
        |> List.Extra.gatherEqualsBy
            (\{ row, col } -> ( row, col ))
        |> List.concatMap (\line -> deadEndToString cfg lines line)
        |> List.intersperse (Line [ cfg.newline ])
        |> List.concatMap (\(Line l) -> l)


deadEndToString : Config a -> List ( Int, String ) -> ( DeadEnd String Problem, List (DeadEnd String Problem) ) -> List (Line a)
deadEndToString cfg lines ( head, tail ) =
    let
        grouped :
            List
                ( List { row : Int, col : Int, context : String }
                , List Problem
                )
        grouped =
            (head :: tail)
                |> List.Extra.gatherEqualsBy .contextStack
                |> List.map
                    (\( ihead, itail ) ->
                        ( ihead.contextStack
                        , List.map .problem (ihead :: itail)
                        )
                    )

        sourceFragment : List (Line a)
        sourceFragment =
            formatSourceFragment cfg head lines

        groupToString :
            ( List { row : Int, col : Int, context : String }
            , List Problem
            )
            -> List (Line a)
        groupToString ( contextStack, problems ) =
            let
                expected : List String
                expected =
                    List.filterMap toExpected problems

                other : List String
                other =
                    problems
                        |> List.filterMap
                            (\problem ->
                                case toExpected problem of
                                    Just _ ->
                                        Nothing

                                    Nothing ->
                                        Just (problemToString problem)
                            )

                groupedExpected : List String
                groupedExpected =
                    case expected of
                        [] ->
                            []

                        [ x ] ->
                            [ "expecting " ++ x ]

                        _ :: _ :: _ ->
                            [ "expecting one of "
                                ++ String.join ", " expected
                            ]

                problemsLines : List (Line a)
                problemsLines =
                    (groupedExpected ++ other)
                        |> List.sort
                        |> List.map (\l -> Line [ cfg.text ("  " ++ l) ])
            in
            Line
                [ cfg.text "- "
                , cfg.colorContext (cfg.text (contextStackToString contextStack))
                , cfg.text ":"
                ]
                :: problemsLines
    in
    sourceFragment ++ Line [ cfg.text "" ] :: List.concatMap groupToString grouped


toExpected : Problem -> Maybe String
toExpected problem =
    case problem of
        Expecting x ->
            Just x

        ExpectingVariable ->
            Just "a variable"

        ExpectingEnd ->
            Just "the end"

        ExpectingInt ->
            Just "an integer"

        ExpectingHex ->
            Just "an hexadecimal number"

        ExpectingOctal ->
            Just "an octal number"

        ExpectingBinary ->
            Just "a binary number"

        ExpectingFloat ->
            Just "a floating point number"

        ExpectingNumber ->
            Just "a number"

        ExpectingSymbol s ->
            Just (Json.Encode.encode 0 (Json.Encode.string s))

        ExpectingKeyword k ->
            Just (Json.Encode.encode 0 (Json.Encode.string k))

        UnexpectedChar ->
            Nothing

        Problem _ ->
            Nothing

        BadRepeat ->
            Nothing


formatSourceFragment : Config a -> DeadEnd String Problem -> List ( Int, String ) -> List (Line a)
formatSourceFragment cfg head lines =
    let
        line : ( Int, String )
        line =
            lines
                |> List.drop (head.row - 1)
                |> List.head
                |> Maybe.withDefault ( head.row, "" )

        before : List ( Int, String )
        before =
            lines
                |> List.drop (head.row - 3)
                |> List.take 3
                |> List.Extra.takeWhile (\( i, _ ) -> i < head.row)

        after : List ( Int, String )
        after =
            lines
                |> List.drop head.row
                |> List.take 3

        formatLine : ( Int, String ) -> Line a
        formatLine ( row, l ) =
            Line
                [ cfg.text
                    (String.padLeft numLength ' ' (String.fromInt row)
                        ++ "| "
                        ++ l
                    )
                ]

        numLength : Int
        numLength =
            after
                |> List.Extra.last
                |> Maybe.map (\( r, _ ) -> r)
                |> Maybe.withDefault head.row
                |> String.fromInt
                |> String.length

        caret : Line a
        caret =
            Line
                [ cfg.text (String.repeat (numLength + head.col + 1) " ")
                , cfg.colorCaret (cfg.text "^")
                ]
    in
    List.map formatLine before
        ++ formatLine line
        :: caret
        :: List.map formatLine after


contextStackToString : List { row : Int, col : Int, context : String } -> String
contextStackToString frames =
    frames
        |> List.reverse
        |> List.map
            (\{ row, col, context } ->
                context
                    ++ " ("
                    ++ String.fromInt row
                    ++ ":"
                    ++ String.fromInt col
                    ++ ")"
            )
        |> String.join " > "


problemToString : Problem -> String
problemToString problem =
    case problem of
        Expecting x ->
            "Expecting " ++ x

        ExpectingVariable ->
            "Expecting a variable"

        ExpectingEnd ->
            "Expecting the end"

        ExpectingInt ->
            "Expecting an integer"

        ExpectingHex ->
            "Expecting an hexadecimal number"

        ExpectingOctal ->
            "Expecting an octal number"

        ExpectingBinary ->
            "Expecting a binary number"

        ExpectingFloat ->
            "Expecting a floating point number"

        ExpectingNumber ->
            "Expecting a number"

        ExpectingSymbol s ->
            "Expecting " ++ Json.Encode.encode 0 (Json.Encode.string s)

        ExpectingKeyword k ->
            "Expecting " ++ Json.Encode.encode 0 (Json.Encode.string k)

        UnexpectedChar ->
            "Unexpected char"

        Problem p ->
            p

        BadRepeat ->
            "Bad repetition"
