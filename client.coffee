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

    saveSheetData: (endpoint, sheetData, cb) ->
      superagent.put("#{endpoint}/api/sheets/#{sheetData._id}")
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
    @type.saveSheetData @props.endpoint, data, (err, res) =>
      console.log err, res

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
          className: 'remove-row'
          onClick: @removeCol
        )
        (div
          className: 'remove-col'
          style:
            height: (((@state.sheet.cells.length + 1) * 24) + 1) + 'px'
          onClick: @removeRow
        )
        (Spreadsheet cells: @state.sheet.cells)
        (div
          className: 'add-col'
          style:
            height: (((@state.sheet.cells.length + 1) * 24) + 1) + 'px'
          onClick: @addCol
        )
        (div
          className: 'add-row',
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
          onChange: @updateCells
        , 'SAVE')
      )
      (div className: 'sub',
        (form className: 'pure-form',
          (Link
            href: '/' + @state.newSheetId
            className: 'pure-button new'
          ,
            'Create a new sheet with address '
            (input
              onClick: @doNothing
              valueLink: @linkState 'newSheetId'
            )
          )
        )
      )
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
