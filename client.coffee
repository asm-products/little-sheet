React = require 'react/addons'
React.initializeTouchEvents(true)
ReactRouter = require 'react-router-component'
superagent = require 'superagent'
cuid = require 'cuid'
Pages = ReactRouter.Pages
Page = ReactRouter.Page
NotFound = ReactRouter.NotFound
Link = ReactRouter.Link

Spreadsheet = require 'react-spreadsheet'

{html, head, link, script, meta, title,
 div, span,
 h1, h2, a, p,
 form, label, input, button} = React.DOM

MainPage = React.createClass
  getInitialState: ->
    cells: null

  componentDidMount: ->
    try
      @setState cells: JSON.parse location.hash.slice 1
    catch e
      try
        @setState cells: JSON.parse decodeURIComponent location.hash.slice 1
      catch e
        location.pathname = cuid.slug()
        
  render: ->
    if not @state.cells
      (div {})
    else
      (SheetPage
        sheet:
          cells: @state.cells
        sheetId: cuid.slug()
      )

SheetPage = React.createClass
  mixins: [React.addons.LinkedStateMixin]
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

    saveSheetData: (sheetId, sheetData, cb) ->
      superagent.put("/api/sheets/#{sheetId}")
                .send(sheetData)
                .end (err, res) ->
        cb err, (if res then res.body else null)

  getInitialState: ->
    if @props.sheet
      sheet: @props.sheet
      newSheetId: cuid.slug()
    else
      newSheetId: cuid.slug()

  componentDidMount: ->
    @setState domain: location.protocol + '//' + location.host

    # actually fetch the sheet
    if not @state.sheet and @props.sheetId
      @type.getSheetData @props.sheetId, (err, sheet) =>
        @setState
          sheet: sheet

      # change page title
      document.title = "#{@props.sheetId} @ Sheets"

    else if not @state.sheet
      location.pathname = @state.newSheetId
    
  componentWillReceiveProps: (nextProps) ->
    if @props.sheetId isnt nextProps.sheetId
      @type.getSheetData nextProps.sheetId, (err, sheet) =>
        throw err if err
        @setState
          sheet: sheet
          newSheetId: cuid.slug()

  componentDidUpdate: ->
    if @props.sheetId
      # change page title
      document.title = "#{@props.sheetId} @ Sheets"

  render: ->
    if not @state.sheet
      return (div {})

    (div className: 'main',
      (div className: 'sheet-area',
        (h2 className: 'sheetId',
          (a {href: '/' + @props.sheetId}, @props.sheetId)
        )
        (span className: 'author'
        , if @state.sheet.author then "by #{@state.sheet.author} at" else '')
        (span # (Link
          className: 'date'
          href: '/' + @props.sheetId + "?versionId=#{@state.sheet.versionId}"
        , @state.sheet.date or '')
        (div className: 'share',
          (input
            onClick: @selectText
            readOnly: true
            value: @state.domain + '/' + @props.sheetId
          )
        ) if @state.sheet.date and @state.domain
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
        (-> console.log @state)
        (Spreadsheet
          cells: @state.sheet.cells
          onChange: @updateCells
        ) if @state.sheet
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
        , @state.saveButtonText or 'SAVE')
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
    @setState saveButtonText: 'SAVING'
    e.preventDefault()
    data =
      cells: @state.sheet.cells
      author: @state.author
    @type.saveSheetData @props.sheetId, data, (err, res) =>
      console.log err
      if err
        @setState
          saveButtonText: 'ERROR'
        , => setTimeout =>
          @setState saveButtonText: null
        , 3000
      else if res
        sheet = @state.sheet
        sheet.date = (new Date()).toGMTString()
        @setState
          sheet: sheet
          saveButtonText: 'SAVED'
        , => setTimeout =>
          @setState saveButtonText: null
        , 3000

  selectText: (e) ->
    e.target.focus()
    e.target.select()

NotFoundHandler = React.createClass
  render: ->
    (p {}, 'Page not found')

App = React.createClass
  render: ->
    (html {},
      (head {},
        (meta charSet: 'utf-8')
        (title {}, 'Sheets: a small sheet you can share')
        (link rel: 'stylesheet', href: 'http://yui.yahooapis.com/pure/0.5.0/pure-min.css')
        (link rel: 'stylesheet', href: '/assets/style.css')
        (script src: '/assets/bundle.js')
        (script
          dangerouslySetInnerHTML:
            __html: '''
  (function(t,r,a,c,k){k=r.createElement('script');k.type='text/javascript';
  k.async=true;k.src=a;k.id='ma';r.getElementsByTagName('head')[0].appendChild(k);
  t.maq=[];t.mai=c;t.ma=function(){t.maq.push(arguments)};
  })(window,document,'http://spooner.alhur.es:5984/microanalytics/_design/microanalytics/_rewrite/tracker.js','2s9jicn0vr5mxxu');

  ma('pageView');
            '''
        )
      )
      (div className: 'title',
        (h1 {}, 'Sheets')
        (h2 {}, 'a small sheet you can share')
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
