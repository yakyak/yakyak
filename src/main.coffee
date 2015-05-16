Client = require 'hangupsjs'
Q      = require 'q'

client = new Client()

app = require 'app'
BrowserWindow = require 'browser-window'

mainWindow = null

# Quit when all windows are closed.
app.on 'window-all-closed', ->
    app.quit() # if (process.platform != 'darwin')

app.on 'ready', ->

    # Create the browser window.
    mainWindow = new BrowserWindow {width: 800, height: 600}

    # and load the index.html of the app.
    mainWindow.loadUrl 'file://' + __dirname + '/index.html'

    # Emitted when the window is closed.
    mainWindow.on 'closed', ->
    mainWindow = null
