Client = require 'hangupsjs'
Q      = require 'q'
login  = require './login'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

mainWindow = null

# Quit when all windows are closed.
app.on 'window-all-closed', ->
    app.quit() # if (process.platform != 'darwin')

loadAppWindow = ->
    mainWindow.loadUrl 'file://' + __dirname + '/index.html'

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

    client.connect(creds).then ->
        # XXX update global var that indicates current
        # client connection state.
        console.log 'connected'
    .done()

    # Emitted when the window is closed.
    mainWindow.on 'closed', ->
        mainWindow = null
