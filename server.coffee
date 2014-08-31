renderApp = (req, res, next) ->
  path = url.parse(req.url).pathname
  app = App(path: path)
  ReactAsync.renderComponentToStringWithAsyncState app, (err, markup) ->
    return next(err) if err
    res.send "<!doctype html>\n" + markup

"use strict"

path = require 'path'
url = require 'url'
bodyParser = require 'body-parser'
mongojs = require 'mongojs'
express = require 'express'
browserify = require 'connect-browserify'
coffeeify = require 'coffeeify'
ReactAsync = require 'react-async'
App = require './client.coffee'

development = process.env.NODE_ENV isnt "production"

db = mongojs.connect(process.env.MONGOLAB_URI, ['sheets'])

api = express()
  .get('/sheets/:sheetId', (req, res) ->
    db.sheets.findOne
      id: req.params.sheetId
    , (err, sheet) ->
      if not sheet
        sheet =
          cells: [
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
            ['', '', '']
          ]
      res.send sheet
  )
  .put('/sheets/:sheetId', (req, res) ->
    if req.body.cells.length > 99 or req.body.cells[0].length > 20
      res.status 400

    db.sheets.update
      id: req.params.sheetId
    ,
      $set:
        cells: req.body.cells
      $push:
        versions:
          $each: [
            cells: req.body.cells
            author: req.body.author
            date: (new Date()).toISOString()
          ]
          $slice: -20
    ,
      upsert: true
    ,
      (err, sheet) ->
        console.log 'saved: ', err, sheet
        res.send sheet
  )

app = express()

app.use(bodyParser.json(strict: false))
   .use("/assets", express.static(path.join(__dirname, "assets")))
   .use("/api", api)
   .use(renderApp)
   .listen 3000, ->
  console.log "Point your browser at http://localhost:3000"
  return
