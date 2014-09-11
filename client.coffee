React = require 'react/addons'
ReactAsync = require 'react-async'
ReactRouter = require 'react-router-component'
superagent = require 'superagent'
cuid = require 'cuid'
Pages = ReactRouter.Pages
Page = ReactRouter.Page
NotFound = ReactRouter.NotFound
Link = ReactRouter.Link

Spreadsheet = require 'react-microspreadsheet'

{html, head, link, script, meta,
 div, span,
 h1, h2, a, p,
 form, label, input, button} = React.DOM

MainPage = React.createClass
  componentDidMount: ->
    location.href = location.href + cuid.slug()
  render: -> (div {})

SheetPage = React.createClass
  mixins: [ReactAsync.Mixin, React.addons.LinkedStateMixin]
  statics:
    getSheetData: (sheetId, versionId, cb) ->
      if sheetId
        url = "http://sheetstore.s3-website-us-east-1.amazonaws.com/#{sheetId}.json"
        if typeof versionId == 'string'
          url += "?versionId=#{versionId}"
        else
          cb = versionId
        superagent.get url, (err, res) ->
          sheet = if res then res.body or {} else {}
          sheet.cells = sheet.cells or [
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
          ]
          if res and res.headers
            sheet.date = res.headers['last-modified']
            sheet.versionId = res.headers['x-amz-version-id']
            sheet.author = res.headers['x-amz-author']
          cb null, sheet
      else
        cb {Error: 'noSheetId'}

    saveSheetData: (endpoint, sheetId, sheetData, cb) ->
      superagent.put("#{endpoint}/api/sheets/#{sheetId}")
                .send(sheetData)
                .end (err, res) ->
        cb err, (if res then res.body else null)

  getInitialStateAsync: (cb) ->
    @type.getSheetData @props.sheetId, (err, sheet) ->
      cb err, {sheet: sheet, newSheetId: cuid.slug()}

  componentWillReceiveProps: (nextProps) ->
    if @props.sheetId isnt nextProps.sheetId
      @type.getSheetData nextProps.sheetId, (err, sheet) =>
        throw err if err
        @setState
          sheet: sheet
          newSheetId: cuid.slug()

  render: ->
    sheetId = @props.sheetId

    (div className: 'main',
      (div className: 'sheet-area',
        (h2 className: 'sheetId',
          (Link {href: '/' + @props.sheetId}, @props.sheetId)
        )
        (span className: 'author'
        , if @state.sheet.author then "by #{@state.sheet.author} at" else '')
        (span # (Link
          className: 'date'
          href: '/' + @props.sheetId + "?versionId=#{@state.sheet.versionId}"
        , @state.sheet.date or '')
        (div
          title: 'Remove a row from the end'
          className: 'remove-row'
          onClick: @removeRow
        )
        (div
          title: 'Remove a column from the end'
          className: 'remove-col'
          style:
            height: ((@state.sheet.cells.length + 1) * 27) + 'px'
          onClick: @removeCol
        )
        (Spreadsheet
          cells: @state.sheet.cells
          onChange: @updateCells
        )
        (div
          title: 'Add a column at the end'
          className: 'add-col'
          style:
            height: ((@state.sheet.cells.length + 1) * 27) + 'px'
          onClick: @addCol
        )
        (div
          title: 'Add a row at the end'
          className: 'add-row',
          style:
            top: ((@state.sheet.cells.length + 1) * 27) + 'px'
          onClick: @addRow
        )
        (form className: 'pure-form sign',
          (label {},
            'Add your name? ' unless @state.sign
            (input
              type: 'checkbox'
              valueLink: @linkState 'sign'
              className: 'sign'
            ) unless @state.sign
          )
          (input valueLink: @linkState 'author') if @state.sign
        )
        (button
          className: 'pure-button save'
          onClick: @save
        , 'SAVE')
      )
      (div className: 'sub',
        (form className: 'pure-form',
          (Link
            href: '/' + @state.newSheetId
            className: 'pure-button new'
          ,
            'Create a new sheet at the address '
            (input
              onClick: @doNothing
              valueLink: @linkState 'newSheetId'
            )
          )
        )
      )
    )

  doNothing: (e) ->
    e.preventDefault()
    e.stopPropagation()

  addRow: (e) ->
    e.preventDefault()
    cells = @state.sheet.cells
    newRow = ('' for c in cells[0])
    cells.push newRow
    @setState cells: cells

  addCol: (e) ->
    e.preventDefault()
    cells = @state.sheet.cells
    for row in cells
      row.push ''
    @setState cells: cells

  removeRow: (e) ->
    e.preventDefault()
    cells = @state.sheet.cells
    cells.pop()
    @setState cells: cells

  removeCol: (e) ->
    e.preventDefault()
    cells = @state.sheet.cells
    for row in cells
      row.pop()
    @setState cells: cells

  updateCells: (cells) ->
    @state.sheet.cells = cells

  save: (e) ->
    e.preventDefault()
    data =
      cells: @state.sheet.cells
      author: @state.author
    @type.saveSheetData @props.endpoint, @props.sheetId, data, (err, res) =>
      console.log err, res

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
      (div className: 'title',
        (h1 {}, 'Sheets')
      )
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
