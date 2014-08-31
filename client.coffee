React = require 'react'
ReactAsync = require 'react-async'
ReactRouter = require 'react-router-component'
superagent = require 'superagent'
cuid = require 'cuid'
Pages = ReactRouter.Pages
Page = ReactRouter.Page
NotFound = ReactRouter.NotFound
Link = ReactRouter.Link

Spreadsheet = require 'react-microspreadsheet'

{html, head, link, script, div, meta, h1, h2, p, button} = React.DOM

MainPage = React.createClass
  componentDidMount: ->
    location.href = location.href + '/' + cuid.slug()
  render: -> (div {})

SheetPage = React.createClass
  mixins: [ReactAsync.Mixin]
  statics:
    getSheetData: (sheetId, cb) ->
      superagent.get "http://162.243.206.108:3000/api/sheets/#{sheetId}", (err, res) ->
        cb err, (if res then res.body else null)

    saveSheetData: (sheetData, cb) ->
      superagent.put("http://162.243.206.108:3000/api/sheets/#{sheetData._id}")
                .send(sheetData)
                .end (err, res) ->
        cb err, (if res then res.body else null)

  getInitialStateAsync: (cb) ->
    @type.getSheetData @props.sheetId, (err, sheet) ->
      cb err, sheet: sheet

  componentWillReceiveProps: (nextProps) ->
    if @props.sheetId isnt nextProps.sheetId
      @type.getSheetData nextProps.sheetId, (err, sheet) =>
        throw err if err
        @setState sheet: sheet

  save: (e) ->
    e.preventDefault()
    sheetData =
      cells: @state.sheet.cells
      _id: @props.sheetId
      author: 'anonymous'
    @type.saveSheetData sheetData, (err, res) =>
      console.log err, res

  render: ->
    sheetId = @props.sheetId
    cells = @state.sheet.cells

    (div {},
      (h2 {}, sheetId)
      (button
        className: 'pure-button'
        onClick: @save
      , 'SAVE')
      (Spreadsheet cells: cells)
    )

NotFoundHandler = React.createClass
  render: ->
    (p {}, 'Page not found')

App = React.createClass
  render: ->
    (html {},
      (head {},
        (meta charSet: 'utf-8')
        (link rel: 'stylesheet', href: 'http://yui.yahooapis.com/pure/0.5.0/pure-min.css')
        (link rel: 'stylesheet', href: '/assets/style.css')
        (script src: '/assets/bundle.js')
      )
      (h1 {}, 'Sheets')
      (Pages
        className: 'App'
        path: @props.path
      ,
        (Page path: '/', handler: MainPage)
        (Page path: '/:sheetId', handler: SheetPage)
        (NotFound handler: NotFoundHandler)
      )
    )

module.exports = App
if typeof window isnt "undefined"
  window.onload = ->
    React.renderComponent App(), document
