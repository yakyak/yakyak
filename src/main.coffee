Client = require 'hangupsjs'
Q      = require 'q'
login  = require './login'
ipc = require 'ipc'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

model = require './model' # holds the application status/model

class Controller
  constructor: (@app, @model, @client) ->
    @app.on 'ready', @appReady.bind(@)
  appReady: ->
    @app.on 'window-all-closed', => @app.quit() # if (process.platform != 'darwin')
    @mainWindow = new BrowserWindow
      width: 940
      height: 600
      "min-width": 620
      "min-height": 420
    @mainWindow.on 'closed', => @mainWindow = null
    @mainWindow.openDevTools detach: true
    # and load the index.html of the app. this may however be yanked
    # away if we must do auth.
    @loadAppWindow()
    # callback for credentials
    creds = =>
      prom = login(@mainWindow)
      # reinstate app window when login finishes
      prom.then -> loadAppWindow()
      auth: -> prom
    @mainWindow.webContents.on 'did-finish-load', => @refresh()
    @model.connection = 'connecting..'
    @client.connect(creds).then @clientConnectionSuccess.bind(@), @clientConnectionError.bind(@)
    @client.on 'chat_message', @clientonchatmessage.bind(@)
    ipc.on 'conversation:select', @conversationSelect
    ipc.on 'message:send', @messageSend
  conversationSelect: (event, id) =>
    console.log id
    @model.conversationCurrent = id
    @refresh()
  messageSend: (event, message) =>
    conversation = @model.conversationCurrent
    console.log conversation, message
    dfr = @client.sendchatmessage conversation, [[0, message]], null
    dfr.then console.log, console.log
  loadAppWindow: -> @mainWindow.loadUrl 'file://' + __dirname + '/ui/index.html'
  refresh: -> @mainWindow.webContents.send 'model:update', @model
  clientConnectionSuccess: ->
    @model.connection = 'online'
    @refresh()
    promise = @getselfinfo()
    promise.then =>
      @syncrecentconversations().fail (err) -> console.log 'error', err, err.stack
    pormise.fail (err) -> console.log 'error', err, err.stack
  clientConnectionError: ->
    @model.connection = 'error'
    @refresh()
  getselfinfo: ->
    ret = client.getselfinfo()
    success = (userInfo) =>
      fs = require('fs')
      @model.self.username = userInfo.self_entity.properties.display_name
      @refresh()
    failure = (error) =>
      console.log 'error', error
    ret = ret.then success, failure
    return ret
  syncrecentconversations: =>
    client.syncrecentconversations().then (data) =>
      @model.loadRecentConversations data
      @refresh()
  entityCache: {}
  getentitybyid: (id) ->
    if @entityCache[id]
      return Q @entityCache[id]
    ret = client.getentitybyid id
    success = (data) => @entityCache[id] = data
    failure = (err) ->
      console.log 'error', err
      console.log err.stack
    ret.then success.bind(@), failure.bind(@)
    return ret
  clientonchatmessage: (ev) ->
    console.log JSON.stringify ev, null, '  '
    @model.messageAdd ev
    @refresh()
    return
    chat_id = (ev.sender_id || ev.user_id).chat_id
    if not ev.chat_message or not ev.chat_message.message_content.segment
      # TODO need to investigate, for now we skip
      return Q()
    text = ev.chat_message.message_content.segment[0].text
    dfr = Q()
    dfr = dfr.then => @getentitybyid chat_id
    dfr = dfr.then (res) =>
      display_name = res.entities[0].properties.display_name
      #console.log display_name, ':', text
    dfr = dfr.then (res) =>
      #console.log JSON.stringify res, null, '  '
    return dfr
    try
      text = ev.chat_message.message_content.segment[0].text
      #if text
      #  console.log(chat_id, text)
    catch e
      console.log chat_id, 'not a text message'
    console.log 'getentitybyid for ', chat_id
    example_getentitybyid chat_id

    
controller = new Controller(app, model, client)
    
