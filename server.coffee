renderApp = (req, res, next) ->
  path = url.parse(req.url).pathname
  app = App
    path: path
  ReactAsync.renderComponentToStringWithAsyncState app, (err, markup) ->
    return next(err) if err
    res.send "<!doctype html>\n" + markup

"use strict"

path = require 'path'
url = require 'url'
bodyParser = require 'body-parser'
AWS = require 'aws-sdk'
express = require 'express'
ReactAsync = require 'react-async'
App = require './client.coffee'

development = process.env.NODE_ENV isnt "production"

s3 = new AWS.S3
  accessKeyId: process.env.S3_KEY_ID
  secretAccessKey: process.env.S3_SECRET
  region: 'us-east-1'

api = express()
  .put('/sheets/:sheetId', (req, res) ->

    sheetId = req.params.sheetId

    if req.body.cells.length > 99 or req.body.cells[0].length > 20
      res.status 400

    sheetData =
      cells: req.body.cells
      author: req.body.author

    s3.putObject {
      Bucket: 'sheetstore'
      Key: sheetId + '.json'
      ACL: 'public-read'
      Body: JSON.stringify sheetData
      ContentType: 'application/json'
    } , (err, data) ->
      console.log err, data
      if not err
        res.send data
      else
        res.status 503
  )

app = express()

app.use(bodyParser.json(strict: false))
   .use("/assets", express.static(path.join(__dirname, "assets")))
   .use("/api", api)
   .use(renderApp)
   .listen (process.env.PORT or 3000), ->
  console.log "Point your browser at http://localhost:3000"
  return
