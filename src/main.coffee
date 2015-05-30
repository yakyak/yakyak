Client = require 'hangupsjs'
Q      = require 'q'
login  = require './login'
fs     = require 'fs'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

mainWindow = null

# Quit when all windows are closed.
app.on 'window-all-closed', ->
    app.quit() # if (process.platform != 'darwin')

loadAppWindow = ->
    mainWindow.loadUrl 'file://' + __dirname + '/ui/index.html'

app.on 'ready', ->

    # Create the browser window.
    mainWindow = new BrowserWindow {
        width: 940
        height: 600
        "min-width": 620
        "min-height": 420
    }

    mainWindow.openDevTools detach: true

    # and load the index.html of the app. this may however be yanked
    # away if we must do auth.
    loadAppWindow()

    # callback for credentials
    creds = ->
        prom = login(mainWindow)
        # reinstate app window when login finishes
        prom.then -> loadAppWindow()
        auth: -> prom

#    client.connect(creds).then ->
#        # when fully connected, we shuffle over the
#        # init object to set up entities/convs
#        mainWindow.webContents.send 'init', client.init
#    .done()

    init = require './init.json'
    mainWindow.webContents.on 'did-finish-load', onDidFinishLoad = ->
        url = mainWindow.getUrl()
        if url.indexOf 'app/ui/index.html' > 0
            mainWindow.webContents.send 'init', init

    # propagate these events to the renderer
    require('./ui/events').forEach (n) ->
        client.on n, (e) -> mainWindow.webContents.send n, e

    # Emitted when the window is closed.
    mainWindow.on 'closed', ->
        mainWindow = null
