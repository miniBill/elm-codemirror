module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Docs.ReviewAtDocs
import NoAlways
import NoBrokenParserFunctions
import NoCatchAllForSpecificRemainingPatterns
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoInconsistentAliases
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoPrematureLetComputation
import NoSimpleLetBody
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import ReviewPipelineStyles
import ReviewPipelineStyles.Fixes
import Simplify
import Validate.Regexes


config : List Rule
config =
    [ Docs.ReviewAtDocs.rule
    , NoAlways.rule
    , NoBrokenParserFunctions.rule
    , NoCatchAllForSpecificRemainingPatterns.rule
    , NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoInconsistentAliases.config
        [ ( "Nix.Syntax.Node", "Node" )
        , ( "Parser.Advanced", "Parser" )
        ]
        |> NoInconsistentAliases.noMissingAliases
        |> NoInconsistentAliases.rule
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule
    , NoModuleOnExposedNames.rule
    , NoPrematureLetComputation.rule
    , NoSimpleLetBody.rule
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , ReviewPipelineStyles.rule pipelineConfig |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , Simplify.rule Simplify.defaults
    , Validate.Regexes.rule
    ]


pipelineConfig : List (ReviewPipelineStyles.PipelineRule ())
pipelineConfig =
    [ ReviewPipelineStyles.forbid ReviewPipelineStyles.leftPizzaPipelines
        |> ReviewPipelineStyles.andTryToFixThemBy ReviewPipelineStyles.Fixes.convertingToParentheticalApplication
        |> ReviewPipelineStyles.andCallThem "forbidden <| pipeline"
    , ReviewPipelineStyles.forbid ReviewPipelineStyles.leftCompositionPipelines
        |> ReviewPipelineStyles.andCallThem "forbidden << composition"
    , ReviewPipelineStyles.forbid ReviewPipelineStyles.rightCompositionPipelines
        |> ReviewPipelineStyles.andCallThem "forbidden >> composition"
    ]
