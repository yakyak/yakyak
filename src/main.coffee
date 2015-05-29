Client = require 'hangupsjs'
Q      = require 'q'
login  = require './login'
ipc = require 'ipc'
Menu = require 'menu'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

model = require './model' # holds the application status/model

class Controller
  constructor: (@app, @model, @client) ->
    @app.on 'ready', @appReady.bind(@)
  appReady: ->
    menus = []
    menus.push
      label: 'YakYak'
      submenu: [
        { label: 'About YakYak', selector: 'orderFrontStandardAboutPanel:' }
        { type: 'separator' }
        #{ label: 'Preferences...', accelerator: 'Command+,', click: => @openConfig() }
        { type: 'separator' }
        { label: 'Hide Atom', accelerator: 'Command+H', selector: 'hide:' }
        { label: 'Hide Others', accelerator: 'Command+Shift+H', selector: 'hideOtherApplications:' }
        { label: 'Show All', selector: 'unhideAllApplications:' }
        { type: 'separator' }
        { label: 'Open Inspector', accelerator: 'Command+Alt+I', click: => @inspectorOpen() }
        { type: 'separator' }
        { label: 'Quit', accelerator: 'Command+Q', click: -> app.quit() }
      ]
    menus.push
      label: 'Edit'
      submenu:[
        { label: 'Undo', accelerator: 'Command+Z', selector: 'undo:' }
        { label: 'Redo', accelerator: 'Command+Shift+Z', selector: 'redo:' }
        { type: 'separator' }
        { label: 'Cut', accelerator: 'Command+X', selector: 'cut:' }
        { label: 'Copy', accelerator: 'Command+C', selector: 'copy:' }
        { label: 'Paste', accelerator: 'Command+V', selector: 'paste:' }
        { label: 'Select All', accelerator: 'Command+A', selector: 'selectAll:' }
      ]
    menu = Menu.buildFromTemplate menus
    Menu.setApplicationMenu menu
    @app.on 'window-all-closed', => @app.quit() # if (process.platform != 'darwin')
    @mainWindow = new BrowserWindow
      width: 940
      height: 600
      "min-width": 620
      "min-height": 420
    @mainWindow.on 'closed', => @mainWindow = null
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
    @client.on 'chat_message', @clientonchatmessage
    ipc.on 'conversation:select', @conversationSelect
    ipc.on 'message:send', @messageSend
    ipc.on 'message-list:scroll', @conversationScrollPositionSet
  inspectorOpen: () =>
    @mainWindow.openDevTools detach: true
  conversationSelect: (event, id) =>
    @model.conversationCurrent = id
    @refresh()
    @mainWindow.webContents.send 'message-list:scroll', Number.MAX_VALUE
  messageSend: (event, message) =>
    conversation = @model.conversationCurrent
    dfr = @client.sendchatmessage conversation, [[0, message]], null
  conversationScrollPositionSet: (e, scrollTop, atBottom) =>
    conversationId = @model.conversationCurrent
    @model.conversationScrollPositionSet conversationId, scrollTop, atBottom
    if (atBottom) then @refresh()
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
  clientonchatmessage: (ev) =>
    console.log JSON.stringify ev, null, '  '
    @model.messageAdd ev
    stickToBottom = false
    conversationCurrent = @model.conversationsById[@model.conversationCurrent]
    if conversationCurrent
      stickToBottom = conversationCurrent.atBottom
      conversationCurrent.unreadCount += 1
    else
      console.log 'we got a message for an unknown conversation'
    @refresh()
    if stickToBottom
      @mainWindow.webContents.send 'message-list:scroll', Number.MAX_VALUE
    return

controller = new Controller(app, model, client)
    
