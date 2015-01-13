React = require 'react/addons'
React.initializeTouchEvents(true)
superagent = require 'superagent'
cuid = require 'cuid'

{div, form, button, label, input, span, h1, h2, a} = React.DOM

Spreadsheet = React.createFactory require 'react-spreadsheet'

Main = React.createFactory React.createClass
  mixins: [React.addons.LinkedStateMixin]

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
      getSheetData @props.sheetId, (err, sheet) =>
        @setState
          sheet: sheet

      # change page title
      document.title = "LittleSheet ##{@props.sheetId}"

  componentWillReceiveProps: (nextProps) ->
    if @props.sheetId isnt nextProps.sheetId
      getSheetData nextProps.sheetId, (err, sheet) =>
        throw err if err
        @setState
          sheet: sheet
          newSheetId: cuid.slug()

  componentDidUpdate: ->
    if @props.sheetId
      # change page title
      document.title = "LittleSheet ##{@props.sheetId}"

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
          (a
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
    saveSheetData @props.sheetId, data, (err, res) =>
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

getSheetData = (sheetId, versionId, cb) ->
  if sheetId
    url = "#{__s3}/#{sheetId}.json"
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

saveSheetData = (sheetId, sheetData, cb) ->
  superagent.put("/api/sheets/#{sheetId}")
            .send(sheetData)
            .end (err, res) ->
    cb err, (if res then res.body else null)

main = document.getElementById 'main'
React.render Main(sheetId: main.dataset.sheet), main
