module Main (..) where

import StartApp
import Html exposing (..)
import Html.Attributes exposing (href, class, style)
import Signal exposing (Signal)
import Effects exposing (..)
import Task
import Signal
import Task exposing (Task)
import Array exposing (Array)
import Routing
import Hop
import Hop.Navigate exposing (navigateTo)
import Material.Color as Color
import Material.Layout
import Material.Layout as Layout exposing (defaultLayoutModel)
import Material exposing (lift, lift')
import Material.Style as Style
import Demo.Buttons
import Demo.Grid
import Demo.Textfields
import Demo.Snackbar
import Demo.Badges


--import Demo.Template
-- MODEL


layoutModel : Layout.Model
layoutModel =
  { defaultLayoutModel
    | state = Layout.initState (List.length tabs)
  }


type alias Model =
  { layout : Layout.Model
  , routing : Routing.Model
  , buttons : Demo.Buttons.Model
  , textfields : Demo.Textfields.Model
  , snackbar :
      Demo.Snackbar.Model
      --, template : Demo.Template.Model
  }


model : Model
model =
  { layout = layoutModel
  , routing = Routing.initialModel
  , buttons = Demo.Buttons.model
  , textfields = Demo.Textfields.model
  , snackbar =
      Demo.Snackbar.model
      --, template = Demo.Template.model
  }



-- ACTION, UPDATE


type Action
  = LayoutAction Layout.Action
  | ButtonsAction Demo.Buttons.Action
  | TextfieldAction Demo.Textfields.Action
  | SnackbarAction Demo.Snackbar.Action
  | RoutingAction Routing.Action
  | HopAction ()



--| TemplateAction Demo.Template.Action


changeTab : Layout.Action -> Effects Action
changeTab action =
  let
    navTo path =
      Effects.map HopAction (navigateTo path)
  in
    case action of
      Layout.SwitchTab n ->
        case n of
          0 ->
            navTo "/snackbar"

          1 ->
            navTo "/textfields"

          2 ->
            navTo "/buttons"

          3 ->
            navTo "/grid"

          4 ->
            navTo "/badges"

          _ ->
            navTo "/404"

      _ ->
        Effects.none


update : Action -> Model -> ( Model, Effects.Effects Action )
update action model =
  case Debug.log "Action: " action of
    LayoutAction a ->
      let
        ( lifted, layoutFx ) =
          lift .layout (\m x -> { m | layout = x }) LayoutAction Layout.update a model

        routeFx =
          changeTab a

        fx =
          Effects.batch [ layoutFx, routeFx ]
      in
        ( lifted, fx )

    ButtonsAction a ->
      lift .buttons (\m x -> { m | buttons = x }) ButtonsAction Demo.Buttons.update a model

    TextfieldAction a ->
      lift' .textfields (\m x -> { m | textfields = x }) Demo.Textfields.update a model

    SnackbarAction a ->
      lift .snackbar (\m x -> { m | snackbar = x }) SnackbarAction Demo.Snackbar.update a model

    RoutingAction a ->
      let
        ( routing', fx ) =
          Routing.update a model.routing

        model' =
          { model | routing = routing' }
      in
        ( model'
        , Effects.map RoutingAction fx
        )

    HopAction _ ->
      ( model, Effects.none )



--TemplateAction  a -> lift  .template   (\m x->{m|template  =x}) TemplateAction Demo.Template.update   a model
-- VIEW


type alias Addr =
  Signal.Address Action


drawer : List Html
drawer =
  [ Layout.title "Example drawer"
  , Layout.navigation
      [ Layout.link
          [ href "https://github.com/debois/elm-mdl" ]
          [ text "github" ]
      , Layout.link
          [ href "http://package.elm-lang.org/packages/debois/elm-mdl/latest/" ]
          [ text "elm-package" ]
      ]
  ]


header : List Html
header =
  [ Layout.title "elm-mdl"
  , Layout.spacer
  , Layout.navigation
      [ Layout.link
          [ href "https://www.getmdl.io/components/index.html" ]
          [ text "MDL" ]
      , Layout.link
          [ href "https://www.google.com/design/spec/material-design/introduction.html" ]
          [ text "Material Design" ]
      ]
  ]


tabs : List ( String, Addr -> Model -> List Html )
tabs =
  [ ( "Snackbar"
    , \addr model ->
        [ Demo.Snackbar.view (Signal.forwardTo addr SnackbarAction) model.snackbar ]
    )
  , ( "Textfields"
    , \addr model ->
        [ Demo.Textfields.view (Signal.forwardTo addr TextfieldAction) model.textfields ]
    )
  , ( "Buttons"
    , \addr model ->
        [ Demo.Buttons.view (Signal.forwardTo addr ButtonsAction) model.buttons ]
    )
  , ( "Grid", \addr model -> Demo.Grid.view )
  , ( "Badges", \addr model -> Demo.Badges.view )
    {-
    , ("Template", \addr model ->
        [Demo.Template.view (Signal.forwardTo addr TemplateAction) model.template])
    -}
  ]


tabViews : Array (Addr -> Model -> List Html)
tabViews =
  List.map snd tabs |> Array.fromList


tabTitles : List Html
tabTitles =
  List.map (fst >> text) tabs


stylesheet : Html
stylesheet =
  Style.stylesheet """
  blockquote:before { content: none; }
  blockquote:after { content: none; }
  blockquote {
    border-left-style: solid;
    border-width: 1px;
    padding-left: 1.3ex;
    border-color: rgb(255,82,82);
    font-style: normal;
      /* TODO: Really need a way to specify "secondary color" in
         inline css.
       */
  }
  p, blockquote {
    max-width: 33em;
    font-size: 13px;
  }
"""


view : Signal.Address Action -> Model -> Html
view addr model =
  routingView addr model


routingView : Signal.Address Action -> Model -> Html
routingView addr model =
  case (Debug.log "Route " model.routing.route) of
    Routing.Home ->
      let
        model' =
          { model | layout = setTab model.layout 0 }
      in
        appView addr model'

    Routing.TabRoute tabNumber ->
      let
        model' =
          { model | layout = setTab model.layout tabNumber }
      in
        appView addr model'

    Routing.NotFoundRoute ->
      div [] [ h2 [] [ text "Not found" ] ]


setTab layout tabNumber =
  { layout | selectedTab = tabNumber }


appView : Signal.Address Action -> Model -> Html
appView addr model =
  let
    top =
      div
        [ style
            [ ( "margin", "auto" )
            , ( "padding-left", "5%" )
            , ( "padding-right", "5%" )
            ]
        ]
        ((Array.get model.layout.selectedTab tabViews
            |> Maybe.withDefault
                (\addr model ->
                  [ div [] [ text "This can't happen." ] ]
                )
         )
          addr
          model
        )
  in
    Layout.view
      (Signal.forwardTo addr LayoutAction)
      model.layout
      { header = Just header
      , drawer = Just drawer
      , tabs = Just tabTitles
      , main = [ stylesheet, top ]
      }
      {- The following line is not needed when you manually set up
      your html, as done with page.html. Removing it will then
      fix the flicker you see on load.
      -}
      |>
        Material.topWithScheme Color.Teal Color.Red


routerSignal : Signal Action
routerSignal =
  Signal.map RoutingAction Routing.signal


init : ( Model, Effects.Effects Action )
init =
  ( model, Effects.none )


inputs : List (Signal.Signal Action)
inputs =
  [ Layout.setupSizeChangeSignal LayoutAction
  , routerSignal
  ]


app : StartApp.App Model
app =
  StartApp.start
    { init = init
    , view = view
    , update = update
    , inputs = inputs
    }


main : Signal Html
main =
  app.html



-- PORTS


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


port routeRunTask : Task () ()
port routeRunTask =
  Routing.run
