module Example exposing (main)

import Html
import Html.Attributes as Attrs
import Html.Events as Events

import Json.Decode as Json

import Bot


{-| PROGRAM
-}
main : Program Never Model Msg
main =
  Html.program
    { init = { history = [], draft = "", bot = Bot.bot "my-bot" } ! [ Cmd.none ]
    , view = view
    , update = update
    , subscriptions = (\model -> Bot.listen Listen model.bot)
    }


-- MODEL

type From = User | Remote

type alias Model =
  { history : List (From, String)
  , draft : String
  , bot : Bot.Bot
  }


type Msg
  = Listen ( String, Bot.Bot )
  | Input String
  | Submit
  | Enter Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Listen ( reply, bot ) ->
      -- Update bot
      { model | history = (Remote, reply) :: model.history, bot = bot } ! [ Cmd.none ]
    Input input ->
      { model | draft = input } ! [ Cmd.none ]
    Submit ->
      let
        ( bot, cmd ) = Bot.reply model.draft model.bot
      in
        { model | history = (User, model.draft) :: model.history, draft = "", bot = bot } ! [ cmd ]
    Enter key ->
      case key of
        13 ->
          update Submit model
        _ ->
          model ! [ Cmd.none ]


-- VIEW

view : Model -> Html.Html Msg
view model =
  Html.div [ Attrs.class "app px-2 pt-1" ]
    [ Html.div [ Attrs.class "controls fixed-bottom m-auto pb-1" ] <| controls model
    , Html.div [ Attrs.class "history d-flex flex-column" ] <| historyView model.history [ ]
    ]


controls : Model -> List (Html.Html Msg)
controls model =
  [ Html.div [ Attrs.class "input-group" ]
    [ Html.div [ Attrs.class "input-group-prepend" ]
      [ Html.span [ Attrs.class "input-group-text" ]
        [ Html.i [ Attrs.class "fas fa-user-circle" ] [ ]
        ]
      ]
    , Html.input [ Events.onInput Input, onKeyDown Enter, Attrs.type_ "text", Attrs.class "form-control", Attrs.value model.draft, Attrs.placeholder "..." ] [ ]
    , Html.div [ Attrs.class "input-group-append" ]
      [ Html.button [ Events.onClick Submit, Attrs.class "btn btn-primary" ]
        [ Html.i [ Attrs.class "fas fa-comments" ] [ ]
        , Html.text " Share"
        ]
      ]
    ]
  ]


historyView : List (From, String) -> List (Html.Html Msg) -> List (Html.Html Msg)
historyView history view =
  case List.head history of
    Nothing -> view
    Just msg -> historyView
      (Maybe.withDefault [ ] <| List.tail history)
      (messageView msg :: view)


messageView : (From, String) -> Html.Html Msg
messageView (from, s) =
  let
    (div_cls, p_cls) = case from of
      User ->
        ("media align-self-start", "alert alert-primary")
      Remote ->
        ("media align-self-end", "alert alert-secondary")
  in
    Html.div [ Attrs.class div_cls ]
    [ Html.div [ Attrs.class "media-body" ]
      [
        Html.p [ Attrs.class p_cls ] [ Html.text s ]
      ]
    ]


-- Helper functions

onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
  Events.on "keydown" (Json.map tagger Events.keyCode)
