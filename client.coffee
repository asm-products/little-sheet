"use strict"

React = require("react")
ReactAsync = require("react-async")
ReactRouter = require("react-router-component")
superagent = require("superagent")
Pages = ReactRouter.Pages
Page = ReactRouter.Page
NotFound = ReactRouter.NotFound
Link = ReactRouter.Link

{html, head, link, script, div, h1, p} = React.DOM

MainPage = React.createClass
  render: ->
    (div className: 'MainPage',
      (h1 {}, 'Hello, anonymous!')
      (p {},
        (Link href: '/users/doe'
        , 'Login')
      )
    )

UserPage = React.createClass
  mixins: [ReactAsync.Mixin]
  statics:
    getUserInfo: (username, cb) ->
      superagent.get "http://localhost:3000/api/users/" + username, (err, res) ->
        cb err, (if res then res.body else null)

  getInitialStateAsync: (cb) ->
    @type.getUserInfo @props.username, cb

  componentWillReceiveProps: (nextProps) ->
    if @props.username isnt nextProps.username
      @type.getUserInfo nextProps.username, (err, info) =>
        throw err  if err
        @setState info

  render: ->
    otherUser = (if @props.username is "doe" then "ivan" else "doe")

    (div className: 'UserPage',
      (h1 {}, "Hello, #{@state.name}!")
      (p {},
        'Go to '
        (Link href: "/users/#{otherUser}"
        , "/users/#{otherUser}")
      )
      (p {},
        (Link href: "/"
        , 'Logout')
      )
    )

NotFoundHandler = React.createClass
  render: ->
    (p {}, 'Page not found')

App = React.createClass
  render: ->
    (html {},
      (head {},
        (link rel: 'stylesheet', href: '/assets/style.css')
        (script src: '/assets/bundle.js')
      )
      (Pages
        className: 'App'
        path: @props.path
      ,
        (Page path: '/', handler: MainPage)
        (Page path: '/users/:username', handler: UserPage)
        (NotFound handler: NotFoundHandler)
      )
    )

module.exports = App
if typeof window isnt "undefined"
  window.onload = ->
    React.renderComponent App(), document
